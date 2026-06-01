package com.petdiet.character.entity;

import com.petdiet.character.service.RaisingActivity;
import com.petdiet.pet.entity.UserPet;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Entity
@Table(name = "\"PetCharacters\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PetCharacter {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"characterId\"")
    private Integer characterId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"petId\"", nullable = false, unique = true)
    private UserPet pet;

    @Column(name = "\"characterName\"", nullable = false)
    private String characterName;

    @Column(name = "\"characterImageUrl\"", columnDefinition = "TEXT")
    private String characterImageUrl;

    @Builder.Default
    @Column(name = "\"characterLevel\"", nullable = false)
    private Integer characterLevel = 1;

    @Builder.Default
    @Column(name = "\"currentExp\"", nullable = false)
    private Integer currentExp = 0;

    @Builder.Default
    @Column(name = "\"health\"", nullable = false)
    private Integer health = 80;

    @Builder.Default
    @Column(name = "\"happiness\"", nullable = false)
    private Integer happiness = 80;

    @Builder.Default
    @Column(name = "\"hunger\"", nullable = false)
    private Integer hunger = 50;

    @Column(name = "\"description\"")
    private String description;

    @Builder.Default
    @Column(name = "\"characterStatus\"", nullable = false)
    private String characterStatus = "ACTIVE";

    @CreationTimestamp
    @Column(name = "\"createdAt\"", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "\"updatedAt\"", nullable = false)
    private OffsetDateTime updatedAt;

    @Builder.Default
    @OneToMany(mappedBy = "character", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CharacterGrowthLog> growthLogs = new ArrayList<>();

    public int requiredExp() {
        return this.characterLevel * 100;
    }

    public int expToNextLevel() {
        return Math.max(0, requiredExp() - this.currentExp);
    }

    public boolean applyActivity(RaisingActivity activity) {
        this.currentExp += activity.getExpGain();
        activity.getStatDeltas().forEach((stat, delta) -> {
            switch (stat) {
                case "health" -> this.health = clamp(this.health + delta);
                case "happiness" -> this.happiness = clamp(this.happiness + delta);
                case "hunger" -> this.hunger = clamp(this.hunger + delta);
                default -> { }
            }
        });
        return checkLevelUp();
    }

    private boolean checkLevelUp() {
        boolean leveled = false;
        while (this.currentExp >= requiredExp()) {
            this.currentExp -= requiredExp();
            this.characterLevel++;
            leveled = true;
        }
        return leveled;
    }

    private static int clamp(int value) {
        return Math.max(0, Math.min(100, value));
    }

    public String formatStatChanges(RaisingActivity activity) {
        return activity.getStatDeltas().entrySet().stream()
                .map(e -> statLabel(e.getKey()) + (e.getValue() >= 0 ? " +" : " ") + e.getValue())
                .collect(Collectors.joining(", "));
    }

    private static String statLabel(String key) {
        return switch (key) {
            case "health" -> "건강";
            case "happiness" -> "행복";
            case "hunger" -> "배고픔";
            default -> key;
        };
    }

    public void updateName(String characterName) {
        if (characterName != null) this.characterName = characterName;
    }

    public void updateMeta(String characterName, String characterImageUrl, String description, String characterStatus) {
        if (characterName != null) this.characterName = characterName;
        if (characterImageUrl != null) this.characterImageUrl = characterImageUrl;
        if (description != null) this.description = description;
        if (characterStatus != null) this.characterStatus = characterStatus;
    }

    public void hide() {
        this.characterStatus = "HIDDEN";
    }
}

package com.petdiet.character.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;

@Entity
@Table(name = "\"CharacterGrowthLogs\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CharacterGrowthLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"growthLogId\"")
    private Integer growthLogId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"characterId\"", nullable = false)
    private PetCharacter character;

    @Column(name = "\"userId\"", nullable = false)
    private Integer userId;

    @Column(name = "\"activityType\"", nullable = false)
    private String activityType;

    @Builder.Default
    @Column(name = "\"expAmount\"", nullable = false)
    private Integer expAmount = 0;

    @Column(name = "\"activityDescription\"")
    private String activityDescription;

    @CreationTimestamp
    @Column(name = "\"createdAt\"", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public static CharacterGrowthLog activity(PetCharacter character, Integer userId,
                                              String activityType, int expAmount, String description) {
        return CharacterGrowthLog.builder()
                .character(character)
                .userId(userId)
                .activityType(activityType)
                .expAmount(expAmount)
                .activityDescription(description)
                .build();
    }
}

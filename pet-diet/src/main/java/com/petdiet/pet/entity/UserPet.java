package com.petdiet.pet.entity;

import com.petdiet.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "\"UserPets\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"petId\"")
    private Integer petId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false)
    private User user;

    @Column(name = "\"petName\"", nullable = false)
    private String petName;

    @Column(name = "\"petType\"", nullable = false)
    private String petType;

    @Column(name = "\"breedId\"")
    private Integer breedId;

    @Column(name = "\"petGender\"")
    private String petGender;

    @Column(name = "\"petBirthdate\"")
    private LocalDate petBirthdate;

    @Column(name = "\"petWeight\"", precision = 5, scale = 2)
    private BigDecimal petWeight;

    @Column(name = "\"isNeutered\"")
    private Boolean isNeutered;

    @Column(name = "\"petBodyConditionScore\"")
    private Integer petBodyConditionScore;

    @Column(name = "\"petBodyScoreDate\"")
    private LocalDate petBodyScoreDate;

    @Column(name = "\"petActivityLevel\"")
    private Integer petActivityLevel;

    // 콤마 구분 태그 문자열(예: "알레르기,장,피부/모질"). 최대 3개, 서비스 계층에서 검증.
    @Column(name = "\"petHealthFocusAreas\"")
    private String healthFocusAreas;

    @Column(name = "\"petProfileImg\"")
    private String petProfileImg;

    @CreationTimestamp
    @Column(name = "\"petCreatedAt\"", nullable = false, updatable = false)
    private OffsetDateTime petCreatedAt;

    @UpdateTimestamp
    @Column(name = "\"petUpdatedAt\"", nullable = false)
    private OffsetDateTime petUpdatedAt;

    @Builder.Default
    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PetAllergy> allergies = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PetDisease> diseases = new ArrayList<>();

    public void update(String petName, String petType, String petGender, LocalDate petBirthdate,
                       BigDecimal petWeight, Boolean isNeutered, String petProfileImg, Integer breedId,
                       Integer petBodyConditionScore, Integer petActivityLevel, String healthFocusAreas) {
        if (petName != null) this.petName = petName;
        if (petType != null) this.petType = petType;
        if (petGender != null) this.petGender = petGender;
        if (petBirthdate != null) this.petBirthdate = petBirthdate;
        if (petWeight != null) this.petWeight = petWeight;
        if (isNeutered != null) this.isNeutered = isNeutered;
        if (petProfileImg != null) this.petProfileImg = petProfileImg;
        if (breedId != null) this.breedId = breedId;
        if (petBodyConditionScore != null) {
            this.petBodyConditionScore = petBodyConditionScore;
            this.petBodyScoreDate = LocalDate.now();
        }
        if (petActivityLevel != null) this.petActivityLevel = petActivityLevel;
        if (healthFocusAreas != null) this.healthFocusAreas = healthFocusAreas;
    }
}

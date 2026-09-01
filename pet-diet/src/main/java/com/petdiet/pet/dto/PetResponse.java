package com.petdiet.pet.dto;

import com.petdiet.pet.entity.UserPet;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

@Getter
@Builder
public class PetResponse {
    private Integer petId;
    private Integer userId;
    private String petName;
    private String petType;
    private Integer breedId;
    private String species;
    private String breedName;
    private String breedNameKo;
    private String groupName;
    private String petGender;
    private LocalDate petBirthdate;
    private BigDecimal petWeight;
    private Integer petBodyConditionScore;
    private LocalDate petBodyScoreDate;
    private Integer petActivityLevel;
    private Boolean isNeutered;
    private String petProfileImg;
    private String petProfileImageUrl;
    private List<Integer> allergyIds;
    private List<Integer> diseaseIds;
    private List<String> healthFocusAreas;

    public static PetResponse from(UserPet pet) {
        return PetResponse.builder()
                .petId(pet.getPetId())
                .userId(pet.getUser().getUserId())
                .petName(pet.getPetName())
                .petType(pet.getPetType())
                .breedId(pet.getBreedId())
                .petGender(pet.getPetGender())
                .petBirthdate(pet.getPetBirthdate())
                .petWeight(pet.getPetWeight())
                .petBodyConditionScore(pet.getPetBodyConditionScore())
                .petBodyScoreDate(pet.getPetBodyScoreDate())
                .petActivityLevel(pet.getPetActivityLevel())
                .isNeutered(pet.getIsNeutered())
                .petProfileImg(pet.getPetProfileImg())
                .petProfileImageUrl(pet.getPetProfileImg())
                .allergyIds(pet.getAllergies().stream().map(a -> a.getAllergyId()).toList())
                .diseaseIds(pet.getDiseases().stream().map(d -> d.getDiseaseId()).toList())
                .healthFocusAreas(splitCsv(pet.getHealthFocusAreas()))
                .build();
    }

    private static List<String> splitCsv(String csv) {
        if (csv == null || csv.isBlank()) return List.of();
        return Arrays.stream(csv.split(",")).map(String::trim).filter(s -> !s.isEmpty()).toList();
    }
}

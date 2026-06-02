package com.petdiet.character.dto;

import com.petdiet.character.entity.PetCharacter;
import com.petdiet.master.entity.Breed;
import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.List;

@Getter
@Builder
public class CharacterResponse {
    private Integer characterId;
    private Integer petId;
    private String characterName;
    private String characterImageUrl;
    private String description;
    private String petType;
    private String petTypeLabel;
    private Integer breedId;
    private String breedName;
    private Integer characterLevel;
    private Integer currentExp;
    private Integer requiredExp;
    private Integer expToNextLevel;
    private Integer health;
    private Integer happiness;
    private Integer hunger;
    private String characterState;
    private Boolean isPrimary;
    private OffsetDateTime updatedAt;
    private List<GrowthLogResponse> growthLogs;
    private OffsetDateTime createdAt;

    public static CharacterResponse from(PetCharacter character, Breed breed) {
        int level = character.getCharacterLevel();
        int required = level * 100;
        int expToNext = Math.max(0, required - character.getCurrentExp());
        String petType = character.getPet().getPetType();
        return CharacterResponse.builder()
                .characterId(character.getCharacterId())
                .petId(character.getPet().getPetId())
                .characterName(character.getCharacterName())
                .characterImageUrl(character.getCharacterImageUrl())
                .description(character.getDescription())
                .petType(petType)
                .petTypeLabel("DOG".equalsIgnoreCase(petType) ? "강아지" : "CAT".equalsIgnoreCase(petType) ? "고양이" : petType)
                .breedId(character.getPet().getBreedId())
                .breedName(breed != null
                        ? (breed.getBreedNameKo() != null ? breed.getBreedNameKo() : breed.getBreedName())
                        : null)
                .characterLevel(level)
                .currentExp(character.getCurrentExp())
                .requiredExp(required)
                .expToNextLevel(expToNext)
                .health(character.getHealth())
                .happiness(character.getHappiness())
                .hunger(character.getHunger())
                .characterState(character.getCharacterStatus())
                .isPrimary(false)
                .updatedAt(character.getUpdatedAt())
                .growthLogs(List.of())
                .createdAt(character.getCreatedAt())
                .build();
    }
}

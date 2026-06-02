package com.petdiet.character.dto;

import lombok.Getter;

@Getter
public class CharacterRequest {
    private Integer petId;

    private String characterName;

    /** DOG | CAT */
    private String petType;

    private Integer breedId;

    private String characterImageUrl;

    private String description;

    private String characterType;
    private String characterState;
    private Boolean isPrimary;
}

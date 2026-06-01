package com.petdiet.ai.diet.dto;

import lombok.Getter;

@Getter
public class DietRecommendRequest {

    private Integer petId;

    private String userNotes;
}

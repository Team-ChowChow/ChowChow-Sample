package com.petdiet.ai.diet.dto;

import lombok.Getter;

@Getter
public class DietRecommendRequest {

    /** null이면 반려동물 프로필 없이 일반 맞춤 레시피 생성 */
    private Integer petId;

    private String userNotes;
}

package com.petdiet.ai.foodtransition.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class FoodTransitionStepDto {
    private String dayRange;
    private Integer currentFoodPercent;
    private Integer newFoodPercent;
    private String note;
}

package com.petdiet.ai.foodtransition.dto;

import lombok.Getter;

@Getter
public class FoodTransitionRequest {

    private Integer petId;

    private Integer currentFoodId;

    private Integer targetFoodId;
}

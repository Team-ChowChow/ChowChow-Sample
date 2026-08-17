package com.petdiet.meal.dto;

import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class MealRecordRequest {
    private Integer petId;
    private String mealTitle;
    private String mealNote;
    private String imageUrl;
    private String mealDate;
    private BigDecimal feedingAmountG;
    private Integer recipeId;
    private Integer commercialFoodId;
}

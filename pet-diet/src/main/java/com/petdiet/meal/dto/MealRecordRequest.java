package com.petdiet.meal.dto;

import lombok.Getter;

@Getter
public class MealRecordRequest {
    private Integer petId;
    private String mealTitle;
    private String mealNote;
    private String imageUrl;
    private String mealDate;
}

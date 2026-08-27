package com.petdiet.food.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class UserFoodRequest {
    private String brandName;

    @NotBlank(message = "사료 이름을 입력해주세요.")
    private String productName;

    private String petType;
    private BigDecimal caloriesPer100g;
    private BigDecimal proteinG;
    private BigDecimal fatG;
    private BigDecimal carbohydrateG;
}

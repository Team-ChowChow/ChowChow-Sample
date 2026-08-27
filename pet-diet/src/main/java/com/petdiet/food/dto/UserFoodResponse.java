package com.petdiet.food.dto;

import com.petdiet.food.entity.UserFood;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class UserFoodResponse {
    private Integer userFoodId;
    private String brandName;
    private String productName;
    private String petType;
    private BigDecimal caloriesPer100g;
    private BigDecimal proteinG;
    private BigDecimal fatG;
    private BigDecimal carbohydrateG;

    public static UserFoodResponse from(UserFood f) {
        return UserFoodResponse.builder()
                .userFoodId(f.getUserFoodId())
                .brandName(f.getBrandName())
                .productName(f.getProductName())
                .petType(f.getPetType())
                .caloriesPer100g(f.getCaloriesPer100g())
                .proteinG(f.getProteinG())
                .fatG(f.getFatG())
                .carbohydrateG(f.getCarbohydrateG())
                .build();
    }
}

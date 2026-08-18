package com.petdiet.food.dto;

import com.petdiet.food.entity.CommercialFood;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class CommercialFoodResponse {
    private Integer foodId;
    private String brandName;
    private String productName;
    private String petType;
    private BigDecimal caloriesPer100g;
    private BigDecimal proteinG;
    private BigDecimal fatG;
    private BigDecimal carbohydrateG;
    private String features;
    private String imageUrl;

    public static CommercialFoodResponse from(CommercialFood f) {
        return CommercialFoodResponse.builder()
                .foodId(f.getFoodId())
                .brandName(f.getBrandName())
                .productName(f.getProductName())
                .petType(f.getPetType())
                .caloriesPer100g(f.getCaloriesPer100g())
                .proteinG(f.getProteinG())
                .fatG(f.getFatG())
                .carbohydrateG(f.getCarbohydrateG())
                .features(f.getFeatures())
                .imageUrl(f.getImageUrl())
                .build();
    }
}

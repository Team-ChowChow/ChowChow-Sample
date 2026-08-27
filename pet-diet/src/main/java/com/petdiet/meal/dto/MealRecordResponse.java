package com.petdiet.meal.dto;

import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.entity.UserFood;
import com.petdiet.meal.entity.MealRecord;
import com.petdiet.recipe.entity.Recipe;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class MealRecordResponse {
    private Integer mealId;
    private Integer petId;
    private String petName;
    private String mealTitle;
    private String mealNote;
    private String imageUrl;
    private String mealDate;
    private BigDecimal feedingAmountG;
    private Integer recipeId;
    private Integer commercialFoodId;
    private Integer userFoodId;
    private String createdAt;

    // recipeId/commercialFoodId/userFoodId가 가리키는 실제 대상의 표시용 정보(있을 때만 채워짐)
    private String recipeTitle;
    private String foodBrandName;
    private String foodProductName;
    private String foodImageUrl;
    private boolean isUserFood;

    public static MealRecordResponse from(MealRecord r, Recipe recipe, CommercialFood food, UserFood userFood) {
        return MealRecordResponse.builder()
                .mealId(r.getMealId())
                .petId(r.getPet() != null ? r.getPet().getPetId() : null)
                .petName(r.getPet() != null ? r.getPet().getPetName() : null)
                .mealTitle(r.getMealTitle())
                .mealNote(r.getMealNote())
                .imageUrl(r.getImageUrl())
                .mealDate(r.getMealDate())
                .feedingAmountG(r.getFeedingAmountG())
                .recipeId(r.getRecipeId())
                .commercialFoodId(r.getCommercialFoodId())
                .userFoodId(r.getUserFoodId())
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                .recipeTitle(recipe != null ? recipe.getRecipeTitle() : null)
                .foodBrandName(food != null ? food.getBrandName() : (userFood != null ? userFood.getBrandName() : null))
                .foodProductName(food != null ? food.getProductName() : (userFood != null ? userFood.getProductName() : null))
                .foodImageUrl(food != null ? food.getImageUrl() : null)
                .isUserFood(userFood != null)
                .build();
    }
}

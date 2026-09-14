package com.petdiet.ai.diet.dto;

import com.petdiet.recipe.dto.RecipeResponse;
import com.petdiet.recipe.entity.Recipe;
import com.petdiet.recipe.entity.RecipeNutritionSummary;
import com.petdiet.recipe.entity.RecipeStep;
import lombok.Builder;
import lombok.Getter;

import java.util.Comparator;
import java.util.List;

@Getter
@Builder
public class DietGenerateResponse {

    private Integer recipeId;
    private String imageUrl;
    private String title;
    private String description;
    private List<DietIngredientDto> ingredients;
    private List<String> steps;
    private List<String> stepImages;
    private String feedingAmount;
    private List<String> warnings;
    private RecipeResponse.NutritionDto nutrition;

    public static DietGenerateResponse from(Recipe recipe, DietRecommendResponse response, RecipeNutritionSummary nutrition) {
        List<String> stepImageUrls = recipe.getSteps().stream()
                .sorted(Comparator.comparing(RecipeStep::getStepNumber))
                .map(RecipeStep::getStepImage)
                .toList();

        return DietGenerateResponse.builder()
                .recipeId(recipe.getRecipeId())
                .imageUrl(recipe.getImageUrl())
                .title(response.getTitle())
                .description(response.getDescription())
                .ingredients(response.getIngredients())
                .steps(response.getSteps())
                .stepImages(stepImageUrls)
                .feedingAmount(response.getFeedingAmount())
                .warnings(response.getWarnings())
                .nutrition(nutrition == null ? null : RecipeResponse.NutritionDto.builder()
                        .totalCalories(nutrition.getTotalCalories() != null ? nutrition.getTotalCalories().doubleValue() : null)
                        .proteinG(nutrition.getProteinG() != null ? nutrition.getProteinG().doubleValue() : null)
                        .fatG(nutrition.getFatG() != null ? nutrition.getFatG().doubleValue() : null)
                        .carbohydrateG(nutrition.getCarbohydrateG() != null ? nutrition.getCarbohydrateG().doubleValue() : null)
                        .fiberG(nutrition.getFiberG() != null ? nutrition.getFiberG().doubleValue() : null)
                        .sodiumMg(nutrition.getSodiumMg() != null ? nutrition.getSodiumMg().doubleValue() : null)
                        .build())
                .build();
    }
}

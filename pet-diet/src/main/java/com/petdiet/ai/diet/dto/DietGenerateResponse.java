package com.petdiet.ai.diet.dto;

import com.petdiet.recipe.entity.Recipe;
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

    public static DietGenerateResponse from(Recipe recipe, DietRecommendResponse response) {
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
                .build();
    }
}

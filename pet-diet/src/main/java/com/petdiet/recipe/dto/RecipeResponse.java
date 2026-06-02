package com.petdiet.recipe.dto;

import com.petdiet.recipe.entity.Recipe;
import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.List;

@Getter
@Builder(toBuilder = true)
public class RecipeResponse {
    private Integer recipeId;
    private Integer menuId;
    private String petType;
    private String menuName;
    private String menuCategory;
    private Integer petId;
    private String recipeTitle;
    private String recipeDescription;
    private String recipePurpose;
    private String feedingAmount;
    private String imageUrl;
    private String warnings;
    private Boolean isAiGenerated;
    private Boolean isPublic;
    private OffsetDateTime createdAt;
    private List<RecipeIngredientDto> ingredients;
    private List<RecipeStepDto> steps;
    // 추가 메타 필드
    private String cookTime;
    private String difficulty;
    private String calories;
    private List<String> tags;
    private NutritionDto nutrition;
    private Integer likeCount;
    private Double averageRating;
    private Long reviewCount;
    private String authorNickname;
    private Boolean likedByMe;
    private Boolean bookmarkedByMe;
    private Long saveCount;

    public static RecipeResponse from(Recipe recipe) {
        return RecipeResponse.builder()
                .recipeId(recipe.getRecipeId())
                .menuId(recipe.getMenuId())
                .petType(recipe.getMenu() != null ? recipe.getMenu().getPetType() : null)
                .menuName(recipe.getMenu() != null ? recipe.getMenu().getMenuName() : null)
                .menuCategory(recipe.getMenu() != null ? recipe.getMenu().getMenuCategory() : null)
                .petId(recipe.getPet() != null ? recipe.getPet().getPetId() : null)
                .recipeTitle(recipe.getRecipeTitle())
                .recipeDescription(recipe.getRecipeDescription())
                .recipePurpose(recipe.getRecipePurpose())
                .feedingAmount(recipe.getFeedingAmount())
                .imageUrl(recipe.getImageUrl())
                .warnings(recipe.getWarnings())
                .isAiGenerated(recipe.getIsAiGenerated())
                .isPublic(recipe.getIsPublic())
                .createdAt(recipe.getCreatedAt())
                .ingredients(recipe.getIngredients().stream().map(RecipeIngredientDto::from).toList())
                .steps(recipe.getSteps().stream().map(RecipeStepDto::from).toList())
                .cookTime(recipe.getCookTime())
                .difficulty(recipe.getDifficulty())
                .calories(recipe.getCalories())
                .likeCount(recipe.getLikeCount() != null ? recipe.getLikeCount() : 0)
                .authorNickname(recipe.getUser() != null ? recipe.getUser().getUserNickname() : "관리자")
                .build();
    }

    @Getter
    @Builder
    public static class NutritionDto {
        private Double totalCalories;
        private Double proteinG;
        private Double fatG;
        private Double carbohydrateG;
        private Double sodiumMg;
        private String nutritionComment;
    }
}

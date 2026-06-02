package com.petdiet.recipe.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import com.petdiet.recipe.dto.*;
import com.petdiet.recipe.entity.*;
import com.petdiet.recipe.repository.*;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RecipeService {

    private final RecipeRepository recipeRepository;
    private final RecipeBookmarkRepository bookmarkRepository;
    private final RecipeReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final RecipeNutritionSummaryRepository nutritionRepository;
    private final JdbcTemplate jdbc;

    @PostConstruct
    public void initLikesTable() {
        jdbc.execute(
            "CREATE TABLE IF NOT EXISTS \"RecipeLikes\" (" +
            "  \"recipeId\" INT NOT NULL," +
            "  \"userId\"   INT NOT NULL," +
            "  \"createdAt\" TIMESTAMPTZ DEFAULT NOW()," +
            "  PRIMARY KEY (\"recipeId\", \"userId\")" +
            ")"
        );
    }

    @Transactional(readOnly = true)
    public Page<RecipeResponse> getPublicRecipes(Pageable pageable) {
        return recipeRepository.findAllByIsPublicTrueAndRecipeStatus("ACTIVE", pageable)
                .map(RecipeResponse::from);
    }

    @Transactional(readOnly = true)
    public List<RecipeResponse> getTrendingRecipes(int limit) {
        return recipeRepository.findTrendingRecipes(
                org.springframework.data.domain.PageRequest.of(0, limit)
        ).stream().map(RecipeResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public Page<RecipeResponse> getMyRecipes(UUID authUuid, Pageable pageable) {
        User user = findUser(authUuid);
        return recipeRepository.findAllByUserAndRecipeStatus(user, "ACTIVE", pageable)
                .map(RecipeResponse::from);
    }

    @Transactional(readOnly = true)
    public RecipeResponse getRecipe(Integer recipeId) {
        return getRecipe(recipeId, null);
    }

    @Transactional(readOnly = true)
    public RecipeResponse getRecipe(Integer recipeId, UUID authUuid) {
        Recipe recipe = findActiveRecipe(recipeId);
        List<RecipeReview> reviews = reviewRepository.findByRecipeRecipeId(recipeId);
        double avgRating = reviews.stream().mapToDouble(RecipeReview::getRating).average().orElse(0.0);
        long reviewCount = reviews.size();

        // 사용자 좋아요 여부 확인
        boolean likedByMe = false;
        if (authUuid != null) {
            try {
                Integer userId = jdbc.queryForObject(
                    "SELECT \"userId\" FROM \"Users\" WHERE \"authUuid\" = ?", Integer.class, authUuid);
                if (userId != null) {
                    Integer cnt = jdbc.queryForObject(
                        "SELECT COUNT(*) FROM \"RecipeLikes\" WHERE \"recipeId\" = ? AND \"userId\" = ?",
                        Integer.class, recipeId, userId);
                    likedByMe = cnt != null && cnt > 0;
                }
            } catch (Exception ignored) {}
        }

        RecipeResponse base = RecipeResponse.from(recipe).toBuilder()
                .averageRating(Math.round(avgRating * 10.0) / 10.0)
                .reviewCount(reviewCount)
                .likedByMe(likedByMe)
                .build();
        var nutrition = nutritionRepository.findByRecipeRecipeId(recipeId);
        if (nutrition.isEmpty()) return base;
        var n = nutrition.get();
        return base.toBuilder()
                .nutrition(RecipeResponse.NutritionDto.builder()
                        .totalCalories(n.getTotalCalories() != null ? n.getTotalCalories().doubleValue() : null)
                        .proteinG(n.getProteinG() != null ? n.getProteinG().doubleValue() : null)
                        .fatG(n.getFatG() != null ? n.getFatG().doubleValue() : null)
                        .carbohydrateG(n.getCarbohydrateG() != null ? n.getCarbohydrateG().doubleValue() : null)
                        .sodiumMg(n.getSodiumMg() != null ? n.getSodiumMg().doubleValue() : null)
                        .nutritionComment(n.getNutritionComment())
                        .build())
                .build();
    }

    @Transactional
    public RecipeResponse createRecipe(UUID authUuid, RecipeRequest req) {
        User user = findUser(authUuid);
        UserPet pet = req.getPetId() != null
                ? userPetRepository.findByPetIdAndUser(req.getPetId(), user)
                        .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."))
                : null;

        Recipe recipe = recipeRepository.save(Recipe.builder()
                .user(user)
                .pet(pet)
                .menuId(req.getMenuId())
                .recipeTitle(req.getRecipeTitle())
                .recipeDescription(req.getRecipeDescription())
                .recipePurpose(req.getRecipePurpose())
                .feedingAmount(req.getFeedingAmount())
                .isPublic(req.getIsPublic() != null ? req.getIsPublic() : true)
                .build());

        addIngredients(recipe, req.getIngredients());
        addSteps(recipe, req.getSteps());
        return RecipeResponse.from(recipeRepository.save(recipe));
    }

    @Transactional
    public RecipeResponse updateRecipe(UUID authUuid, Integer recipeId, RecipeRequest req) {
        User user = findUser(authUuid);
        Recipe recipe = findOwnedActiveRecipe(recipeId, user);

        recipe.update(req.getRecipeTitle(), req.getRecipeDescription(),
                req.getRecipePurpose(), req.getFeedingAmount(), req.getIsPublic());

        if (req.getIngredients() != null) {
            recipe.getIngredients().clear();
            addIngredients(recipe, req.getIngredients());
        }
        if (req.getSteps() != null) {
            recipe.getSteps().clear();
            addSteps(recipe, req.getSteps());
        }
        return RecipeResponse.from(recipeRepository.save(recipe));
    }

    @Transactional
    public void deleteRecipe(UUID authUuid, Integer recipeId) {
        User user = findUser(authUuid);
        Recipe recipe = findOwnedActiveRecipe(recipeId, user);
        recipe.delete();
    }

    @Transactional
    public Map<String, Object> toggleLike(UUID authUuid, Integer recipeId) {
        Recipe recipe = findActiveRecipe(recipeId);
        boolean nowLiked = false;
        if (authUuid != null) {
            Integer userId = jdbc.queryForObject(
                "SELECT \"userId\" FROM \"Users\" WHERE \"authUuid\" = ?", Integer.class, authUuid);
            if (userId != null) {
                Integer cnt = jdbc.queryForObject(
                    "SELECT COUNT(*) FROM \"RecipeLikes\" WHERE \"recipeId\" = ? AND \"userId\" = ?",
                    Integer.class, recipeId, userId);
                if (cnt != null && cnt > 0) {
                    jdbc.update("DELETE FROM \"RecipeLikes\" WHERE \"recipeId\" = ? AND \"userId\" = ?", recipeId, userId);
                    recipe.toggleLike(false);
                    nowLiked = false;
                } else {
                    jdbc.update("INSERT INTO \"RecipeLikes\" (\"recipeId\", \"userId\") VALUES (?, ?)", recipeId, userId);
                    recipe.toggleLike(true);
                    nowLiked = true;
                }
                recipeRepository.save(recipe);
            }
        }
        return Map.of("likeCount", recipe.getLikeCount(), "recipeId", recipeId, "liked", nowLiked);
    }

    @Transactional
    public void toggleBookmark(UUID authUuid, Integer recipeId) {
        User user = findUser(authUuid);
        Recipe recipe = findActiveRecipe(recipeId);
        bookmarkRepository.findByRecipeAndUser(recipe, user).ifPresentOrElse(
                bookmarkRepository::delete,
                () -> bookmarkRepository.save(RecipeBookmark.builder().recipe(recipe).user(user).build())
        );
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> getReviews(Integer recipeId) {
        Recipe recipe = findActiveRecipe(recipeId);
        return reviewRepository.findAllByRecipe(recipe).stream()
                .map(ReviewResponse::from)
                .toList();
    }

    @Transactional
    public ReviewResponse createReview(UUID authUuid, Integer recipeId, ReviewRequest req) {
        User user = findUser(authUuid);
        Recipe recipe = findActiveRecipe(recipeId);
        if (reviewRepository.existsByRecipeAndUser(recipe, user)) {
            throw new IllegalStateException("이미 리뷰를 작성했습니다.");
        }
        RecipeReview review = reviewRepository.save(RecipeReview.builder()
                .recipe(recipe)
                .user(user)
                .rating(req.getRating())
                .reviewContent(req.getReviewContent())
                .build());
        return ReviewResponse.from(review);
    }

    @Transactional
    public ReviewResponse updateReview(UUID authUuid, Integer recipeId, Integer reviewId, ReviewRequest req) {
        User user = findUser(authUuid);
        RecipeReview review = findOwnedReview(reviewId, user);
        if (!review.getRecipe().getRecipeId().equals(recipeId)) {
            throw new IllegalArgumentException("리뷰를 찾을 수 없습니다.");
        }
        review.update(req.getRating(), req.getReviewContent());
        return ReviewResponse.from(review);
    }

    @Transactional
    public void deleteReview(UUID authUuid, Integer recipeId, Integer reviewId) {
        User user = findUser(authUuid);
        RecipeReview review = findOwnedReview(reviewId, user);
        if (!review.getRecipe().getRecipeId().equals(recipeId)) {
            throw new IllegalArgumentException("리뷰를 찾을 수 없습니다.");
        }
        reviewRepository.delete(review);
    }

    private void addIngredients(Recipe recipe, List<RecipeIngredientDto> dtos) {
        if (dtos == null) return;
        dtos.forEach(dto -> recipe.getIngredients().add(
                RecipeIngredient.builder()
                        .recipe(recipe)
                        .ingredientId(dto.getIngredientId())
                        .ingredientAmount(dto.getAmount())
                        .ingredientUnit(dto.getUnit())
                        .ingredientNote(dto.getNote())
                        .build()));
    }

    private void addSteps(Recipe recipe, List<RecipeStepDto> dtos) {
        if (dtos == null) return;
        dtos.forEach(dto -> recipe.getSteps().add(
                RecipeStep.builder()
                        .recipe(recipe)
                        .stepNumber(dto.getStepNumber())
                        .stepDescription(dto.getStepDescription())
                        .stepImage(dto.getStepImage())
                        .build()));
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }

    private Recipe findActiveRecipe(Integer recipeId) {
        return recipeRepository.findByRecipeIdAndRecipeStatus(recipeId, "ACTIVE")
                .orElseThrow(() -> new IllegalArgumentException("레시피를 찾을 수 없습니다."));
    }

    private Recipe findOwnedActiveRecipe(Integer recipeId, User user) {
        Recipe recipe = findActiveRecipe(recipeId);
        if (!recipe.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("레시피를 수정할 권한이 없습니다.");
        }
        return recipe;
    }

    private RecipeReview findOwnedReview(Integer reviewId, User user) {
        RecipeReview review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다."));
        if (!review.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("리뷰를 수정할 권한이 없습니다.");
        }
        return review;
    }
}

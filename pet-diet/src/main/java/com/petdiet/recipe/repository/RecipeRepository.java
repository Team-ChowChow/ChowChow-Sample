package com.petdiet.recipe.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.recipe.entity.Recipe;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface RecipeRepository extends JpaRepository<Recipe, Integer> {

    Page<Recipe> findAllByIsPublicTrueAndRecipeStatus(String recipeStatus, Pageable pageable);

    Page<Recipe> findAllByUserAndRecipeStatus(User user, String recipeStatus, Pageable pageable);

    Optional<Recipe> findByRecipeIdAndRecipeStatus(Integer recipeId, String recipeStatus);

    @Query("SELECT r FROM Recipe r WHERE (r.imageUrl IS NULL OR r.imageUrl = '') AND r.recipeStatus = 'ACTIVE'")
    List<Recipe> findAllWithoutImage();

    @Query("SELECT r FROM Recipe r WHERE r.isPublic = true AND r.recipeStatus = 'ACTIVE' AND (r.imageUrl IS NOT NULL AND r.imageUrl <> '') ORDER BY r.likeCount DESC, r.recipeId DESC")
    List<Recipe> findTrendingRecipes(Pageable pageable);
}

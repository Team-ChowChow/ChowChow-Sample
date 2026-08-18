package com.petdiet.recipe.controller;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class RecipeV1ControllerTest {

    @Test
    void popularSortUsesLikesBeforeCreationTime() {
        assertEquals("popular", RecipeV1Controller.normalizeSearchSort("popular"));
        assertEquals(
                " ORDER BY COALESCE(r.\"likeCount\", 0) DESC, " +
                        "r.\"createdAt\" DESC, r.\"recipeId\" DESC",
                RecipeV1Controller.searchOrderBy("popular")
        );
    }

    @Test
    void latestSortUsesCreationTimeBeforeId() {
        assertEquals("latest", RecipeV1Controller.normalizeSearchSort("LATEST"));
        assertEquals(
                " ORDER BY r.\"createdAt\" DESC, r.\"recipeId\" DESC",
                RecipeV1Controller.searchOrderBy("latest")
        );
    }

    @Test
    void unknownSortFallsBackToPopular() {
        assertEquals("popular", RecipeV1Controller.normalizeSearchSort("unknown"));
    }
}

package com.petdiet.recipe.controller;

import com.petdiet.config.SupabasePrincipal;
import com.petdiet.recipe.dto.RecipeRequest;
import com.petdiet.recipe.dto.RecipeResponse;
import com.petdiet.recipe.dto.ReviewRequest;
import com.petdiet.recipe.dto.ReviewResponse;
import com.petdiet.recipe.service.RecipeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class RecipeV1Controller {

    private final RecipeService recipeService;
    private final JdbcTemplate jdbc;

    @PostMapping("/recipes/convert")
    public ResponseEntity<?> convertRecipe() {
        return ResponseEntity.ok(Map.of("message", "AI 레시피 생성이 완료되었습니다."));
    }

    @GetMapping("/recipes/{recipeId}")
    public ResponseEntity<RecipeResponse> getRecipe(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId) {
        return ResponseEntity.ok(recipeService.getRecipe(recipeId, principal != null ? principal.authUuid() : null));
    }

    @PostMapping("/recipes/{recipeId}/bookmark")
    public ResponseEntity<?> bookmarkRecipe(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId) {
        recipeService.toggleBookmark(principal.authUuid(), recipeId);
        return ResponseEntity.ok(Map.of("recipeId", recipeId, "isBookmarked", true));
    }

    @GetMapping("/recipes")
    public ResponseEntity<?> listRecipes(
            @RequestParam(defaultValue = "latest") String sort,
            Pageable pageable) {
        return ResponseEntity.ok(Map.of(
                "sortType", sort,
                "data", recipeService.getPublicRecipes(pageable).getContent()
        ));
    }

    @GetMapping("/recipes/trending")
    public ResponseEntity<?> trendingRecipes(
            @RequestParam(defaultValue = "6") int limit) {
        return ResponseEntity.ok(Map.of(
                "data", recipeService.getTrendingRecipes(limit)
        ));
    }

    @PostMapping("/recipes")
    public ResponseEntity<RecipeResponse> createRecipe(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody @Valid RecipeRequest request) {
        return ResponseEntity.ok(recipeService.createRecipe(principal.authUuid(), request));
    }

    @GetMapping("/recipes/search")
    public ResponseEntity<?> searchRecipes(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String petType,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) List<Integer> allergyIds,
            @RequestParam(required = false) List<Integer> diseaseIds,
            @RequestParam(defaultValue = "false") Boolean useMyPetFilter,
            Pageable pageable) {

        // 키워드 + 태그 + petType 복합 검색
        StringBuilder sql = new StringBuilder(
            "SELECT r.\"recipeId\" FROM \"Recipes\" r " +
            "LEFT JOIN \"RecipeTagMap\" rtm ON r.\"recipeId\" = rtm.\"recipeId\" " +
            "LEFT JOIN \"RecipeTags\" rt ON rtm.\"recipeTagId\" = rt.\"recipeTagId\" " +
            "LEFT JOIN \"Menus\" m ON r.\"menuId\" = m.\"menuId\" " +
            "WHERE r.\"isPublic\" = true AND r.\"recipeStatus\" = 'ACTIVE'"
        );
        List<Object> params = new java.util.ArrayList<>();

        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (r.\"recipeTitle\" ILIKE ? OR r.\"recipePurpose\" ILIKE ? OR r.\"recipeDescription\" ILIKE ?)");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
        }
        if (tag != null && !tag.isBlank()) {
            sql.append(" AND rt.\"tagName\" = ?");
            params.add(tag.trim());
        }
        if (petType != null && !petType.isBlank()) {
            sql.append(" AND m.\"petType\" = ?");
            params.add(petType.trim());
        }
        sql.append(" GROUP BY r.\"recipeId\" ORDER BY r.\"recipeId\" DESC LIMIT 50");

        List<Integer> ids = jdbc.queryForList(sql.toString(), Integer.class, params.toArray());
        List<RecipeResponse> results = ids.stream().map(id -> recipeService.getRecipe(id)).toList();

        return ResponseEntity.ok(Map.of(
                "keyword", keyword == null ? "" : keyword,
                "tag", tag == null ? "" : tag,
                "petType", petType == null ? "" : petType,
                "data", results
        ));
    }

    @PostMapping("/recipes/{recipeId}/like")
    public ResponseEntity<?> toggleLike(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId) {
        return ResponseEntity.ok(recipeService.toggleLike(principal != null ? principal.authUuid() : null, recipeId));
    }

    @PostMapping("/recipes/{recipeId}/reviews")
    public ResponseEntity<ReviewResponse> createReview(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId,
            @RequestBody @Valid ReviewRequest request) {
        return ResponseEntity.ok(recipeService.createReview(principal.authUuid(), recipeId, request));
    }

    @GetMapping("/recipes/{recipeId}/nutrition")
    public ResponseEntity<?> getNutrition(@PathVariable Integer recipeId) {
        return ResponseEntity.ok(Map.of(
                "recipeId", recipeId,
                "totalCalories", 0,
                "protein", 0,
                "fat", 0,
                "carbo", 0
        ));
    }

    @GetMapping("/recipes/me/bookmarks")
    public ResponseEntity<?> getMyBookmarks() {
        return ResponseEntity.ok(Map.of("bookmarks", List.of(), "totalCount", 0));
    }

    @GetMapping("/recipes/{recipeId}/reviews")
    public ResponseEntity<List<ReviewResponse>> getReviews(@PathVariable Integer recipeId) {
        return ResponseEntity.ok(recipeService.getReviews(recipeId));
    }

    @GetMapping("/allergies")
    public ResponseEntity<List<Object>> getAllergies() {
        return ResponseEntity.ok(List.of());
    }

    @GetMapping("/diseases")
    public ResponseEntity<List<Object>> getDiseases() {
        return ResponseEntity.ok(List.of());
    }

    @GetMapping("/ingredients/categories")
    public ResponseEntity<List<Object>> getIngredientCategories() {
        return ResponseEntity.ok(List.of());
    }

    @GetMapping("/menus")
    public ResponseEntity<List<Object>> getMenus() {
        return ResponseEntity.ok(List.of());
    }

    /**
     * 유사한 레시피 추천: recipePurpose 태그가 2개 이상 겹치는 레시피, 최대 4개 반환
     */
    @GetMapping("/recipes/{recipeId}/similar")
    public ResponseEntity<List<RecipeResponse>> getSimilarRecipes(@PathVariable Integer recipeId) {
        // 기준 레시피의 purpose 태그 목록
        String purposeRaw = jdbc.queryForObject(
            "SELECT COALESCE(\"recipePurpose\", '') FROM \"Recipes\" WHERE \"recipeId\" = ?",
            String.class, recipeId
        );
        if (purposeRaw == null || purposeRaw.isBlank()) {
            return ResponseEntity.ok(recipeService.getPublicRecipes(
                org.springframework.data.domain.PageRequest.of(0, 4)).getContent());
        }

        String[] tags = purposeRaw.split(",");
        // 각 태그를 LIKE 조건으로 검색해 2개 이상 매칭되는 레시피
        StringBuilder sql = new StringBuilder(
            "SELECT r.\"recipeId\", COUNT(*) AS match_count FROM \"Recipes\" r WHERE r.\"recipeId\" != ? " +
            "AND r.\"isPublic\" = true AND r.\"recipeStatus\" = 'ACTIVE' AND ("
        );
        List<Object> params = new java.util.ArrayList<>();
        params.add(recipeId);
        for (int i = 0; i < tags.length; i++) {
            if (i > 0) sql.append(" OR ");
            sql.append("r.\"recipePurpose\" LIKE ?");
            params.add("%" + tags[i].trim() + "%");
        }
        sql.append(") GROUP BY r.\"recipeId\" HAVING COUNT(*) >= 2 ORDER BY match_count DESC LIMIT 4");

        List<Integer> similarIds = jdbc.queryForList(sql.toString(), Integer.class, params.toArray());
        List<RecipeResponse> similar = similarIds.stream()
            .map(id -> recipeService.getRecipe(id))
            .toList();

        // 결과가 부족하면 최신순으로 채움
        if (similar.size() < 4) {
            List<RecipeResponse> fallback = recipeService.getPublicRecipes(
                org.springframework.data.domain.PageRequest.of(0, 8)).getContent();
            for (RecipeResponse r : fallback) {
                if (similar.size() >= 4) break;
                if (!r.getRecipeId().equals(recipeId) && similar.stream().noneMatch(s -> s.getRecipeId().equals(r.getRecipeId()))) {
                    similar = new java.util.ArrayList<>(similar);
                    ((java.util.ArrayList<RecipeResponse>) similar).add(r);
                }
            }
        }
        return ResponseEntity.ok(similar);
    }
}

package com.petdiet.recipe.controller;

import com.petdiet.config.SupabasePrincipal;
import com.petdiet.master.repository.AllergyRepository;
import com.petdiet.recipe.dto.RecipeRequest;
import com.petdiet.recipe.dto.RecipeResponse;
import com.petdiet.recipe.dto.ReviewRequest;
import com.petdiet.recipe.dto.ReviewResponse;
import com.petdiet.recipe.repository.MenuRepository;
import com.petdiet.recipe.repository.RecipeRepository;
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
    private final RecipeRepository recipeRepository;
    private final MenuRepository menuRepository;
    private final JdbcTemplate jdbc;
    private final AllergyRepository allergyRepository;

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
        return ResponseEntity.ok(recipeService.toggleBookmark(principal.authUuid(), recipeId));
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
            @RequestParam(defaultValue = "popular") String sort,
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
        String normalizedSort = normalizeSearchSort(sort);
        sql.append(" GROUP BY r.\"recipeId\"")
                .append(searchOrderBy(normalizedSort))
                .append(" LIMIT 50");

        List<Integer> ids = jdbc.queryForList(sql.toString(), Integer.class, params.toArray());
        // N+1 방지: 한 번에 조회 후 ID 순서대로 정렬
        Map<Integer, RecipeResponse> byId = recipeRepository.findAllById(ids).stream()
                .collect(java.util.stream.Collectors.toMap(
                        r -> r.getRecipeId(),
                        r -> RecipeResponse.from(r)
                ));
        List<RecipeResponse> results = ids.stream()
                .filter(byId::containsKey)
                .map(byId::get)
                .toList();

        return ResponseEntity.ok(Map.of(
                "keyword", keyword == null ? "" : keyword,
                "tag", tag == null ? "" : tag,
                "petType", petType == null ? "" : petType,
                "sortType", normalizedSort,
                "data", results
        ));
    }

    static String normalizeSearchSort(String sort) {
        return "latest".equalsIgnoreCase(sort) ? "latest" : "popular";
    }

    static String searchOrderBy(String normalizedSort) {
        if ("latest".equals(normalizedSort)) {
            return " ORDER BY r.\"createdAt\" DESC, r.\"recipeId\" DESC";
        }
        return " ORDER BY COALESCE(r.\"likeCount\", 0) DESC, " +
                "r.\"createdAt\" DESC, r.\"recipeId\" DESC";
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
    public ResponseEntity<?> getMyBookmarks(@AuthenticationPrincipal SupabasePrincipal principal) {
        var bookmarks = recipeService.getMyBookmarks(principal.authUuid());
        return ResponseEntity.ok(Map.of("bookmarks", bookmarks, "totalCount", bookmarks.size()));
    }

    @GetMapping("/recipes/me")
    public ResponseEntity<?> getMyRecipes(@AuthenticationPrincipal SupabasePrincipal principal, Pageable pageable) {
        return ResponseEntity.ok(recipeService.getMyRecipes(principal.authUuid(), pageable).getContent());
    }

    @GetMapping("/recipes/by-pet/{petId}")
    public ResponseEntity<?> getRecipesByPet(
            @AuthenticationPrincipal SupabasePrincipal principal, @PathVariable Integer petId) {
        return ResponseEntity.ok(recipeService.getRecipesByPet(principal.authUuid(), petId));
    }

    @GetMapping("/recipes/{recipeId}/reviews")
    public ResponseEntity<List<ReviewResponse>> getReviews(@PathVariable Integer recipeId) {
        return ResponseEntity.ok(recipeService.getReviews(recipeId));
    }

    @GetMapping("/allergies")
    public ResponseEntity<List<Map<String, Object>>> getAllergies() {
        return ResponseEntity.ok(
            allergyRepository.findAll().stream()
                .map(a -> Map.<String, Object>of(
                    "allergyId", a.getAllergyId(),
                    "allergyName", a.getAllergyName(),
                    "allergyDescription", a.getAllergyDescription() != null ? a.getAllergyDescription() : ""
                ))
                .toList()
        );
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
    public ResponseEntity<List<Map<String, Object>>> getMenus(
            @RequestParam(required = false, defaultValue = "DOG") String petType) {
        return ResponseEntity.ok(
            menuRepository.findAllByPetTypeAndMenuStatusOrderByMenuIdAsc(petType, "ACTIVE").stream()
                .map(m -> Map.<String, Object>of(
                    "menuId", m.getMenuId(),
                    "menuName", m.getMenuName(),
                    "menuCategory", m.getMenuCategory() != null ? m.getMenuCategory() : ""
                ))
                .toList()
        );
    }

    /**
     * 유사한 레시피 추천: 같은 종(강아지/고양이)이면서 recipePurpose 태그가 겹치는 레시피 우선,
     * 부족하면 같은 종의 최신 레시피로 채움. 최대 4개 반환.
     *
     * 이전에는 종 필터가 전혀 없고(강아지 레시피에 고양이 레시피가 섞여 나올 수 있었음),
     * 태그 2개 이상 일치를 요구해 대부분 매칭되지 않아 사실상 항상 같은 정렬 없는
     * fallback 목록(추천 로직 미반영)만 보였다. 종으로 후보를 좁히고 태그 매칭 기준을
     * 1개로 낮췄으며, fallback도 같은 종·최신순으로 바꿔 레시피마다 다른 결과가 나오게 했다.
     */
    @GetMapping("/recipes/{recipeId}/similar")
    public ResponseEntity<List<RecipeResponse>> getSimilarRecipes(@PathVariable Integer recipeId) {
        Map<String, Object> base = jdbc.queryForMap(
            "SELECT COALESCE(r.\"recipePurpose\", '') AS purpose, m.\"petType\" AS pet_type " +
            "FROM \"Recipes\" r JOIN \"Menus\" m ON m.\"menuId\" = r.\"menuId\" WHERE r.\"recipeId\" = ?",
            recipeId
        );
        String purposeRaw = (String) base.get("purpose");
        String petType = (String) base.get("pet_type");

        List<Integer> similarIds;
        if (purposeRaw == null || purposeRaw.isBlank()) {
            similarIds = List.of();
        } else {
            String[] tags = purposeRaw.split(",");
            StringBuilder sql = new StringBuilder(
                "SELECT r.\"recipeId\", COUNT(*) AS match_count FROM \"Recipes\" r " +
                "JOIN \"Menus\" m ON m.\"menuId\" = r.\"menuId\" " +
                "WHERE r.\"recipeId\" != ? AND r.\"isPublic\" = true AND r.\"recipeStatus\" = 'ACTIVE' " +
                "AND m.\"petType\" = ? AND ("
            );
            List<Object> params = new java.util.ArrayList<>();
            params.add(recipeId);
            params.add(petType);
            for (int i = 0; i < tags.length; i++) {
                if (i > 0) sql.append(" OR ");
                sql.append("r.\"recipePurpose\" LIKE ?");
                params.add("%" + tags[i].trim() + "%");
            }
            sql.append(") GROUP BY r.\"recipeId\" HAVING COUNT(*) >= 1 ORDER BY match_count DESC LIMIT 4");
            similarIds = jdbc.queryForList(sql.toString(), Integer.class, params.toArray());
        }

        List<RecipeResponse> similar = new java.util.ArrayList<>(
            similarIds.stream().map(id -> recipeService.getRecipe(id)).toList());

        if (similar.size() < 4) {
            List<Integer> fallbackIds = jdbc.queryForList(
                "SELECT r.\"recipeId\" FROM \"Recipes\" r JOIN \"Menus\" m ON m.\"menuId\" = r.\"menuId\" " +
                "WHERE r.\"recipeId\" != ? AND r.\"isPublic\" = true AND r.\"recipeStatus\" = 'ACTIVE' " +
                "AND m.\"petType\" = ? ORDER BY r.\"createdAt\" DESC LIMIT 8",
                Integer.class, recipeId, petType);
            for (Integer id : fallbackIds) {
                if (similar.size() >= 4) break;
                if (similar.stream().noneMatch(s -> s.getRecipeId().equals(id))) {
                    similar.add(recipeService.getRecipe(id));
                }
            }
        }
        return ResponseEntity.ok(similar);
    }

    @DeleteMapping("/admin/recipes/deduplicate")
    public ResponseEntity<?> deduplicateRecipes() {
        // 동일 제목 중 recipeId가 가장 작은 것만 남기고 나머지 삭제
        List<Integer> toDelete = jdbc.queryForList(
            "SELECT r.\"recipeId\" FROM \"Recipes\" r " +
            "WHERE r.\"recipeId\" NOT IN (" +
            "  SELECT MIN(r2.\"recipeId\") FROM \"Recipes\" r2 GROUP BY r2.\"recipeTitle\"" +
            ")",
            Integer.class
        );
        if (toDelete.isEmpty()) {
            return ResponseEntity.ok(Map.of("message", "중복 없음", "deleted", 0));
        }
        jdbc.update(
            "DELETE FROM \"Recipes\" WHERE \"recipeId\" = ANY(?)",
            (Object) toDelete.stream().mapToInt(Integer::intValue).toArray()
        );
        return ResponseEntity.ok(Map.of(
            "message", "중복 제거 완료",
            "deleted", toDelete.size(),
            "deletedIds", toDelete
        ));
    }
}

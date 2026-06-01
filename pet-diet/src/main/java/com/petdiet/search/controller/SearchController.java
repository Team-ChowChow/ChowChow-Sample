package com.petdiet.search.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/search")
@RequiredArgsConstructor
public class SearchController {

    private final JdbcTemplate jdbc;

    /**
     * 인기 검색어: 최근 등록된 레시피의 주재료(1번째 재료) 기준 상위 10개
     */
    @GetMapping("/popular")
    public ResponseEntity<?> getPopularSearches() {
        List<String> keywords = jdbc.queryForList(
            "SELECT DISTINCT COALESCE(i.\"ingredientName\", ri.\"ingredientNote\") AS kw " +
            "FROM \"RecipeIngredients\" ri " +
            "JOIN \"Recipes\" r ON ri.\"recipeId\" = r.\"recipeId\" " +
            "LEFT JOIN \"Ingredients\" i ON ri.\"ingredientId\" = i.\"ingredientId\" " +
            "WHERE r.\"isPublic\" = true AND r.\"recipeStatus\" = 'ACTIVE' " +
            "  AND ri.\"ingredientAmount\" IS NOT NULL " +
            "ORDER BY kw " +
            "LIMIT 10",
            String.class
        );
        List<String> filtered = keywords.stream()
            .filter(k -> k != null && !k.isBlank())
            .collect(Collectors.toList());
        return ResponseEntity.ok(Map.of("popular", filtered, "totalCount", filtered.size()));
    }

    /**
     * 레시피 카테고리 목록: RecipeTags 마스터 데이터의 PURPOSE 타입 태그
     */
    @GetMapping("/categories")
    public ResponseEntity<?> getCategories() {
        List<String> categories = jdbc.queryForList(
            "SELECT \"tagName\" FROM \"RecipeTags\" WHERE \"tagType\" = 'PURPOSE' ORDER BY \"tagName\"",
            String.class
        );
        return ResponseEntity.ok(Map.of("categories", categories, "totalCount", categories.size()));
    }

    @GetMapping("/recent")
    public ResponseEntity<?> getRecentSearches() {
        return ResponseEntity.ok(Map.of("recent", List.of(), "totalCount", 0));
    }

    @PostMapping("/log")
    public ResponseEntity<?> saveSearchLog(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(Map.of(
                "searchKeyword", body.getOrDefault("searchKeyword", ""),
                "message", "검색 기록이 저장되었습니다."
        ));
    }

    @DeleteMapping("/{searchLogId}")
    public ResponseEntity<?> deleteSearchLog(@PathVariable Long searchLogId) {
        return ResponseEntity.ok(Map.of("searchLogId", searchLogId, "message", "검색 기록이 삭제되었습니다."));
    }

    @DeleteMapping("/recent/all")
    public ResponseEntity<?> deleteAllSearchLogs() {
        return ResponseEntity.ok(Map.of("message", "전체 검색 기록이 삭제되었습니다."));
    }
}

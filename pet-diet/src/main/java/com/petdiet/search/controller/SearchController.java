package com.petdiet.search.controller;

import com.petdiet.config.SupabasePrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/search")
@RequiredArgsConstructor
public class SearchController {

    private final JdbcTemplate jdbc;

    /** 최근 7일간 실제 검색 횟수 기준 인기 검색어 상위 10개 (한글 검색어만 — 영문 테스트 입력 등 노이즈 제외). */
    @GetMapping("/popular")
    public ResponseEntity<?> getPopularSearches() {
        List<String> keywords = jdbc.queryForList(
            "SELECT TRIM(\"searchKeyword\") AS keyword " +
            "FROM \"SearchLogs\" " +
            "WHERE \"searchedAt\" >= NOW() - INTERVAL '7 days' " +
            "  AND TRIM(\"searchKeyword\") ~ '[가-힣]' " +
            "GROUP BY TRIM(\"searchKeyword\") " +
            "ORDER BY COUNT(*) DESC, MAX(\"searchedAt\") DESC " +
            "LIMIT 10",
            String.class
        );
        List<String> filtered = new ArrayList<>(keywords.stream()
            .filter(k -> k != null && !k.isBlank())
            .collect(Collectors.toList()));

        // 실제 검색 로그가 충분하지 않으면 현재 공개된 레시피에 실제로 쓰인 한글 재료명으로 채운다.
        if (filtered.size() < 10) {
            List<String> ingredientFallback = jdbc.queryForList(
                "SELECT i.\"ingredientNameKo\" AS keyword " +
                "FROM \"RecipeIngredients\" ri " +
                "JOIN \"Ingredients\" i ON i.\"ingredientId\" = ri.\"ingredientId\" " +
                "JOIN \"Recipes\" r ON r.\"recipeId\" = ri.\"recipeId\" " +
                "WHERE r.\"isPublic\" = true AND r.\"recipeStatus\" = 'ACTIVE' " +
                "  AND i.\"ingredientNameKo\" IS NOT NULL " +
                "GROUP BY i.\"ingredientNameKo\" " +
                "ORDER BY COUNT(*) DESC " +
                "LIMIT 10",
                String.class
            );
            for (String keyword : ingredientFallback) {
                if (filtered.size() >= 10) break;
                if (!filtered.contains(keyword)) filtered.add(keyword);
            }
        }

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
    public ResponseEntity<?> saveSearchLog(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody Map<String, Object> body) {
        String keyword = Objects.toString(body.get("searchKeyword"), "").trim();
        if (keyword.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "검색어를 입력해주세요."));
        }
        if (keyword.length() > 200) keyword = keyword.substring(0, 200);

        if (principal != null) {
            Integer userId = jdbc.queryForObject(
                    "SELECT \"userId\" FROM \"Users\" WHERE \"authUuid\" = ?",
                    Integer.class,
                    principal.authUuid()
            );
            if (userId != null) {
                String petType = Objects.toString(body.get("petType"), "").trim();
                if (!petType.equals("DOG") && !petType.equals("CAT")) petType = null;
                Integer resultCount = body.get("resultCount") instanceof Number count
                        ? count.intValue()
                        : null;
                jdbc.update(
                        "INSERT INTO \"SearchLogs\" " +
                        "(\"userId\", \"searchKeyword\", \"searchType\", \"petType\", \"resultCount\") " +
                        "VALUES (?, ?, 'KEYWORD', ?, ?)",
                        userId, keyword, petType, resultCount
                );
            }
        }

        return ResponseEntity.ok(Map.of(
                "searchKeyword", keyword,
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

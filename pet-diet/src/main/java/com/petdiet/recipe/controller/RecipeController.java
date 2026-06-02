package com.petdiet.recipe.controller;

import com.petdiet.ai.image.service.ImageGenerateService;
import com.petdiet.config.SupabasePrincipal;
import com.petdiet.recipe.dto.*;
import com.petdiet.recipe.entity.Recipe;
import com.petdiet.recipe.repository.RecipeRepository;
import com.petdiet.recipe.service.RecipeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@RestController
@RequestMapping("/api/recipes")
@RequiredArgsConstructor
public class RecipeController {

    private final RecipeService recipeService;
    private final RecipeRepository recipeRepository;
    private final ImageGenerateService imageGenerateService;
    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    @Value("${openai.api-key}")
    private String openaiApiKey;

    @GetMapping
    public ResponseEntity<Page<RecipeResponse>> getPublicRecipes(
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(recipeService.getPublicRecipes(pageable));
    }

    @GetMapping("/my")
    public ResponseEntity<Page<RecipeResponse>> getMyRecipes(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PageableDefault(size = 20) Pageable pageable) {
        return ResponseEntity.ok(recipeService.getMyRecipes(principal.authUuid(), pageable));
    }

    @GetMapping("/{recipeId}")
    public ResponseEntity<RecipeResponse> getRecipe(@PathVariable Integer recipeId) {
        return ResponseEntity.ok(recipeService.getRecipe(recipeId));
    }

    @PostMapping
    public ResponseEntity<RecipeResponse> createRecipe(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody @Valid RecipeRequest request) {
        return ResponseEntity.ok(recipeService.createRecipe(principal.authUuid(), request));
    }

    @PatchMapping("/{recipeId}")
    public ResponseEntity<RecipeResponse> updateRecipe(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId,
            @RequestBody RecipeRequest request) {
        return ResponseEntity.ok(recipeService.updateRecipe(principal.authUuid(), recipeId, request));
    }

    @DeleteMapping("/{recipeId}")
    public ResponseEntity<Void> deleteRecipe(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId) {
        recipeService.deleteRecipe(principal.authUuid(), recipeId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{recipeId}/bookmark")
    public ResponseEntity<Void> toggleBookmark(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId) {
        recipeService.toggleBookmark(principal.authUuid(), recipeId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{recipeId}/reviews")
    public ResponseEntity<List<ReviewResponse>> getReviews(@PathVariable Integer recipeId) {
        return ResponseEntity.ok(recipeService.getReviews(recipeId));
    }

    @PostMapping("/{recipeId}/reviews")
    public ResponseEntity<ReviewResponse> createReview(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId,
            @RequestBody @Valid ReviewRequest request) {
        return ResponseEntity.ok(recipeService.createReview(principal.authUuid(), recipeId, request));
    }

    @PatchMapping("/{recipeId}/reviews/{reviewId}")
    public ResponseEntity<ReviewResponse> updateReview(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId,
            @PathVariable Integer reviewId,
            @RequestBody @Valid ReviewRequest request) {
        return ResponseEntity.ok(recipeService.updateReview(principal.authUuid(), recipeId, reviewId, request));
    }

    @DeleteMapping("/{recipeId}/reviews/{reviewId}")
    public ResponseEntity<Void> deleteReview(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer recipeId,
            @PathVariable Integer reviewId) {
        recipeService.deleteReview(principal.authUuid(), recipeId, reviewId);
        return ResponseEntity.noContent().build();
    }

    /**
     * OpenAI로 레시피 메타데이터(조리시간, 난이도, 칼로리, 영양정보, 태그) 일괄 보강 (관리자용)
     * POST /api/recipes/admin/enrich-meta
     */
    @PostMapping("/admin/enrich-meta")
    public ResponseEntity<Map<String, Object>> enrichMeta() {
        // JDBC로 대상 레시피 조회 (JPA 트랜잭션 없이)
        List<Map<String, Object>> targets = jdbc.queryForList(
            "SELECT \"recipeId\", \"recipeTitle\", \"recipeDescription\", \"recipePurpose\" " +
            "FROM \"Recipes\" WHERE \"recipeStatus\" = 'ACTIVE' AND (\"cookTime\" IS NULL OR \"difficulty\" IS NULL)"
        );

        AtomicInteger success = new AtomicInteger(0);
        AtomicInteger failed = new AtomicInteger(0);

        WebClient client = WebClient.builder()
                .baseUrl("https://api.openai.com")
                .defaultHeader("Authorization", "Bearer " + openaiApiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();

        // 태그 목록 미리 조회
        List<Map<String, Object>> allTags = jdbc.queryForList(
                "SELECT \"recipeTagId\", \"tagName\" FROM \"RecipeTags\"");

        for (Map<String, Object> recipe : targets) {
            Integer recipeId = (Integer) recipe.get("recipeId");
            String title = (String) recipe.get("recipeTitle");
            String desc = recipe.get("recipeDescription") != null ? (String) recipe.get("recipeDescription") : "";
            String purpose = recipe.get("recipePurpose") != null ? (String) recipe.get("recipePurpose") : "";

            try {
                String prompt = String.format(
                    "반려동물(강아지/고양이) 레시피 정보를 JSON으로 답해줘. 답변은 JSON만 출력해.\n" +
                    "레시피명: %s\n설명: %s\n목적: %s\n\n" +
                    "다음 형식으로만 답해:\n" +
                    "{\"cookTime\":\"20분\",\"difficulty\":\"쉬움\",\"calories\":\"180kcal\",\"protein\":25.0,\"fat\":5.0,\"carbohydrate\":10.0,\"sodium\":120.0,\"nutritionComment\":\"고단백 저지방 식단\",\"tips\":[\"팁1\",\"팁2\"],\"tagNames\":[\"저지방\",\"고단백\"]}\n\n" +
                    "difficulty는 '쉬움','보통','어려움' 중 하나. tagNames는 이 목록에서만 선택: 저지방,고단백,다이어트,면역력 강화,알러지프리,관절 건강,피부 모질 개선,신장 건강,당뇨 관리,비만 관리,췌장염 관리,닭고기,소고기,연어,채소 위주,수제 간식,생식",
                    title, desc, purpose
                );

                String response = client.post()
                        .uri("/v1/chat/completions")
                        .bodyValue(Map.of(
                                "model", "gpt-4o-mini",
                                "messages", List.of(Map.of("role", "user", "content", prompt)),
                                "temperature", 0.3,
                                "max_tokens", 400
                        ))
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();

                JsonNode root = objectMapper.readTree(response);
                String content = root.path("choices").get(0).path("message").path("content").stringValue();
                if (content == null) continue;

                // JSON 블록 파싱
                int start = content.indexOf('{');
                int end = content.lastIndexOf('}');
                if (start < 0 || end < 0) continue;
                JsonNode data = objectMapper.readTree(content.substring(start, end + 1));

                // 기본 메타 업데이트 (JDBC)
                String cookTime = strVal(data.path("cookTime"));
                String difficulty = strVal(data.path("difficulty"));
                String calories = strVal(data.path("calories"));
                jdbc.update(
                    "UPDATE \"Recipes\" SET \"cookTime\"=?, \"difficulty\"=?, \"calories\"=? WHERE \"recipeId\"=?",
                    cookTime, difficulty, calories, recipeId
                );

                // warnings에 팁 저장
                JsonNode tipsNode = data.path("tips");
                if (tipsNode.isArray() && !tipsNode.isEmpty()) {
                    StringBuilder tips = new StringBuilder();
                    for (JsonNode t : tipsNode) {
                        String tip = strVal(t);
                        if (tip != null) tips.append(tip).append("\n");
                    }
                    jdbc.update("UPDATE \"Recipes\" SET \"warnings\" = ? WHERE \"recipeId\" = ?",
                            tips.toString().trim(), recipeId);
                }

                // 영양정보 upsert
                double protein = numVal(data.path("protein"));
                double fat = numVal(data.path("fat"));
                double carbohydrate = numVal(data.path("carbohydrate"));
                double sodium = numVal(data.path("sodium"));
                String nutritionComment = strVal(data.path("nutritionComment"), "");
                jdbc.update(
                    "INSERT INTO \"RecipeNutritionSummaries\" (\"recipeId\",\"proteinG\",\"fatG\",\"carbohydrateG\",\"sodiumMg\",\"nutritionComment\") " +
                    "VALUES (?,?,?,?,?,?) ON CONFLICT (\"recipeId\") DO UPDATE SET \"proteinG\"=?,\"fatG\"=?,\"carbohydrateG\"=?,\"sodiumMg\"=?,\"nutritionComment\"=?",
                    recipeId, protein, fat, carbohydrate, sodium, nutritionComment,
                    protein, fat, carbohydrate, sodium, nutritionComment
                );

                // 태그 매핑
                JsonNode tagNamesNode = data.path("tagNames");
                if (tagNamesNode.isArray()) {
                    for (JsonNode tn : tagNamesNode) {
                        String tagName = strVal(tn);
                        allTags.stream()
                                .filter(t -> tagName.equals(t.get("tagName")))
                                .findFirst()
                                .ifPresent(t -> {
                                    Integer tagId = (Integer) t.get("recipeTagId");
                                    try {
                                        jdbc.update(
                                            "INSERT INTO \"RecipeTagMap\" (\"recipeId\",\"recipeTagId\") VALUES (?,?) ON CONFLICT DO NOTHING",
                                            recipeId, tagId
                                        );
                                    } catch (Exception ignored) {}
                                });
                    }
                }

                success.incrementAndGet();
                log.info("레시피 보강 완료: recipeId={}, cookTime={}, difficulty={}", recipeId, cookTime, difficulty);
                Thread.sleep(300); // rate limit 방지
            } catch (Exception e) {
                log.warn("레시피 보강 실패: recipeId={}, error={}", recipeId, e.getMessage());
                failed.incrementAndGet();
            }
        }

        return ResponseEntity.ok(Map.of("total", targets.size(), "success", success.get(), "failed", failed.get()));
    }

    private static String strVal(JsonNode node) {
        return strVal(node, null);
    }

    private static String strVal(JsonNode node, String defaultVal) {
        if (node == null || node.isMissingNode() || node.isNull()) return defaultVal;
        return node.isString() ? node.stringValue() : defaultVal;
    }

    private static double numVal(JsonNode node) {
        if (node == null || node.isMissingNode() || node.isNull()) return 0.0;
        return node.isNumber() ? node.numberValue().doubleValue() : 0.0;
    }

    /**
     * 이미지가 없는 레시피에 일괄 이미지 생성 (관리자용)
     * POST /api/recipes/admin/generate-missing-images
     */
    @PostMapping("/admin/generate-missing-images")
    @Transactional
    public ResponseEntity<Map<String, Object>> generateMissingImages() {
        List<Recipe> targets = recipeRepository.findAllWithoutImage();
        AtomicInteger success = new AtomicInteger(0);
        AtomicInteger failed = new AtomicInteger(0);

        for (Recipe recipe : targets) {
            try {
                String imageUrl = imageGenerateService
                        .generateRecipeImage(recipe.getRecipeTitle(), List.of(), recipe.getRecipeDescription())
                        .getImageUrl();
                if (imageUrl != null && !imageUrl.isBlank()) {
                    recipe.updateImage(imageUrl);
                    recipeRepository.save(recipe);
                    success.incrementAndGet();
                    log.info("이미지 생성 완료: recipeId={}", recipe.getRecipeId());
                }
            } catch (Exception e) {
                log.warn("이미지 생성 실패: recipeId={}, error={}", recipe.getRecipeId(), e.getMessage());
                failed.incrementAndGet();
            }
        }

        return ResponseEntity.ok(Map.of(
                "total", targets.size(),
                "success", success.get(),
                "failed", failed.get()
        ));
    }
}

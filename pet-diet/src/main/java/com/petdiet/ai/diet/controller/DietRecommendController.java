package com.petdiet.ai.diet.controller;

import com.petdiet.ai.diet.dto.DietGenerateResponse;
import com.petdiet.ai.diet.dto.DietRecommendRequest;
import com.petdiet.ai.diet.dto.DietRecommendResponse;
import com.petdiet.recipe.entity.Recipe;
import com.petdiet.ai.diet.service.DietRecommendService;
import com.petdiet.ai.diet.service.DietRecommendService.RecommendContext;
import com.petdiet.ai.diet.service.DietRecipeSaveService;
import com.petdiet.ai.image.service.ImageGenerateService;
import com.petdiet.config.SupabasePrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Slf4j
@RestController
@RequestMapping("/api/ai/diet")
@RequiredArgsConstructor
public class DietRecommendController {

    private final DietRecommendService dietRecommendService;
    private final DietRecipeSaveService dietRecipeSaveService;
    private final ImageGenerateService imageGenerateService;

    /**
     * 식단 추천만 반환 (레시피 저장 없음)
     */
    @PostMapping("/recommend")
    public ResponseEntity<DietRecommendResponse> recommend(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody @Valid DietRecommendRequest request) {
        return ResponseEntity.ok(dietRecommendService.recommend(
                principal.authUuid(), request.getPetId(), request.getUserNotes()));
    }

    /**
     * 식단 추천 + 레시피 자동 저장 + 이미지 생성 (옵션)
     * recipeId와 imageUrl을 포함한 DietGenerateResponse를 반환
     */
    @PostMapping("/recommend-and-save")
    public ResponseEntity<DietGenerateResponse> recommendAndSave(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody @Valid DietRecommendRequest request,
            @RequestParam(defaultValue = "false") boolean generateImage) {

        RecommendContext ctx = dietRecommendService.recommendWithContext(
                principal.authUuid(), request.getPetId(), request.getUserNotes());

        String imageUrl = null;
        List<String> stepImages = new ArrayList<>();

        if (generateImage) {
            List<String> steps = ctx.response().getSteps() != null ? ctx.response().getSteps() : List.of();
            String title = ctx.response().getTitle();

            // 레시피 대표 이미지 + 단계별 이미지를 병렬 생성
            List<String> ingredientNames = ctx.response().getIngredients() != null
                    ? ctx.response().getIngredients().stream().map(i -> i.getName()).toList()
                    : List.of();

            CompletableFuture<String> recipeFuture = CompletableFuture.supplyAsync(() -> {
                try {
                    return imageGenerateService.generateRecipeImage(title, ingredientNames, ctx.response().getDescription()).getImageUrl();
                } catch (Exception e) {
                    log.warn("대표 이미지 생성 실패: {}", e.getMessage());
                    return null;
                }
            });

            List<CompletableFuture<String>> stepFutures = new ArrayList<>();
            for (int i = 0; i < steps.size(); i++) {
                final String step = steps.get(i);
                final int stepNum = i + 1;
                stepFutures.add(CompletableFuture.supplyAsync(() -> {
                    try {
                        return imageGenerateService.generateStepImage(step, title, stepNum).getImageUrl();
                    } catch (Exception e) {
                        log.warn("단계 {} 이미지 생성 실패: {}", stepNum, e.getMessage());
                        return null;
                    }
                }));
            }

            // 모든 이미지 생성 완료 대기
            CompletableFuture.allOf(
                    CompletableFuture.allOf(stepFutures.toArray(new CompletableFuture[0])),
                    recipeFuture
            ).join();

            try { imageUrl = recipeFuture.get(); } catch (Exception ignored) {}
            for (CompletableFuture<String> f : stepFutures) {
                try { stepImages.add(f.get()); } catch (Exception ignored) { stepImages.add(null); }
            }
        }

        Recipe saved = dietRecipeSaveService.saveAiRecipe(ctx.user(), ctx.pet(), ctx.response(), imageUrl, stepImages);

        return ResponseEntity.ok(DietGenerateResponse.from(saved, ctx.response()));
    }
}

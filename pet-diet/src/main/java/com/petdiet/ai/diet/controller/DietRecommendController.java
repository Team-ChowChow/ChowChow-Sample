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

import java.util.List;

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
        List<String> stepImages = List.of();

        if (generateImage) {
            String title = ctx.response().getTitle();
            List<String> ingredientNames = ctx.response().getIngredients() != null
                    ? ctx.response().getIngredients().stream().map(i -> i.getName()).toList()
                    : List.of();

            // 대표 이미지만 생성 (step 이미지는 시간 초과 방지를 위해 생략)
            try {
                imageUrl = imageGenerateService.generateRecipeImage(title, ingredientNames, ctx.response().getDescription()).getImageUrl();
            } catch (Exception e) {
                log.warn("대표 이미지 생성 실패: {}", e.getMessage());
            }
        }

        Recipe saved = dietRecipeSaveService.saveAiRecipe(ctx.user(), ctx.pet(), ctx.response(), imageUrl, stepImages);

        return ResponseEntity.ok(DietGenerateResponse.from(saved, ctx.response()));
    }
}

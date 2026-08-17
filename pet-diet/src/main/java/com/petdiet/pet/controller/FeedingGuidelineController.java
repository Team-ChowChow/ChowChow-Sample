package com.petdiet.pet.controller;

import com.petdiet.config.SupabasePrincipal;
import com.petdiet.pet.dto.FeedingGuidelineResponse;
import com.petdiet.pet.service.FeedingGuidelineService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/pets/{petId}/feeding-guideline")
@RequiredArgsConstructor
public class FeedingGuidelineController {

    private final FeedingGuidelineService feedingGuidelineService;

    @GetMapping
    public ResponseEntity<FeedingGuidelineResponse> getGuideline(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer petId,
            @RequestParam(required = false) Integer recipeId,
            @RequestParam(required = false) Integer commercialFoodId,
            @RequestParam(required = false) BigDecimal kcalPer100g,
            @RequestParam(required = false) BigDecimal currentFeedingAmountG) {
        return ResponseEntity.ok(feedingGuidelineService.calculate(
                principal.authUuid(), petId, recipeId, commercialFoodId, kcalPer100g, currentFeedingAmountG));
    }
}

package com.petdiet.ai.foodtransition.controller;

import com.petdiet.ai.foodtransition.dto.FoodTransitionRequest;
import com.petdiet.ai.foodtransition.dto.FoodTransitionResponse;
import com.petdiet.ai.foodtransition.service.FoodTransitionService;
import com.petdiet.config.SupabasePrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai/food-transition")
@RequiredArgsConstructor
public class FoodTransitionController {

    private final FoodTransitionService foodTransitionService;

    @PostMapping("/recommend")
    public ResponseEntity<FoodTransitionResponse> recommend(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody FoodTransitionRequest request) {
        return ResponseEntity.ok(foodTransitionService.recommend(
                principal.authUuid(), request.getPetId(),
                request.getCurrentFoodId(), request.getCurrentUserFoodId(),
                request.getTargetFoodId(), request.getTargetUserFoodId()));
    }
}

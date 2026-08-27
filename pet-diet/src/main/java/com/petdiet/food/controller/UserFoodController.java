package com.petdiet.food.controller;

import com.petdiet.config.SupabasePrincipal;
import com.petdiet.food.dto.UserFoodRequest;
import com.petdiet.food.dto.UserFoodResponse;
import com.petdiet.food.service.UserFoodService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** 사용자가 직접 등록한 사료(카탈로그에 없는 사료). 본인에게만 조회/선택된다. */
@RestController
@RequestMapping("/api/v1/user-foods")
@RequiredArgsConstructor
public class UserFoodController {

    private final UserFoodService userFoodService;

    @GetMapping
    public ResponseEntity<List<UserFoodResponse>> getMyFoods(@AuthenticationPrincipal SupabasePrincipal principal) {
        return ResponseEntity.ok(userFoodService.getMyFoods(principal.authUuid()));
    }

    @PostMapping
    public ResponseEntity<UserFoodResponse> create(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody @Valid UserFoodRequest request) {
        return ResponseEntity.ok(userFoodService.create(principal.authUuid(), request));
    }

    @DeleteMapping("/{userFoodId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer userFoodId) {
        userFoodService.delete(principal.authUuid(), userFoodId);
        return ResponseEntity.noContent().build();
    }
}

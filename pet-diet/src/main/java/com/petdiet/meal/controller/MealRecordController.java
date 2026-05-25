package com.petdiet.meal.controller;

import com.petdiet.config.SupabasePrincipal;
import com.petdiet.meal.dto.MealRecordRequest;
import com.petdiet.meal.dto.MealRecordResponse;
import com.petdiet.meal.service.MealRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/meal-records")
@RequiredArgsConstructor
public class MealRecordController {

    private final MealRecordService mealRecordService;

    @GetMapping
    public ResponseEntity<List<MealRecordResponse>> getMyRecords(
            @AuthenticationPrincipal SupabasePrincipal principal) {
        return ResponseEntity.ok(mealRecordService.getMyRecords(principal.authUuid()));
    }

    @PostMapping
    public ResponseEntity<MealRecordResponse> create(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody MealRecordRequest request) {
        return ResponseEntity.ok(mealRecordService.create(principal.authUuid(), request));
    }

    @PostMapping("/upload-photo")
    public ResponseEntity<Map<String, String>> uploadPhoto(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestParam("file") MultipartFile file) throws IOException {
        String url = mealRecordService.uploadPhoto(principal.authUuid(), file);
        return ResponseEntity.ok(Map.of("imageUrl", url));
    }

    @DeleteMapping("/{mealId}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer mealId) {
        mealRecordService.delete(principal.authUuid(), mealId);
        return ResponseEntity.noContent().build();
    }
}

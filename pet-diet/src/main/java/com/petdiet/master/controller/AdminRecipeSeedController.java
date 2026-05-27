package com.petdiet.master.controller;

import com.petdiet.master.service.AdminRecipeSeedService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/recipes")
@RequiredArgsConstructor
public class AdminRecipeSeedController {

    private final AdminRecipeSeedService adminRecipeSeedService;

    @PostMapping("/seed")
    public ResponseEntity<Map<String, Object>> seed() {
        Map<String, Object> result = adminRecipeSeedService.seedRecipes();
        return ResponseEntity.ok(result);
    }

    @PostMapping("/seed-step-images")
    public ResponseEntity<Map<String, Object>> seedStepImages() {
        Map<String, Object> result = adminRecipeSeedService.seedStepImages();
        return ResponseEntity.ok(result);
    }
}

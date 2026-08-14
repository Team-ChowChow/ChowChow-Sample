package com.petdiet.food.controller;

import com.petdiet.food.service.CommercialFoodSyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/foods")
@RequiredArgsConstructor
public class AdminCommercialFoodController {

    private final CommercialFoodSyncService syncService;

    @PostMapping("/sync")
    public ResponseEntity<Map<String, Object>> sync() {
        int saved = syncService.sync();
        return ResponseEntity.ok(Map.of("message", "사료 데이터 동기화 완료", "saved", saved));
    }
}

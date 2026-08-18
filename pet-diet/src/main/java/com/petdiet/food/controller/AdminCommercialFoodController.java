package com.petdiet.food.controller;

import com.petdiet.food.service.CommercialFoodSyncService;
import com.petdiet.food.service.KoreanFoodSeedService;
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
    private final KoreanFoodSeedService koreanFoodSeedService;

    @PostMapping("/sync")
    public ResponseEntity<Map<String, Object>> sync() {
        int saved = syncService.sync();
        return ResponseEntity.ok(Map.of("message", "사료 데이터 동기화 완료", "saved", saved));
    }

    @PostMapping("/seed-kr")
    public ResponseEntity<Map<String, Object>> seedKr() {
        int saved = koreanFoodSeedService.seed();
        return ResponseEntity.ok(Map.of("message", "국내 사료 큐레이션 데이터 시딩 완료", "saved", saved));
    }

    @PostMapping("/remove-uncurated")
    public ResponseEntity<Map<String, Object>> removeUncurated() {
        long removed = koreanFoodSeedService.removeUncurated();
        return ResponseEntity.ok(Map.of("message", "큐레이션되지 않은 사료 데이터 삭제 완료", "removed", removed));
    }

    @PostMapping("/fill-images")
    public ResponseEntity<Map<String, Object>> fillImages() {
        int filled = koreanFoodSeedService.fillMissingImages();
        return ResponseEntity.ok(Map.of("message", "네이버 이미지 검색으로 사료 이미지 채우기 완료", "filled", filled));
    }
}

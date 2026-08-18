package com.petdiet.food.service;

import com.petdiet.food.client.OpenPetFoodFactsClient;
import com.petdiet.food.client.OpenPetFoodFactsClient.FoodResult;
import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.repository.CommercialFoodRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CommercialFoodSyncService {

    private final OpenPetFoodFactsClient client;
    private final CommercialFoodRepository repository;

    // 브랜드별 검색은 브랜드 태그를 일일이 알아야 하고 커버리지가 좁아서(예: 인기 브랜드 16개 시도해도 40여건),
    // 카테고리(강아지/고양이 사료) 전체를 페이지네이션으로 훑는 방식이 훨씬 포괄적(원본 기준 강아지 961건, 고양이 1552건).
    private static final List<String> CATEGORY_TAGS = List.of("en:dog-food", "en:cat-food");

    @Transactional
    public int sync() {
        int saved = 0;
        for (String categoryTag : CATEGORY_TAGS) {
            for (FoodResult r : client.searchByCategory(categoryTag, 1000)) {
                if (r.barcode() != null && repository.findByBarcode(r.barcode()).isPresent()) continue;
                repository.save(CommercialFood.builder()
                        .barcode(r.barcode())
                        .brandName(r.brand() != null ? r.brand() : "기타")
                        .productName(r.productName())
                        .petType(r.petType())
                        .caloriesPer100g(r.calories())
                        .proteinG(r.protein())
                        .fatG(r.fat())
                        .carbohydrateG(r.carbs())
                        .ingredientsText(r.ingredientsText())
                        .imageUrl(r.imageUrl())
                        .source("OPFF")
                        .build());
                saved++;
            }
        }
        log.info("사료 데이터 동기화 완료: {}건", saved);
        return saved;
    }
}

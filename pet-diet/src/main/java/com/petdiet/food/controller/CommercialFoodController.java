package com.petdiet.food.controller;

import com.petdiet.food.dto.CommercialFoodResponse;
import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.repository.CommercialFoodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/foods")
@RequiredArgsConstructor
public class CommercialFoodController {

    private final CommercialFoodRepository repository;

    @GetMapping("/search")
    public ResponseEntity<List<CommercialFoodResponse>> search(
            @RequestParam String query,
            @RequestParam(required = false) String petType,
            @RequestParam(required = false) String brand) {
        List<CommercialFood> results = repository.searchByPopularity(query, petType, brand, Pageable.unpaged());
        return ResponseEntity.ok(results.stream().map(CommercialFoodResponse::from).toList());
    }

    /** 1단계(강아지/고양이) 선택 후 2단계로 보여줄 브랜드 목록 */
    @GetMapping("/brands")
    public ResponseEntity<List<String>> brands(@RequestParam(required = false) String petType) {
        return ResponseEntity.ok(repository.findDistinctBrandNames(petType));
    }
}

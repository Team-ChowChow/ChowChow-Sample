package com.petdiet.food.controller;

import com.petdiet.food.dto.CommercialFoodResponse;
import com.petdiet.food.repository.CommercialFoodRepository;
import lombok.RequiredArgsConstructor;
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
    public ResponseEntity<List<CommercialFoodResponse>> search(@RequestParam String query) {
        return ResponseEntity.ok(
                repository.findTop30ByProductNameContainingIgnoreCaseOrBrandNameContainingIgnoreCase(query, query)
                        .stream().map(CommercialFoodResponse::from).toList());
    }
}

package com.petdiet.ingredient.controller;

import com.petdiet.ingredient.dto.LowestPriceResponse;
import com.petdiet.ingredient.service.IngredientPriceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class IngredientPriceController {

    private final IngredientPriceService ingredientPriceService;

    @GetMapping("/ingredients/lowest-price")
    public ResponseEntity<LowestPriceResponse> getLowestPrice(@RequestParam String name) {
        return ResponseEntity.ok(ingredientPriceService.getLowestPrice(name));
    }
}

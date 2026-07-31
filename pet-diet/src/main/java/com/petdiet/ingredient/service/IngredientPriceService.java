package com.petdiet.ingredient.service;

import com.petdiet.ingredient.client.NaverShoppingClient;
import com.petdiet.ingredient.dto.LowestPriceResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class IngredientPriceService {

    private final NaverShoppingClient naverShoppingClient;

    public LowestPriceResponse getLowestPrice(String ingredientName) {
        return naverShoppingClient.searchLowestPrice(ingredientName)
                .map(LowestPriceResponse::from)
                .orElseGet(LowestPriceResponse::notFound);
    }
}

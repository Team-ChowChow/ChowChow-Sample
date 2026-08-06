package com.petdiet.coin.dto;

import java.util.List;

public record ShopCatalogResponse(
        int balance,
        List<ShopItemResponse> items
) {
}

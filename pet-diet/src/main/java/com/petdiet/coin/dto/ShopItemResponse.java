package com.petdiet.coin.dto;

import com.petdiet.coin.shop.ShopCatalog;

public record ShopItemResponse(
        String itemKey,
        String name,
        String description,
        String itemType,
        int price,
        String emoji,
        boolean featured,
        boolean owned,
        boolean equipped
) {
    public static ShopItemResponse from(
            ShopCatalog.Item item,
            boolean owned,
            boolean equipped) {
        return new ShopItemResponse(
                item.itemKey(),
                item.name(),
                item.description(),
                item.itemType(),
                item.price(),
                item.emoji(),
                item.featured(),
                owned,
                equipped
        );
    }
}

package com.petdiet.coin.shop;

import org.junit.jupiter.api.Test;

import java.util.HashSet;

import static org.junit.jupiter.api.Assertions.*;

class ShopCatalogTest {

    @Test
    void catalogKeysAreUniqueAndPricesAreValid() {
        var keys = new HashSet<String>();

        for (ShopCatalog.Item item : ShopCatalog.items()) {
            assertTrue(keys.add(item.itemKey()), "중복 itemKey: " + item.itemKey());
            assertTrue(item.price() >= 0, "가격은 음수일 수 없습니다.");
            assertTrue(
                    ShopCatalog.ROOM_BACKGROUND.equals(item.itemType())
                            || ShopCatalog.ROOM_DECOR.equals(item.itemType())
                            || ShopCatalog.PROFILE_FRAME.equals(item.itemType()),
                    "지원하지 않는 itemType: " + item.itemType()
            );
        }
    }

    @Test
    void unknownItemIsRejected() {
        assertThrows(IllegalArgumentException.class, () -> ShopCatalog.require("unknown_item"));
    }
}

package com.petdiet.coin.shop;

import java.util.List;

public final class ShopCatalog {

    public static final String ROOM_BACKGROUND = "ROOM_BACKGROUND";
    public static final String ROOM_DECOR = "ROOM_DECOR";
    public static final String PROFILE_FRAME = "PROFILE_FRAME";

    public static final String DEFAULT_BACKGROUND = "room_sunrise";
    public static final String DEFAULT_PROFILE_FRAME = "frame_orange";

    private static final List<Item> ITEMS = List.of(
            new Item(DEFAULT_BACKGROUND, "햇살 가득한 방", "따뜻한 크림색 기본 방", ROOM_BACKGROUND, 0, "🏡", true),
            new Item("room_sky", "구름 창가", "파란 하늘이 보이는 산뜻한 방", ROOM_BACKGROUND, 80, "🪟", false),
            new Item("room_forest", "초록 정원", "식물과 햇살이 가득한 포근한 방", ROOM_BACKGROUND, 150, "🌿", true),
            new Item("room_night", "별빛 캠핑", "별이 반짝이는 차분한 밤의 방", ROOM_BACKGROUND, 240, "🌙", false),
            new Item("decor_plant", "몬스테라 화분", "방 한쪽을 채우는 싱그러운 화분", ROOM_DECOR, 90, "🪴", true),
            new Item("decor_lamp", "포근한 스탠드", "은은한 빛의 플로어 스탠드", ROOM_DECOR, 120, "💡", false),
            new Item("decor_cushion", "말랑 쿠션", "캐릭터가 좋아하는 푹신한 쿠션", ROOM_DECOR, 70, "🧸", false),
            new Item(DEFAULT_PROFILE_FRAME, "오렌지 링", "기본 프로필 테두리", PROFILE_FRAME, 0, "🧡", false),
            new Item("frame_mint", "민트 리프", "상쾌한 민트색 프로필 테두리", PROFILE_FRAME, 100, "🍃", true),
            new Item("frame_royal", "로열 골드", "반짝이는 골드 프로필 테두리", PROFILE_FRAME, 220, "👑", false)
    );

    private ShopCatalog() {
    }

    public static List<Item> items() {
        return ITEMS;
    }

    public static Item require(String itemKey) {
        return ITEMS.stream()
                .filter(item -> item.itemKey().equals(itemKey))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 상점 아이템입니다."));
    }

    public static boolean isExclusive(String itemType) {
        return ROOM_BACKGROUND.equals(itemType) || PROFILE_FRAME.equals(itemType);
    }

    public record Item(
            String itemKey,
            String name,
            String description,
            String itemType,
            int price,
            String emoji,
            boolean featured
    ) {
    }
}

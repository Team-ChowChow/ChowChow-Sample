-- 코인 상점 구매 내역 및 장착 상태
CREATE TABLE IF NOT EXISTS "UserShopItems" (
    "userShopItemId" BIGSERIAL PRIMARY KEY,
    "userId"         INTEGER NOT NULL REFERENCES "Users"("userId") ON DELETE CASCADE,
    "itemKey"        VARCHAR(60) NOT NULL,
    "itemType"       VARCHAR(30) NOT NULL,
    "isEquipped"     BOOLEAN NOT NULL DEFAULT FALSE,
    "purchasedAt"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "equippedAt"     TIMESTAMPTZ,
    CONSTRAINT "uk_user_shop_item" UNIQUE ("userId", "itemKey")
);

CREATE INDEX IF NOT EXISTS "idx_user_shop_items_user_type"
    ON "UserShopItems" ("userId", "itemType");

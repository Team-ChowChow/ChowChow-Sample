ALTER TABLE "Breeds" ADD COLUMN IF NOT EXISTS "breedNameKo" VARCHAR(100);

-- 코인 시스템
CREATE TABLE IF NOT EXISTS "UserCoins" (
    "coinId"             SERIAL PRIMARY KEY,
    "userId"             INTEGER NOT NULL UNIQUE REFERENCES "Users"("userId") ON DELETE CASCADE,
    "balance"            INTEGER NOT NULL DEFAULT 0,
    "lastDailyLoginDate" DATE,
    "lastLlmGenerateDate" DATE,
    "updatedAt"          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "CoinLogs" (
    "logId"        BIGSERIAL PRIMARY KEY,
    "userId"       INTEGER NOT NULL REFERENCES "Users"("userId") ON DELETE CASCADE,
    "amount"       INTEGER NOT NULL,
    "reason"       VARCHAR(100) NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "createdAt"    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

-- GPS 산책 기록 및 일일 거리 로드맵 보상
CREATE TABLE IF NOT EXISTS "WalkRecords" (
    "walkId"          BIGSERIAL PRIMARY KEY,
    "userId"          INTEGER NOT NULL REFERENCES "Users"("userId") ON DELETE CASCADE,
    "sessionId"       VARCHAR(80) NOT NULL,
    "walkDate"        DATE NOT NULL,
    "distanceMeters"  INTEGER NOT NULL CHECK ("distanceMeters" >= 0),
    "durationSeconds" INTEGER NOT NULL CHECK ("durationSeconds" > 0),
    "rewardCoins"     INTEGER NOT NULL DEFAULT 0 CHECK ("rewardCoins" >= 0),
    "startedAt"       TIMESTAMPTZ NOT NULL,
    "endedAt"         TIMESTAMPTZ NOT NULL,
    "createdAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT "uk_walk_user_session" UNIQUE ("userId", "sessionId")
);

CREATE INDEX IF NOT EXISTS "idx_walk_records_user_date"
    ON "WalkRecords" ("userId", "walkDate");

CREATE INDEX IF NOT EXISTS "idx_walk_records_user_started"
    ON "WalkRecords" ("userId", "startedAt" DESC);

-- 어드민 시드 레시피는 특정 유저/펫 없이 삽입 가능하도록 nullable 허용
ALTER TABLE "Recipes" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "Recipes" ALTER COLUMN "petId" DROP NOT NULL;

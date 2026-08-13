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

-- 식단 기록에 실제 급여량/레시피 연결 (조리 완료 여부만이 아닌 급여 기록으로 확장)
ALTER TABLE "MealRecords" ADD COLUMN IF NOT EXISTS "feedingAmountG" NUMERIC(6,2);
ALTER TABLE "MealRecords" ADD COLUMN IF NOT EXISTS "recipeId" INTEGER REFERENCES "Recipes"("recipeId") ON DELETE SET NULL;

-- BCS(체형 점수)/운동량 — DTO에는 있었지만 컬럼이 없어 항상 null로 응답되던 것을 실제 저장하도록 보강
-- (엔티티 필드가 Integer라 컬럼도 INTEGER로 맞춰야 Hibernate 스키마 검증을 통과함)
ALTER TABLE "UserPets" ADD COLUMN IF NOT EXISTS "petBodyConditionScore" INTEGER CHECK ("petBodyConditionScore" BETWEEN 1 AND 9);
ALTER TABLE "UserPets" ADD COLUMN IF NOT EXISTS "petBodyScoreDate" DATE;
ALTER TABLE "UserPets" ADD COLUMN IF NOT EXISTS "petActivityLevel" INTEGER;

-- 관심 건강 부위 (최대 3개, 콤마 구분 문자열로 저장)
ALTER TABLE "UserPets" ADD COLUMN IF NOT EXISTS "petHealthFocusAreas" TEXT;

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

-- 어드민 시드 레시피는 특정 유저/펫 없이 삽입 가능하도록 nullable 허용
ALTER TABLE "Recipes" ALTER COLUMN "userId" DROP NOT NULL;
ALTER TABLE "Recipes" ALTER COLUMN "petId" DROP NOT NULL;

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

-- 캐릭터 키우기 확장: 스탯·설명·활동 타입
ALTER TABLE "PetCharacters"
    ADD COLUMN IF NOT EXISTS "health"     INT NOT NULL DEFAULT 80,
    ADD COLUMN IF NOT EXISTS "happiness"  INT NOT NULL DEFAULT 80,
    ADD COLUMN IF NOT EXISTS "hunger"      INT NOT NULL DEFAULT 50,
    ADD COLUMN IF NOT EXISTS "description" TEXT NULL;

ALTER TABLE "CharacterGrowthLogs" DROP CONSTRAINT IF EXISTS "CharacterGrowthLogs_activityType_check";

ALTER TABLE "CharacterGrowthLogs"
    ADD CONSTRAINT "CharacterGrowthLogs_activityType_check"
        CHECK ("activityType" IN (
            'FEED', 'PET', 'EXERCISE', 'BATH', 'LEVEL_UP',
            'RECIPE_USE', 'COMMUNITY_POST', 'COMMENT', 'FEEDING'
        ));

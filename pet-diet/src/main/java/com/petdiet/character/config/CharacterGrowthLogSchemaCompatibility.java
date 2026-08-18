package com.petdiet.character.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Keeps CharacterGrowthLogs inserts compatible with older deployed backends.
 *
 * <p>The live database contains snapshot columns that were added as NOT NULL,
 * but older application versions do not include them in INSERT statements.
 * Database defaults allow both versions to save activity logs safely while
 * deployments are being coordinated.</p>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class CharacterGrowthLogSchemaCompatibility {

    private final JdbcTemplate jdbcTemplate;

    @EventListener(ApplicationReadyEvent.class)
    public void ensureLegacyInsertDefaults() {
        jdbcTemplate.execute("""
                ALTER TABLE "CharacterGrowthLogs"
                    ALTER COLUMN "currentExp" SET DEFAULT 0,
                    ALTER COLUMN "currentLevel" SET DEFAULT 1,
                    ALTER COLUMN "expGained" SET DEFAULT 0
                """);
        jdbcTemplate.execute("""
                ALTER TABLE "CharacterGrowthLogs"
                    DROP CONSTRAINT IF EXISTS "CharacterGrowthLogs_activityType_check"
                """);
        jdbcTemplate.execute("""
                ALTER TABLE "CharacterGrowthLogs"
                    ADD CONSTRAINT "CharacterGrowthLogs_activityType_check"
                    CHECK ("activityType" IN (
                        'FEED', 'PET', 'EXERCISE', 'BATH', 'LEVEL_UP',
                        'RECIPE_USE', 'COMMUNITY_POST', 'COMMENT', 'FEEDING'
                    ))
                """);
        log.info("CharacterGrowthLogs legacy INSERT defaults and activity types are configured");
    }
}

package com.petdiet.character.dto;

import com.petdiet.character.entity.CharacterGrowthLog;
import com.petdiet.character.service.RaisingActivity;
import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;

@Getter
@Builder
public class GrowthLogResponse {
    private Integer growthLogId;
    private String activityType;
    private String activityLabel;
    private String growthType;
    private Integer expGained;
    private Integer growthValue;
    private Integer currentExp;
    private Integer currentLevel;
    private String description;
    private String statusChanges;
    private Boolean levelUp;
    private Integer previousLevel;
    private Integer newLevel;
    private OffsetDateTime createdAt;

    public static GrowthLogResponse from(CharacterGrowthLog log) {
        String type = log.getActivityType();
        String label = activityLabel(type);
        boolean levelUp = "LEVEL_UP".equals(type);
        return GrowthLogResponse.builder()
                .growthLogId(log.getGrowthLogId())
                .activityType(type)
                .activityLabel(label)
                .growthType(type)
                .expGained(log.getExpAmount())
                .growthValue(log.getExpAmount())
                .currentExp(null)
                .currentLevel(null)
                .description(log.getActivityDescription())
                .statusChanges(log.getActivityDescription())
                .levelUp(levelUp)
                .previousLevel(levelUp ? parseLevelFromDescription(log.getActivityDescription(), true) : null)
                .newLevel(levelUp ? parseLevelFromDescription(log.getActivityDescription(), false) : null)
                .createdAt(log.getCreatedAt())
                .build();
    }

    private static String activityLabel(String type) {
        if (type == null) return "";
        try {
            return RaisingActivity.valueOf(type).getLabel();
        } catch (IllegalArgumentException e) {
            return switch (type) {
                case "LEVEL_UP" -> "레벨업";
                case "RECIPE_USE" -> "식단 추천";
                case "COMMUNITY_POST" -> "게시글 작성";
                case "COMMENT" -> "댓글 작성";
                case "FEEDING" -> "식단 기록";
                default -> type;
            };
        }
    }

    private static Integer parseLevelFromDescription(String desc, boolean previous) {
        if (desc == null || !desc.contains("->")) return null;
        try {
            String part = previous ? desc.split("->")[0].trim() : desc.split("->")[1].trim();
            return Integer.parseInt(part.replaceAll("[^0-9]", ""));
        } catch (Exception e) {
            return null;
        }
    }
}

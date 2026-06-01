package com.petdiet.character.service;

import lombok.Getter;

import java.util.Map;

@Getter
public enum RaisingActivity {
    FEED("밥주기", 20, Map.of("hunger", -30, "happiness", 5)),
    PET("쓰다듬기", 5, Map.of("happiness", 15)),
    EXERCISE("운동하기", 10, Map.of("health", 10, "hunger", 5)),
    BATH("목욕시키기", 15, Map.of("health", 10, "happiness", -5));

    private final String label;
    private final int expGain;
    private final Map<String, Integer> statDeltas;

    RaisingActivity(String label, int expGain, Map<String, Integer> statDeltas) {
        this.label = label;
        this.expGain = expGain;
        this.statDeltas = statDeltas;
    }

    public static RaisingActivity from(String type) {
        if (type == null || type.isBlank()) {
            throw new IllegalArgumentException("activityType이 필요합니다.");
        }
        return RaisingActivity.valueOf(type.trim().toUpperCase());
    }
}

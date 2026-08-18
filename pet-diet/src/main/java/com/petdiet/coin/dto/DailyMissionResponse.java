package com.petdiet.coin.dto;

public record DailyMissionResponse(
        String key,
        String label,
        int progress,
        int target,
        int rewardCoins,
        boolean completed,
        boolean claimed
) {
}

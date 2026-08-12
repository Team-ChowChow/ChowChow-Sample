package com.petdiet.walk.dto;

import com.petdiet.walk.entity.WalkRecord;

public record WalkRecordResponse(
        Long walkId,
        String sessionId,
        int distanceMeters,
        int durationSeconds,
        double averageSpeedKmh,
        int rewardCoins,
        String startedAt,
        String endedAt
) {
    public static WalkRecordResponse from(WalkRecord record) {
        double averageSpeed = record.getDurationSeconds() == 0
                ? 0
                : record.getDistanceMeters() * 3.6 / record.getDurationSeconds();
        return new WalkRecordResponse(
                record.getWalkId(),
                record.getSessionId(),
                record.getDistanceMeters(),
                record.getDurationSeconds(),
                Math.round(averageSpeed * 100.0) / 100.0,
                record.getRewardCoins(),
                record.getStartedAt().toString(),
                record.getEndedAt().toString()
        );
    }
}

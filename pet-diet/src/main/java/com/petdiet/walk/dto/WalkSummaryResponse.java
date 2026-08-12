package com.petdiet.walk.dto;

import com.petdiet.walk.reward.WalkRewardRoadmap;

import java.time.LocalDate;
import java.util.List;

public record WalkSummaryResponse(
        String date,
        int todayDistanceMeters,
        int todayRewardCoins,
        int balance,
        List<MilestoneResponse> milestones
) {
    public static WalkSummaryResponse of(LocalDate date, int distanceMeters, int balance) {
        List<MilestoneResponse> milestones = WalkRewardRoadmap.milestones().stream()
                .map(milestone -> new MilestoneResponse(
                        milestone.targetMeters(),
                        milestone.rewardCoins(),
                        distanceMeters >= milestone.targetMeters()
                ))
                .toList();
        return new WalkSummaryResponse(
                date.toString(),
                distanceMeters,
                WalkRewardRoadmap.totalRewardAt(distanceMeters),
                balance,
                milestones
        );
    }

    public record MilestoneResponse(
            int targetMeters,
            int rewardCoins,
            boolean achieved
    ) {
    }
}

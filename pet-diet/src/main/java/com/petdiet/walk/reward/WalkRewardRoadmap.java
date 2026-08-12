package com.petdiet.walk.reward;

import java.util.List;

public final class WalkRewardRoadmap {

    private WalkRewardRoadmap() {
    }

    private static final List<Milestone> MILESTONES = List.of(
            new Milestone(500, 5),
            new Milestone(1_000, 5),
            new Milestone(2_000, 10),
            new Milestone(3_000, 10),
            new Milestone(5_000, 20)
    );

    public static List<Milestone> milestones() {
        return MILESTONES;
    }

    public static int totalRewardAt(int distanceMeters) {
        return MILESTONES.stream()
                .filter(milestone -> distanceMeters >= milestone.targetMeters())
                .mapToInt(Milestone::rewardCoins)
                .sum();
    }

    public static int rewardBetween(int previousDistanceMeters, int newDistanceMeters) {
        return totalRewardAt(newDistanceMeters) - totalRewardAt(previousDistanceMeters);
    }

    public record Milestone(int targetMeters, int rewardCoins) {
    }
}

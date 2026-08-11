package com.petdiet.walk.reward;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class WalkRewardRoadmapTest {

    @Test
    void rewardsOnlyNewlyCrossedMilestones() {
        assertEquals(0, WalkRewardRoadmap.rewardBetween(0, 499));
        assertEquals(5, WalkRewardRoadmap.rewardBetween(400, 500));
        assertEquals(10, WalkRewardRoadmap.rewardBetween(400, 1_500));
        assertEquals(30, WalkRewardRoadmap.rewardBetween(0, 3_000));
        assertEquals(20, WalkRewardRoadmap.rewardBetween(3_000, 6_000));
    }

    @Test
    void dailyRewardIsCappedAtFiftyCoins() {
        assertEquals(50, WalkRewardRoadmap.totalRewardAt(5_000));
        assertEquals(50, WalkRewardRoadmap.totalRewardAt(20_000));
    }
}

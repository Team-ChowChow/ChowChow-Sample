package com.petdiet.walk.dto;

public record WalkFinishResponse(
        WalkRecordResponse walk,
        WalkSummaryResponse today,
        int earnedCoins
) {
}

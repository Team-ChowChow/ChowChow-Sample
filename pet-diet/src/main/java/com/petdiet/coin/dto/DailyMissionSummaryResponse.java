package com.petdiet.coin.dto;

import java.time.LocalDate;
import java.util.List;

public record DailyMissionSummaryResponse(
        LocalDate date,
        int balance,
        List<DailyMissionResponse> missions
) {
}

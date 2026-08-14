package com.petdiet.pet.dto;

import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@Builder
public class FeedingGuidelineResponse {
    private BigDecimal petWeightKg;
    private String ageCategory;
    private BigDecimal activityFactor;
    private BigDecimal restingEnergyKcal;
    private BigDecimal dailyEnergyKcal;
    private BigDecimal recommendedGrams;
    private String status;
    private String message;
}

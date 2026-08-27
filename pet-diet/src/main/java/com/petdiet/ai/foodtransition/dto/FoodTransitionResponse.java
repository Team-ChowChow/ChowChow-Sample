package com.petdiet.ai.foodtransition.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FoodTransitionResponse {
    private String summary;
    private Integer totalDays;
    private List<FoodTransitionStepDto> schedule;
    private List<String> warnings;
}

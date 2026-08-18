package com.petdiet.ai.foodtransition.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class FoodTransitionResponse {
    private String summary;
    private Integer totalDays;
    private List<FoodTransitionStepDto> schedule;
    private List<String> warnings;
}

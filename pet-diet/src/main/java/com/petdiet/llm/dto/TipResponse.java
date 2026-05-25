package com.petdiet.llm.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TipResponse {
    private String tip;
    private String detail;
}

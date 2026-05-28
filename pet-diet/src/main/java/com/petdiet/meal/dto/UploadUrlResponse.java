package com.petdiet.meal.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UploadUrlResponse {
    private String uploadUrl;
    private String publicUrl;
}

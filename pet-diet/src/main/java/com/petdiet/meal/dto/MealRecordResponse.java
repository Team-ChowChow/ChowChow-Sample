package com.petdiet.meal.dto;

import com.petdiet.meal.entity.MealRecord;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class MealRecordResponse {
    private Integer mealId;
    private Integer petId;
    private String petName;
    private String mealTitle;
    private String mealNote;
    private String imageUrl;
    private String mealDate;
    private String createdAt;

    public static MealRecordResponse from(MealRecord r) {
        return MealRecordResponse.builder()
                .mealId(r.getMealId())
                .petId(r.getPet() != null ? r.getPet().getPetId() : null)
                .petName(r.getPet() != null ? r.getPet().getPetName() : null)
                .mealTitle(r.getMealTitle())
                .mealNote(r.getMealNote())
                .imageUrl(r.getImageUrl())
                .mealDate(r.getMealDate())
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                .build();
    }
}

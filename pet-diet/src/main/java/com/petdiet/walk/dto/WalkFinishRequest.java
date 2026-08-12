package com.petdiet.walk.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.time.OffsetDateTime;

public record WalkFinishRequest(
        @NotBlank String sessionId,
        @NotNull @PositiveOrZero Integer distanceMeters,
        @NotNull @Positive Integer durationSeconds,
        @NotNull OffsetDateTime startedAt,
        @NotNull OffsetDateTime endedAt
) {
}

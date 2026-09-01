package com.petdiet.user.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.domain.Page;

import java.util.List;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FollowPageResponse {
    private List<UserFollowResponse> content;

    @JsonProperty("totalElements")
    private long totalElements;

    @JsonProperty("number")
    private int number;

    @JsonProperty("last")
    private boolean last;

    public static FollowPageResponse from(Page<UserFollowResponse> page) {
        return FollowPageResponse.builder()
                .content(page.getContent())
                .totalElements(page.getTotalElements())
                .number(page.getNumber())
                .last(page.isLast())
                .build();
    }
}

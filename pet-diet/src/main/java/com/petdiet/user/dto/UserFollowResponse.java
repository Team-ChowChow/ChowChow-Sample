package com.petdiet.user.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.petdiet.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserFollowResponse {
    @JsonProperty("userId")
    private Integer userId;

    @JsonProperty("userName")
    private String userName;

    @JsonProperty("userNickname")
    private String userNickname;

    @JsonProperty("userProfileImg")
    private String userProfileImg;

    @JsonProperty("isFollowing")
    private Boolean isFollowing;

    public static UserFollowResponse from(User user, boolean isFollowing) {
        return UserFollowResponse.builder()
                .userId(user.getUserId())
                .userName(user.getUserName())
                .userNickname(user.getUserNickname())
                .userProfileImg(user.getUserProfileImg())
                .isFollowing(isFollowing)
                .build();
    }
}

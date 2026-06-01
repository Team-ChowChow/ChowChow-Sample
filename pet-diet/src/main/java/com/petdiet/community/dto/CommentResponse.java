package com.petdiet.community.dto;

import com.petdiet.community.entity.CommunityComment;
import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;

@Getter
@Builder
public class CommentResponse {
    private Integer commentId;
    private Integer postId;
    private Integer userId;
    private String userNickname;
    private Integer parentCommentId;
    private String commentContent;
    private String commentStatus;
    private Boolean isMine;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public static CommentResponse from(CommunityComment comment, boolean isMine) {
        return CommentResponse.builder()
                .commentId(comment.getCommentId())
                .postId(comment.getPost().getPostId())
                .userId(comment.getUser().getUserId())
                .userNickname(comment.getUser().getUserNickname())
                .parentCommentId(comment.getParentCommentId())
                .commentContent(comment.getCommentContent())
                .commentStatus(comment.getCommentStatus())
                .isMine(isMine)
                .createdAt(comment.getCreatedAt())
                .updatedAt(comment.getUpdatedAt())
                .build();
    }
}

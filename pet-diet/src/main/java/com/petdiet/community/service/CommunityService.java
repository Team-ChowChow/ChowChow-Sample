package com.petdiet.community.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.community.dto.CommentRequest;
import com.petdiet.community.dto.CommentResponse;
import com.petdiet.community.dto.PostRequest;
import com.petdiet.community.dto.PostResponse;
import com.petdiet.community.entity.CommunityComment;
import com.petdiet.community.entity.CommunityLike;
import com.petdiet.community.entity.CommunityPost;
import com.petdiet.community.repository.CommunityCommentRepository;
import com.petdiet.community.repository.CommunityLikeRepository;
import com.petdiet.community.repository.CommunityPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CommunityService {

    private final CommunityPostRepository postRepository;
    private final CommunityCommentRepository commentRepository;
    private final CommunityLikeRepository likeRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public Page<PostResponse> getPosts(String category, Pageable pageable) {
        Page<CommunityPost> posts = (category == null || category.isBlank())
                ? postRepository.findAllByPostStatus("ACTIVE", pageable)
                : postRepository.findAllByPostCategoryAndPostStatus(category, "ACTIVE", pageable);

        return posts.map(post -> PostResponse.from(post, post.getLikeCount(), false));
    }

    @Transactional
    public PostResponse getPost(Integer postId) {
        CommunityPost post = postRepository.findByPostIdAndPostStatus(postId, "ACTIVE")
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        post.incrementViewCount();
        return PostResponse.from(post, post.getLikeCount(), false);
    }

    @Transactional(readOnly = true)
    public Page<PostResponse> getMyPosts(UUID authUuid, Pageable pageable) {
        User user = getUser(authUuid);
        return postRepository.findAllByUserAndPostStatus(user, "ACTIVE", pageable)
                .map(post -> PostResponse.from(post, post.getLikeCount(), false));
    }

    @Transactional
    public PostResponse createPost(UUID authUuid, PostRequest req) {
        User user = getUser(authUuid);
        CommunityPost post = CommunityPost.builder()
                .user(user)
                .petId(req.getPetId())
                .recipeId(req.getRecipeId())
                .postTitle(req.getPostTitle())
                .postContent(req.getPostContent())
                .postImageUrl(req.getPostImageUrl())
                .postCategory(req.getPostCategory())
                .build();
        postRepository.save(post);
        return PostResponse.from(post, 0, false);
    }

    @Transactional
    public PostResponse updatePost(UUID authUuid, Integer postId, PostRequest req) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        if (!post.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("수정 권한이 없습니다.");
        }
        post.update(req.getPostTitle(), req.getPostContent(), req.getPostImageUrl(), req.getPostCategory());
        return PostResponse.from(post, post.getLikeCount(), false);
    }

    @Transactional
    public void deletePost(UUID authUuid, Integer postId) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        if (!post.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("삭제 권한이 없습니다.");
        }
        post.delete();
    }

    @Transactional
    public void toggleLike(UUID authUuid, Integer postId) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        likeRepository.findByPostAndUser(post, user).ifPresentOrElse(
                like -> {
                    likeRepository.delete(like);
                    post.decrementLikeCount();
                },
                () -> {
                    likeRepository.save(CommunityLike.builder().post(post).user(user).build());
                    post.incrementLikeCount();
                }
        );
    }

    @Transactional(readOnly = true)
    public List<CommentResponse> getComments(Integer postId) {
        CommunityPost post = getActivePost(postId);
        return commentRepository.findAllByPostAndCommentStatus(post, "ACTIVE").stream()
                .map(c -> CommentResponse.from(c, false))
                .toList();
    }

    @Transactional
    public CommentResponse createComment(UUID authUuid, Integer postId, CommentRequest req) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        CommunityComment comment = CommunityComment.builder()
                .post(post)
                .user(user)
                .parentCommentId(req.getParentCommentId())
                .commentContent(req.getCommentContent())
                .build();
        commentRepository.save(comment);
        post.incrementCommentCount();
        return CommentResponse.from(comment, true);
    }

    @Transactional
    public CommentResponse updateComment(UUID authUuid, Integer postId, Integer commentId, CommentRequest req) {
        return updateComment(authUuid, commentId, req);
    }

    @Transactional
    public CommentResponse updateComment(UUID authUuid, Integer commentId, CommentRequest req) {
        User user = getUser(authUuid);
        CommunityComment comment = getActiveComment(commentId);
        if (!comment.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("수정 권한이 없습니다.");
        }
        comment.update(req.getCommentContent());
        return CommentResponse.from(comment, true);
    }

    @Transactional
    public void deleteComment(UUID authUuid, Integer postId, Integer commentId) {
        deleteComment(authUuid, commentId);
    }

    @Transactional
    public void deleteComment(UUID authUuid, Integer commentId) {
        User user = getUser(authUuid);
        CommunityComment comment = getActiveComment(commentId);
        if (!comment.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("삭제 권한이 없습니다.");
        }
        comment.delete();
        comment.getPost().decrementCommentCount();
    }

    private User getUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }

    private CommunityPost getActivePost(Integer postId) {
        return postRepository.findByPostIdAndPostStatus(postId, "ACTIVE")
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
    }

    private CommunityComment getActiveComment(Integer commentId) {
        return commentRepository.findByCommentIdAndCommentStatus(commentId, "ACTIVE")
                .orElseThrow(() -> new IllegalArgumentException("댓글을 찾을 수 없습니다."));
    }
}

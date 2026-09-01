package com.petdiet.community.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.service.CoinService;
import com.petdiet.community.dto.CommentRequest;
import com.petdiet.community.dto.CommentResponse;
import com.petdiet.community.dto.PostRequest;
import com.petdiet.community.dto.PostResponse;
import com.petdiet.community.entity.CommunityComment;
import com.petdiet.community.entity.CommunityLike;
import com.petdiet.community.entity.CommunityPost;
import com.petdiet.community.entity.CommunityPostBookmark;
import com.petdiet.community.repository.CommunityCommentRepository;
import com.petdiet.community.repository.CommunityLikeRepository;
import com.petdiet.community.repository.CommunityPostBookmarkRepository;
import com.petdiet.community.repository.CommunityPostRepository;
import com.petdiet.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CommunityService {

    private final CommunityPostRepository postRepository;
    private final CommunityCommentRepository commentRepository;
    private final CommunityLikeRepository likeRepository;
    private final CommunityPostBookmarkRepository bookmarkRepository;
    private final UserRepository userRepository;
    private final CoinService coinService;
    private final NotificationService notificationService;

    @Transactional(readOnly = true)
    public Page<PostResponse> getPosts(UUID authUuid, String category, String petType, Pageable pageable) {
        User user = getUser(authUuid);
        boolean hasCategory = category != null && !category.isBlank();
        boolean hasPetType = petType != null && !petType.isBlank();

        Page<CommunityPost> posts;
        if (hasCategory && hasPetType) {
            posts = postRepository.findAllByPostCategoryAndPetTypeAndPostStatus(category, petType, "ACTIVE", pageable);
        } else if (hasCategory) {
            posts = postRepository.findAllByPostCategoryAndPostStatus(category, "ACTIVE", pageable);
        } else if (hasPetType) {
            posts = postRepository.findAllByPetTypeAndPostStatus(petType, "ACTIVE", pageable);
        } else {
            posts = postRepository.findAllByPostStatus("ACTIVE", pageable);
        }

        return posts.map(post -> PostResponse.from(post, post.getLikeCount(),
                likeRepository.existsByPostAndUser(post, user), bookmarkRepository.existsByPostAndUser(post, user)));
    }

    @Transactional
    public PostResponse getPost(UUID authUuid, Integer postId) {
        User user = getUser(authUuid);
        CommunityPost post = postRepository.findByPostIdAndPostStatus(postId, "ACTIVE")
                .orElseThrow(() -> new IllegalArgumentException("게시글을 찾을 수 없습니다."));
        post.incrementViewCount();
        return PostResponse.from(post, post.getLikeCount(),
                likeRepository.existsByPostAndUser(post, user), bookmarkRepository.existsByPostAndUser(post, user));
    }

    @Transactional(readOnly = true)
    public Page<PostResponse> getMyPosts(UUID authUuid, Pageable pageable) {
        User user = getUser(authUuid);
        return postRepository.findAllByUserAndPostStatus(user, "ACTIVE", pageable)
                .map(post -> PostResponse.from(post, post.getLikeCount(),
                        likeRepository.existsByPostAndUser(post, user), bookmarkRepository.existsByPostAndUser(post, user)));
    }

    @Transactional
    public Map<String, Object> toggleBookmark(UUID authUuid, Integer postId) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        boolean nowBookmarked;
        var existing = bookmarkRepository.findByPostAndUser(post, user);
        if (existing.isPresent()) {
            bookmarkRepository.delete(existing.get());
            nowBookmarked = false;
        } else {
            bookmarkRepository.save(CommunityPostBookmark.builder().post(post).user(user).build());
            nowBookmarked = true;
        }
        return Map.of("postId", postId, "bookmarked", nowBookmarked);
    }

    @Transactional(readOnly = true)
    public List<PostResponse> getBookmarkedPosts(UUID authUuid) {
        User user = getUser(authUuid);
        return bookmarkRepository.findAllByUserOrderByCreatedAtDesc(user).stream()
                .map(bm -> {
                    CommunityPost post = bm.getPost();
                    return PostResponse.from(post, post.getLikeCount(),
                            likeRepository.existsByPostAndUser(post, user), true);
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PostResponse> getLikedPosts(UUID authUuid) {
        User user = getUser(authUuid);
        return likeRepository
                .findAllByUserAndPost_PostStatusOrderByCreatedAtDesc(user, "ACTIVE")
                .stream()
                .map(like -> {
                    CommunityPost post = like.getPost();
                    return PostResponse.from(post, post.getLikeCount(), true);
                })
                .toList();
    }

    @Transactional
    public PostResponse createPost(UUID authUuid, PostRequest req) {
        User user = getUser(authUuid);
        CommunityPost post = CommunityPost.builder()
                .user(user)
                .petId(req.getPetId())
                .recipeId(req.getRecipeId())
                .petType(req.getPetType())
                .postTitle(req.getPostTitle())
                .postContent(req.getPostContent())
                .postImageUrl(req.getPostImageUrl())
                .postCategory(req.getPostCategory())
                .build();
        postRepository.save(post);
        coinService.earnCoinsOnce(
                authUuid,
                CoinService.COMMUNITY_POST_REWARD,
                "커뮤니티 글쓰기 #" + post.getPostId());
        return PostResponse.from(post, 0, false);
    }

    @Transactional
    public PostResponse updatePost(UUID authUuid, Integer postId, PostRequest req) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        if (!post.getUser().getUserId().equals(user.getUserId())) {
            throw new IllegalArgumentException("수정 권한이 없습니다.");
        }
        post.update(req.getPostTitle(), req.getPostContent(), req.getPostImageUrl(),
                req.getPostCategory(), req.getPetType());
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
                    coinService.earnCoinsOnce(
                            authUuid,
                            CoinService.COMMUNITY_LIKE_REWARD,
                            "커뮤니티 좋아요 #" + postId);
                    if (!post.getUser().getUserId().equals(user.getUserId())) {
                        notificationService.createNotification(
                                post.getUser(), "LIKE", "새 좋아요",
                                (user.getUserNickname() != null ? user.getUserNickname() : "누군가") + "님이 회원님의 글을 좋아합니다.",
                                "POST", postId, postId);
                    }
                }
        );
    }

    @Transactional(readOnly = true)
    public List<CommentResponse> getComments(UUID authUuid, Integer postId) {
        User user = getUser(authUuid);
        CommunityPost post = getActivePost(postId);
        return commentRepository.findAllByPostAndCommentStatus(post, "ACTIVE").stream()
                .map(c -> CommentResponse.from(c, c.getUser().getUserId().equals(user.getUserId())))
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
        coinService.earnCoinsOnce(
                authUuid,
                CoinService.COMMUNITY_COMMENT_REWARD,
                "커뮤니티 댓글 #" + comment.getCommentId());
        if (!post.getUser().getUserId().equals(user.getUserId())) {
            notificationService.createNotification(
                    post.getUser(), "COMMENT", "새 댓글",
                    (user.getUserNickname() != null ? user.getUserNickname() : "누군가") + "님이 회원님의 글에 댓글을 남겼습니다.",
                    "POST", postId, comment.getCommentId());
        }
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

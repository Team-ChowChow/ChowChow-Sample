package com.petdiet.community.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.service.CoinService;
import com.petdiet.community.entity.CommunityPost;
import com.petdiet.community.repository.CommunityCommentRepository;
import com.petdiet.community.repository.CommunityLikeRepository;
import com.petdiet.community.repository.CommunityPostRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.*;

class CommunityServiceTest {

    @Test
    void firstLikeAwardsCoinsThroughTheDomainTransaction() {
        UUID authUuid = UUID.randomUUID();
        User user = User.builder().userId(1).authUuid(authUuid).build();
        CommunityPost post = CommunityPost.builder()
                .postId(10)
                .user(user)
                .postTitle("title")
                .postContent("content")
                .build();
        CommunityPostRepository postRepository = mock(CommunityPostRepository.class);
        CommunityCommentRepository commentRepository = mock(CommunityCommentRepository.class);
        CommunityLikeRepository likeRepository = mock(CommunityLikeRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        CoinService coinService = mock(CoinService.class);
        CommunityService service = new CommunityService(
                postRepository,
                commentRepository,
                likeRepository,
                userRepository,
                coinService);

        when(userRepository.findByAuthUuid(authUuid)).thenReturn(Optional.of(user));
        when(postRepository.findByPostIdAndPostStatus(10, "ACTIVE"))
                .thenReturn(Optional.of(post));
        when(likeRepository.findByPostAndUser(post, user)).thenReturn(Optional.empty());

        service.toggleLike(authUuid, 10);

        verify(coinService).earnCoinsOnce(
                authUuid,
                CoinService.COMMUNITY_LIKE_REWARD,
                "커뮤니티 좋아요 #10");
    }
}

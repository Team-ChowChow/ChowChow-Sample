package com.petdiet.user.service;

import com.petdiet.auth.entity.User;
import com.petdiet.user.dto.FollowPageResponse;
import com.petdiet.user.dto.UserFollowResponse;
import com.petdiet.user.entity.UserFollow;
import com.petdiet.user.repository.UserFollowRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
@RequiredArgsConstructor
public class FollowService {
    private final UserFollowRepository userFollowRepository;

    // 사용자 팔로우
    public void follow(User follower, User following) {
        if (follower.getUserId().equals(following.getUserId())) {
            throw new IllegalArgumentException("자신을 팔로우할 수 없습니다.");
        }
        if (!userFollowRepository.existsByFollowerAndFollowing(follower, following)) {
            UserFollow userFollow = UserFollow.builder()
                    .follower(follower)
                    .following(following)
                    .build();
            userFollowRepository.save(userFollow);
        }
    }

    // 사용자 언팔로우
    public void unfollow(User follower, User following) {
        userFollowRepository.deleteByFollowerAndFollowing(follower, following);
    }

    // 팔로워 목록 조회
    @Transactional(readOnly = true)
    public FollowPageResponse getFollowers(User currentUser, User targetUser, Pageable pageable) {
        Page<UserFollow> followers = userFollowRepository.findFollowers(targetUser, pageable);
        Page<UserFollowResponse> responses = followers.map(uf -> {
            boolean isFollowing = userFollowRepository.existsByFollowerAndFollowing(currentUser, uf.getFollower());
            return UserFollowResponse.from(uf.getFollower(), isFollowing);
        });
        return FollowPageResponse.from(responses);
    }

    // 팔로잉 목록 조회
    @Transactional(readOnly = true)
    public FollowPageResponse getFollowing(User currentUser, User targetUser, Pageable pageable) {
        Page<UserFollow> following = userFollowRepository.findFollowing(targetUser, pageable);
        Page<UserFollowResponse> responses = following.map(uf -> {
            boolean isFollowing = userFollowRepository.existsByFollowerAndFollowing(currentUser, uf.getFollowing());
            return UserFollowResponse.from(uf.getFollowing(), isFollowing);
        });
        return FollowPageResponse.from(responses);
    }

    // 팔로워 수
    @Transactional(readOnly = true)
    public long getFollowerCount(User user) {
        return userFollowRepository.countByFollowing(user);
    }

    // 팔로잉 수
    @Transactional(readOnly = true)
    public long getFollowingCount(User user) {
        return userFollowRepository.countByFollower(user);
    }

    // 팔로우 여부 확인
    @Transactional(readOnly = true)
    public boolean isFollowing(User follower, User following) {
        return userFollowRepository.existsByFollowerAndFollowing(follower, following);
    }
}

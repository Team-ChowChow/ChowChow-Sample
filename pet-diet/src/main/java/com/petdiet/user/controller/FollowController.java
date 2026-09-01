package com.petdiet.user.controller;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.auth.security.CurrentUser;
import com.petdiet.user.dto.FollowPageResponse;
import com.petdiet.user.service.FollowService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class FollowController {
    private final FollowService followService;
    private final UserRepository userRepository;

    // 팔로우
    @PostMapping("/{userId}/follow")
    public ResponseEntity<Void> follow(
            @CurrentUser User currentUser,
            @PathVariable Integer userId) {
        User targetUser = userRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        followService.follow(currentUser, targetUser);
        return ResponseEntity.ok().build();
    }

    // 언팔로우
    @DeleteMapping("/{userId}/follow")
    public ResponseEntity<Void> unfollow(
            @CurrentUser User currentUser,
            @PathVariable Integer userId) {
        User targetUser = userRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        followService.unfollow(currentUser, targetUser);
        return ResponseEntity.ok().build();
    }

    // 나의 팔로워 목록
    @GetMapping("/me/followers")
    public ResponseEntity<FollowPageResponse> getMyFollowers(
            @CurrentUser User currentUser,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        FollowPageResponse response = followService.getFollowers(currentUser, currentUser, pageable);
        return ResponseEntity.ok(response);
    }

    // 나의 팔로잉 목록
    @GetMapping("/me/following")
    public ResponseEntity<FollowPageResponse> getMyFollowing(
            @CurrentUser User currentUser,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        FollowPageResponse response = followService.getFollowing(currentUser, currentUser, pageable);
        return ResponseEntity.ok(response);
    }

    // 다른 사용자의 팔로워 목록
    @GetMapping("/{userId}/followers")
    public ResponseEntity<FollowPageResponse> getUserFollowers(
            @CurrentUser User currentUser,
            @PathVariable Integer userId,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User targetUser = userRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        FollowPageResponse response = followService.getFollowers(currentUser, targetUser, pageable);
        return ResponseEntity.ok(response);
    }

    // 다른 사용자의 팔로잉 목록
    @GetMapping("/{userId}/following")
    public ResponseEntity<FollowPageResponse> getUserFollowing(
            @CurrentUser User currentUser,
            @PathVariable Integer userId,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User targetUser = userRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        FollowPageResponse response = followService.getFollowing(currentUser, targetUser, pageable);
        return ResponseEntity.ok(response);
    }
}

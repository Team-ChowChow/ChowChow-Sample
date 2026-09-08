package com.petdiet.user.controller;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.config.SupabasePrincipal;
import com.petdiet.user.dto.FollowPageResponse;
import com.petdiet.user.service.FollowService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class FollowController {
    private final FollowService followService;
    private final UserRepository userRepository;

    private User currentUser(SupabasePrincipal principal) {
        return userRepository.findByAuthUuid(principal.authUuid())
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }

    // 팔로우
    @PostMapping("/{userId}/follow")
    public ResponseEntity<Void> follow(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer userId) {
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        followService.follow(currentUser(principal), targetUser);
        return ResponseEntity.ok().build();
    }

    // 언팔로우
    @DeleteMapping("/{userId}/follow")
    public ResponseEntity<Void> unfollow(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer userId) {
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        followService.unfollow(currentUser(principal), targetUser);
        return ResponseEntity.ok().build();
    }

    // 나의 팔로워 목록
    @GetMapping("/me/followers")
    public ResponseEntity<FollowPageResponse> getMyFollowers(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User user = currentUser(principal);
        FollowPageResponse response = followService.getFollowers(user, user, pageable);
        return ResponseEntity.ok(response);
    }

    // 나의 팔로잉 목록
    @GetMapping("/me/following")
    public ResponseEntity<FollowPageResponse> getMyFollowing(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User user = currentUser(principal);
        FollowPageResponse response = followService.getFollowing(user, user, pageable);
        return ResponseEntity.ok(response);
    }

    // 다른 사용자의 팔로워 목록
    @GetMapping("/{userId}/followers")
    public ResponseEntity<FollowPageResponse> getUserFollowers(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer userId,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        FollowPageResponse response = followService.getFollowers(currentUser(principal), targetUser, pageable);
        return ResponseEntity.ok(response);
    }

    // 다른 사용자의 팔로잉 목록
    @GetMapping("/{userId}/following")
    public ResponseEntity<FollowPageResponse> getUserFollowing(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @PathVariable Integer userId,
            @PageableDefault(size = 50, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        FollowPageResponse response = followService.getFollowing(currentUser(principal), targetUser, pageable);
        return ResponseEntity.ok(response);
    }
}

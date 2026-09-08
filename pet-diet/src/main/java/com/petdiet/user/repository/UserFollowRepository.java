package com.petdiet.user.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.user.entity.UserFollow;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UserFollowRepository extends JpaRepository<UserFollow, Long> {

    // 특정 사용자를 팔로우하는지 확인
    boolean existsByFollowerAndFollowing(User follower, User following);

    // 팔로워 목록 조회
    @Query("SELECT uf FROM UserFollow uf WHERE uf.following = :user ORDER BY uf.createdAt DESC")
    Page<UserFollow> findFollowers(@Param("user") User user, Pageable pageable);

    // 팔로잉 목록 조회
    @Query("SELECT uf FROM UserFollow uf WHERE uf.follower = :user ORDER BY uf.createdAt DESC")
    Page<UserFollow> findFollowing(@Param("user") User user, Pageable pageable);

    // 팔로워 수
    long countByFollowing(User user);

    // 팔로잉 수
    long countByFollower(User user);

    // 팔로우 관계 삭제
    void deleteByFollowerAndFollowing(User follower, User following);

    // 팔로우 관계 조회
    Optional<UserFollow> findByFollowerAndFollowing(User follower, User following);
}

package com.petdiet.community.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.community.entity.CommunityPost;
import com.petdiet.community.entity.CommunityPostBookmark;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CommunityPostBookmarkRepository extends JpaRepository<CommunityPostBookmark, Integer> {

    Optional<CommunityPostBookmark> findByPostAndUser(CommunityPost post, User user);

    boolean existsByPostAndUser(CommunityPost post, User user);

    List<CommunityPostBookmark> findAllByUserOrderByCreatedAtDesc(User user);
}

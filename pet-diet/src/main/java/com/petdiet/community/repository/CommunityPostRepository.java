package com.petdiet.community.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.community.entity.CommunityPost;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface CommunityPostRepository extends JpaRepository<CommunityPost, Integer> {

    Page<CommunityPost> findAllByPostStatus(String postStatus, Pageable pageable);

    Page<CommunityPost> findAllByPostCategoryAndPostStatus(String postCategory, String postStatus, Pageable pageable);

    Page<CommunityPost> findAllByPetTypeAndPostStatus(String petType, String postStatus, Pageable pageable);

    Page<CommunityPost> findAllByPostCategoryAndPetTypeAndPostStatus(String postCategory, String petType, String postStatus, Pageable pageable);

    Page<CommunityPost> findAllByUserAndPostStatus(User user, String postStatus, Pageable pageable);

    @Query("SELECT post FROM CommunityPost post " +
            "WHERE post.user IN (" +
            "SELECT follow.following FROM UserFollow follow WHERE follow.follower = :user" +
            ") AND post.postStatus = :postStatus")
    Page<CommunityPost> findFollowingPosts(
            @Param("user") User user,
            @Param("postStatus") String postStatus,
            Pageable pageable);

    Optional<CommunityPost> findByPostIdAndPostStatus(Integer postId, String postStatus);
}

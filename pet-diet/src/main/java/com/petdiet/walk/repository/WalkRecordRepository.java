package com.petdiet.walk.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.walk.entity.WalkRecord;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Optional;

public interface WalkRecordRepository extends JpaRepository<WalkRecord, Long> {

    Optional<WalkRecord> findByUserAndSessionId(User user, String sessionId);

    Page<WalkRecord> findByUserOrderByStartedAtDesc(User user, Pageable pageable);

    @Query("""
            select coalesce(sum(w.distanceMeters), 0)
            from WalkRecord w
            where w.user = :user and w.walkDate = :walkDate
            """)
    Integer sumDistanceByUserAndWalkDate(
            @Param("user") User user,
            @Param("walkDate") LocalDate walkDate
    );
}

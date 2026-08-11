package com.petdiet.walk.entity;

import com.petdiet.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(
        name = "\"WalkRecords\"",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_walk_user_session",
                columnNames = {"\"userId\"", "\"sessionId\""}
        )
)
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WalkRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"walkId\"")
    private Long walkId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false)
    private User user;

    @Column(name = "\"sessionId\"", nullable = false, length = 80)
    private String sessionId;

    @Column(name = "\"walkDate\"", nullable = false)
    private LocalDate walkDate;

    @Column(name = "\"distanceMeters\"", nullable = false)
    private Integer distanceMeters;

    @Column(name = "\"durationSeconds\"", nullable = false)
    private Integer durationSeconds;

    @Builder.Default
    @Column(name = "\"rewardCoins\"", nullable = false)
    private Integer rewardCoins = 0;

    @Column(name = "\"startedAt\"", nullable = false)
    private OffsetDateTime startedAt;

    @Column(name = "\"endedAt\"", nullable = false)
    private OffsetDateTime endedAt;

    @CreationTimestamp
    @Column(name = "\"createdAt\"", nullable = false, updatable = false)
    private OffsetDateTime createdAt;
}

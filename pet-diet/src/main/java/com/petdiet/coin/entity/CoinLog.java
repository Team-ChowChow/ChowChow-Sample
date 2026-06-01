package com.petdiet.coin.entity;

import com.petdiet.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.OffsetDateTime;

@Entity
@Table(name = "\"CoinLogs\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CoinLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"logId\"")
    private Long logId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false)
    private User user;

    @Column(name = "\"amount\"", nullable = false)
    private Integer amount;

    @Column(name = "\"reason\"", nullable = false)
    private String reason;

    @Column(name = "\"balanceAfter\"", nullable = false)
    private Integer balanceAfter;

    @CreationTimestamp
    @Column(name = "\"createdAt\"", nullable = false, updatable = false)
    private OffsetDateTime createdAt;
}

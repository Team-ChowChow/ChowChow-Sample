package com.petdiet.coin.entity;

import com.petdiet.auth.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "\"UserCoins\"")
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserCoin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "\"coinId\"")
    private Integer coinId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "\"userId\"", nullable = false, unique = true)
    private User user;

    @Builder.Default
    @Column(name = "\"balance\"", nullable = false)
    private Integer balance = 0;

    @Column(name = "\"lastDailyLoginDate\"")
    private LocalDate lastDailyLoginDate;

    @Column(name = "\"lastLlmGenerateDate\"")
    private LocalDate lastLlmGenerateDate;

    @UpdateTimestamp
    @Column(name = "\"updatedAt\"", nullable = false)
    private OffsetDateTime updatedAt;

    public void addCoins(int amount) {
        this.balance = this.balance + amount;
    }

    public boolean spendCoins(int amount) {
        if (this.balance < amount) return false;
        this.balance = this.balance - amount;
        return true;
    }

    public boolean canDailyLogin() {
        return lastDailyLoginDate == null || !lastDailyLoginDate.equals(LocalDate.now());
    }

    public boolean canLlmGenerate() {
        return lastLlmGenerateDate == null || !lastLlmGenerateDate.equals(LocalDate.now());
    }

    public void recordDailyLogin() {
        this.lastDailyLoginDate = LocalDate.now();
    }

    public void recordLlmGenerate() {
        this.lastLlmGenerateDate = LocalDate.now();
    }
}

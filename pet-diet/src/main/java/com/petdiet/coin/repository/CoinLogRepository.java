package com.petdiet.coin.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.coin.entity.CoinLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CoinLogRepository extends JpaRepository<CoinLog, Long> {
    Page<CoinLog> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);
}

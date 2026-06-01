package com.petdiet.coin.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.coin.entity.UserCoin;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserCoinRepository extends JpaRepository<UserCoin, Integer> {
    Optional<UserCoin> findByUser(User user);
}

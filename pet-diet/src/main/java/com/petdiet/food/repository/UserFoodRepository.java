package com.petdiet.food.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.food.entity.UserFood;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserFoodRepository extends JpaRepository<UserFood, Integer> {
    List<UserFood> findAllByUserOrderByCreatedAtDesc(User user);
    Optional<UserFood> findByUserFoodIdAndUser(Integer userFoodId, User user);
}

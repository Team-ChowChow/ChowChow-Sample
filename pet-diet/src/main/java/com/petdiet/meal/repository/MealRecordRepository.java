package com.petdiet.meal.repository;

import com.petdiet.auth.entity.User;
import com.petdiet.meal.entity.MealRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface MealRecordRepository extends JpaRepository<MealRecord, Integer> {
    List<MealRecord> findAllByUserOrderByCreatedAtDesc(User user);
    Optional<MealRecord> findByMealIdAndUser(Integer mealId, User user);
}

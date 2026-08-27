package com.petdiet.food.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.food.dto.UserFoodRequest;
import com.petdiet.food.dto.UserFoodResponse;
import com.petdiet.food.entity.UserFood;
import com.petdiet.food.repository.UserFoodRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserFoodService {

    private final UserFoodRepository userFoodRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<UserFoodResponse> getMyFoods(UUID authUuid) {
        User user = findUser(authUuid);
        return userFoodRepository.findAllByUserOrderByCreatedAtDesc(user)
                .stream().map(UserFoodResponse::from).toList();
    }

    @Transactional
    public UserFoodResponse create(UUID authUuid, UserFoodRequest req) {
        User user = findUser(authUuid);
        UserFood food = UserFood.builder()
                .user(user)
                .brandName(req.getBrandName())
                .productName(req.getProductName())
                .petType(req.getPetType())
                .caloriesPer100g(req.getCaloriesPer100g())
                .proteinG(req.getProteinG())
                .fatG(req.getFatG())
                .carbohydrateG(req.getCarbohydrateG())
                .build();
        return UserFoodResponse.from(userFoodRepository.save(food));
    }

    @Transactional
    public void delete(UUID authUuid, Integer userFoodId) {
        User user = findUser(authUuid);
        UserFood food = userFoodRepository.findByUserFoodIdAndUser(userFoodId, user)
                .orElseThrow(() -> new IllegalArgumentException("등록한 사료를 찾을 수 없습니다."));
        userFoodRepository.delete(food);
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }
}

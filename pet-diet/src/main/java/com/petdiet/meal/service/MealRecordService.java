package com.petdiet.meal.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.common.service.SupabaseStorageService;
import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.entity.UserFood;
import com.petdiet.food.repository.CommercialFoodRepository;
import com.petdiet.food.repository.UserFoodRepository;
import com.petdiet.meal.dto.MealRecordRequest;
import com.petdiet.meal.dto.MealRecordResponse;
import com.petdiet.meal.entity.MealRecord;
import com.petdiet.meal.repository.MealRecordRepository;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import com.petdiet.recipe.entity.Recipe;
import com.petdiet.recipe.repository.RecipeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MealRecordService {

    private final MealRecordRepository mealRecordRepository;
    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final SupabaseStorageService supabaseStorageService;
    private final RecipeRepository recipeRepository;
    private final CommercialFoodRepository commercialFoodRepository;
    private final UserFoodRepository userFoodRepository;

    @Transactional(readOnly = true)
    public List<MealRecordResponse> getMyRecords(UUID authUuid, Integer petId) {
        User user = findUser(authUuid);
        List<MealRecord> records = petId != null
                ? mealRecordRepository.findAllByUserAndPet_PetIdOrderByCreatedAtDesc(user, petId)
                : mealRecordRepository.findAllByUserOrderByCreatedAtDesc(user);
        return records.stream().map(this::toResponse).toList();
    }

    @Transactional
    public MealRecordResponse create(UUID authUuid, MealRecordRequest req) {
        User user = findUser(authUuid);
        UserPet pet = req.getPetId() != null
                ? userPetRepository.findByPetIdAndUser(req.getPetId(), user).orElse(null)
                : null;

        MealRecord record = MealRecord.builder()
                .user(user)
                .pet(pet)
                .mealTitle(req.getMealTitle())
                .mealNote(req.getMealNote())
                .imageUrl(req.getImageUrl())
                .mealDate(req.getMealDate())
                .feedingAmountG(req.getFeedingAmountG())
                .recipeId(req.getRecipeId())
                .commercialFoodId(req.getCommercialFoodId())
                .userFoodId(req.getUserFoodId())
                .build();

        return toResponse(mealRecordRepository.save(record));
    }

    private MealRecordResponse toResponse(MealRecord r) {
        Recipe recipe = r.getRecipeId() != null ? recipeRepository.findById(r.getRecipeId()).orElse(null) : null;
        CommercialFood food = r.getCommercialFoodId() != null
                ? commercialFoodRepository.findById(r.getCommercialFoodId()).orElse(null) : null;
        UserFood userFood = r.getUserFoodId() != null
                ? userFoodRepository.findById(r.getUserFoodId()).orElse(null) : null;
        return MealRecordResponse.from(r, recipe, food, userFood);
    }

    @Transactional
    public String uploadPhoto(UUID authUuid, MultipartFile file) throws IOException {
        findUser(authUuid);
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";
        return supabaseStorageService.uploadMealImageBytes(file.getBytes(), contentType);
    }

    @Transactional
    public void delete(UUID authUuid, Integer mealId) {
        User user = findUser(authUuid);
        MealRecord record = mealRecordRepository.findByMealIdAndUser(mealId, user)
                .orElseThrow(() -> new IllegalArgumentException("식단 기록을 찾을 수 없습니다."));
        mealRecordRepository.delete(record);
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }
}

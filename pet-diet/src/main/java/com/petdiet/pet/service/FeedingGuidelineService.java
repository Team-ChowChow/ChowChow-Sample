package com.petdiet.pet.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.pet.dto.FeedingGuidelineResponse;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import com.petdiet.recipe.repository.RecipeNutritionSummaryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Period;
import java.util.UUID;

/**
 * 체중 기반 RER/MER 공식(WSAVA 표준)으로 반려동물의 하루 권장 급여 칼로리·중량을 계산하고,
 * 현재 급여량과 비교해 과다/부족 여부를 판단.
 */
@Service
@RequiredArgsConstructor
public class FeedingGuidelineService {

    private final UserPetRepository userPetRepository;
    private final UserRepository userRepository;
    private final RecipeNutritionSummaryRepository nutritionRepository;

    private static final BigDecimal GROWING_FACTOR = BigDecimal.valueOf(2.5);
    private static final BigDecimal ADULT_NEUTERED_FACTOR = BigDecimal.valueOf(1.6);
    private static final BigDecimal ADULT_INTACT_FACTOR = BigDecimal.valueOf(1.8);
    private static final BigDecimal STATUS_TOLERANCE = BigDecimal.valueOf(0.1); // ±10%

    @Transactional(readOnly = true)
    public FeedingGuidelineResponse calculate(UUID authUuid, Integer petId, Integer recipeId,
                                               BigDecimal kcalPer100g, BigDecimal currentFeedingAmountG) {
        User user = findUser(authUuid);
        UserPet pet = userPetRepository.findByPetIdAndUser(petId, user)
                .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."));
        if (pet.getPetWeight() == null) {
            throw new IllegalStateException("반려동물의 체중 정보가 등록되어 있지 않습니다.");
        }

        boolean isGrowing = isGrowing(pet.getPetBirthdate());
        BigDecimal factor = isGrowing
                ? GROWING_FACTOR
                : (Boolean.TRUE.equals(pet.getIsNeutered()) ? ADULT_NEUTERED_FACTOR : ADULT_INTACT_FACTOR);

        BigDecimal rer = BigDecimal.valueOf(70 * Math.pow(pet.getPetWeight().doubleValue(), 0.75))
                .setScale(1, RoundingMode.HALF_UP);
        BigDecimal mer = rer.multiply(factor).setScale(1, RoundingMode.HALF_UP);

        BigDecimal density = resolveKcalPer100g(recipeId, kcalPer100g);
        BigDecimal recommendedGrams = density != null && density.compareTo(BigDecimal.ZERO) > 0
                ? mer.divide(density, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                        .setScale(1, RoundingMode.HALF_UP)
                : null;

        String status = null;
        String message = null;
        if (recommendedGrams != null && currentFeedingAmountG != null) {
            BigDecimal diffRatio = currentFeedingAmountG.subtract(recommendedGrams)
                    .divide(recommendedGrams, 4, RoundingMode.HALF_UP);
            int percent = diffRatio.abs().multiply(BigDecimal.valueOf(100)).setScale(0, RoundingMode.HALF_UP).intValue();
            if (diffRatio.compareTo(STATUS_TOLERANCE) > 0) {
                status = "과다";
                message = "권장 급여량보다 약 " + percent + "% 많이 급여하고 있어요. 비만 위험이 있으니 양을 줄여보세요.";
            } else if (diffRatio.compareTo(STATUS_TOLERANCE.negate()) < 0) {
                status = "부족";
                message = "권장 급여량보다 약 " + percent + "% 적게 급여하고 있어요. 영양 부족이 우려되니 양을 늘려보세요.";
            } else {
                status = "적정";
                message = "권장 급여량 범위 내에서 잘 급여하고 있어요.";
            }
        }

        return FeedingGuidelineResponse.builder()
                .petWeightKg(pet.getPetWeight())
                .ageCategory(isGrowing ? "성장기" : "성체")
                .activityFactor(factor)
                .restingEnergyKcal(rer)
                .dailyEnergyKcal(mer)
                .recommendedGrams(recommendedGrams)
                .status(status)
                .message(message)
                .build();
    }

    private BigDecimal resolveKcalPer100g(Integer recipeId, BigDecimal kcalPer100g) {
        if (kcalPer100g != null) return kcalPer100g;
        if (recipeId == null) return null;
        return nutritionRepository.findByRecipeRecipeId(recipeId)
                .filter(n -> n.getTotalWeight() != null && n.getTotalCalories() != null
                        && n.getTotalWeight().compareTo(BigDecimal.ZERO) > 0)
                .map(n -> n.getTotalCalories().divide(n.getTotalWeight(), 6, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100)))
                .orElse(null);
    }

    private boolean isGrowing(LocalDate birthdate) {
        return birthdate != null && Period.between(birthdate, LocalDate.now()).toTotalMonths() < 12;
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }
}

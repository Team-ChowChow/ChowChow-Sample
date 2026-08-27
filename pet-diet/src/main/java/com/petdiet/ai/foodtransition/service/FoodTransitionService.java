package com.petdiet.ai.foodtransition.service;

import com.petdiet.ai.foodtransition.dto.FoodTransitionResponse;
import com.petdiet.ai.foodtransition.dto.FoodTransitionStepDto;
import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.repository.CommercialFoodRepository;
import com.petdiet.master.entity.Allergy;
import com.petdiet.master.repository.AllergyRepository;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static java.util.stream.Collectors.joining;

/**
 * 현재 급여 중인 사료에서 새 사료로 넘어갈 때의 단계별 배합 비율(전환 스케줄)을 계산.
 *
 * 널리 통용되는 수의학적 사료 전환 가이드라인(예: WSAVA, 각 사료 제조사 공식 가이드)은
 * "7일에 걸쳐 75:25 → 50:50 → 25:75 → 0:100으로 점진 전환"을 표준으로 제시하고,
 * 두 사료의 영양 성분 차이가 크면 기간을 늘리고 단계를 세분화하도록 권장한다(정확한
 * 임계값은 문헌에 명시되어 있지 않아 이 서비스의 근사치를 사용). 이 스케줄을 LLM이
 * 매번 새로 생성하면 실행마다 달라지고 근거도 없어, 표준 스케줄을 코드에 고정하고
 * 성분 차이 크기로 기간(7/10일)과 단계 수(4/6단계)를 결정하는 계산으로 대체했다.
 * 성분 차이 자체(칼로리/단백질/지방 실측 수치)는 warnings에 구체적으로 안내한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FoodTransitionService {

    // ponytail: 임계값은 WSAVA 등에서 제시하는 정성적 기준("차이가 크면 더 길게")을
    // 정량화한 근사치. 더 정밀한 임상 데이터가 확보되면 교체.
    private static final BigDecimal CALORIE_DIFF_RATIO_THRESHOLD = new BigDecimal("0.15"); // 칼로리 15% 이상 차이
    private static final BigDecimal MACRO_DIFF_THRESHOLD = new BigDecimal("8"); // 단백질/지방 8g/100g 이상 차이

    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final AllergyRepository allergyRepository;
    private final CommercialFoodRepository commercialFoodRepository;

    @Transactional(readOnly = true)
    public FoodTransitionResponse recommend(UUID authUuid, Integer petId, Integer currentFoodId, Integer targetFoodId) {
        User user = userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));

        CommercialFood currentFood = commercialFoodRepository.findById(currentFoodId)
                .orElseThrow(() -> new IllegalArgumentException("현재 급여 중인 사료를 찾을 수 없습니다."));
        CommercialFood targetFood = commercialFoodRepository.findById(targetFoodId)
                .orElseThrow(() -> new IllegalArgumentException("바꿀 사료를 찾을 수 없습니다."));

        if (currentFood.getPetType() != null && targetFood.getPetType() != null
                && !currentFood.getPetType().equals(targetFood.getPetType())) {
            throw new IllegalArgumentException("강아지 사료와 고양이 사료는 서로 전환할 수 없어요. 같은 동물용 사료를 선택해주세요.");
        }

        UserPet pet = null;
        List<Allergy> allergies = List.of();
        if (petId != null) {
            pet = userPetRepository.findByPetIdAndUser(petId, user).orElse(null);
            if (pet != null) {
                if (currentFood.getPetType() != null && !currentFood.getPetType().equals(pet.getPetType())) {
                    throw new IllegalArgumentException("선택한 사료가 반려동물의 종(강아지/고양이)과 맞지 않아요.");
                }
                List<Integer> allergyIds = pet.getAllergies().stream().map(a -> a.getAllergyId()).toList();
                allergies = allergyRepository.findAllById(allergyIds);
            }
        }

        boolean bigDifference = isBigDifference(currentFood, targetFood);
        int totalDays = bigDifference ? 10 : 7;
        List<FoodTransitionStepDto> schedule = buildSchedule(totalDays, bigDifference);
        List<String> warnings = buildWarnings(allergies, currentFood, targetFood);
        String summary = String.format(
                "%s에서 %s로 %d일에 걸쳐 점진적으로 전환합니다.",
                currentFood.getProductName(), targetFood.getProductName(), totalDays);

        return FoodTransitionResponse.builder()
                .summary(summary)
                .totalDays(totalDays)
                .schedule(schedule)
                .warnings(warnings)
                .build();
    }

    private boolean isBigDifference(CommercialFood a, CommercialFood b) {
        if (macroDiffExceeds(a.getCaloriesPer100g(), b.getCaloriesPer100g(), null, CALORIE_DIFF_RATIO_THRESHOLD)) return true;
        if (macroDiffExceeds(a.getProteinG(), b.getProteinG(), MACRO_DIFF_THRESHOLD, null)) return true;
        return macroDiffExceeds(a.getFatG(), b.getFatG(), MACRO_DIFF_THRESHOLD, null);
    }

    /** absThreshold(절대값 g) 또는 ratioThreshold(비율) 중 주어진 쪽 기준으로 차이가 임계값을 넘는지 확인 */
    private boolean macroDiffExceeds(BigDecimal x, BigDecimal y, BigDecimal absThreshold, BigDecimal ratioThreshold) {
        if (x == null || y == null) return false;
        BigDecimal diff = x.subtract(y).abs();
        if (absThreshold != null) {
            return diff.compareTo(absThreshold) >= 0;
        }
        BigDecimal avg = x.add(y).divide(BigDecimal.valueOf(2), 4, java.math.RoundingMode.HALF_UP);
        if (avg.compareTo(BigDecimal.ZERO) == 0) return false;
        return diff.divide(avg, 4, java.math.RoundingMode.HALF_UP).compareTo(ratioThreshold) >= 0;
    }

    /**
     * 표준 사료 전환 스케줄. 성분 차이가 작으면 75:25→50:50→25:75→0:100의 4단계(7일),
     * 성분 차이가 크면 장 적응 부담을 줄이도록 6단계로 더 세분화(10일) — 기간만 늘리고
     * 같은 4단계를 나눠 붓는 방식은 단계별 변화폭이 그대로라 개선 효과가 없다는 지적을
     * 반영해, 단계 수 자체를 늘렸다.
     */
    private List<FoodTransitionStepDto> buildSchedule(int totalDays, boolean fineGrained) {
        int[] currentPercents = fineGrained
                ? new int[]{90, 75, 50, 25, 10, 0}
                : new int[]{75, 50, 25, 0};
        String[] notes = fineGrained
                ? new String[]{
                        "아주 소량만 섞어 반응 관찰",
                        "소량 섞어 반응 관찰",
                        "절반씩 섞어 급여",
                        "새 사료 비중을 늘려 적응",
                        "새 사료 비중을 더 늘려 마무리 준비",
                        "새 사료로 완전 전환"}
                : new String[]{
                        "소량 섞어 반응 관찰",
                        "절반씩 섞어 급여",
                        "새 사료 비중을 늘려 적응 마무리",
                        "새 사료로 완전 전환"};

        int steps = currentPercents.length;
        int stepDays = totalDays / steps;
        int remainder = totalDays % steps;

        List<FoodTransitionStepDto> schedule = new ArrayList<>();
        int dayCursor = 1;
        for (int i = 0; i < steps; i++) {
            int daysInStep = stepDays + (i < remainder ? 1 : 0);
            if (daysInStep <= 0) daysInStep = 1;
            int startDay = dayCursor;
            int endDay = dayCursor + daysInStep - 1;
            String dayRange = startDay == endDay ? startDay + "일차" : startDay + "~" + endDay + "일차";
            schedule.add(FoodTransitionStepDto.builder()
                    .dayRange(dayRange)
                    .currentFoodPercent(currentPercents[i])
                    .newFoodPercent(100 - currentPercents[i])
                    .note(notes[i])
                    .build());
            dayCursor = endDay + 1;
        }
        return schedule;
    }

    // ponytail: "얼마나 다르면 언급할 가치가 있는가"의 근사치. isBigDifference()의 기간 연장
    // 임계값보다 낮게 잡아, 기간은 그대로 7일이어도 실질적 성분 차이는 사용자에게 알린다.
    private static final BigDecimal CALORIE_MENTION_RATIO = new BigDecimal("0.10");
    private static final BigDecimal MACRO_MENTION_THRESHOLD = new BigDecimal("5");

    private List<String> buildWarnings(List<Allergy> allergies, CommercialFood currentFood, CommercialFood targetFood) {
        List<String> warnings = new ArrayList<>();
        warnings.add("급여 중 설사, 구토 등의 이상 반응이 발생하면 이전 단계로 되돌아가세요.");

        addCalorieWarning(warnings, currentFood.getCaloriesPer100g(), targetFood.getCaloriesPer100g());
        addMacroWarning(warnings, "단백질", currentFood.getProteinG(), targetFood.getProteinG(),
                "신장이나 간 질환이 있다면 수의사와 상담 후 진행하세요.");
        addMacroWarning(warnings, "지방", currentFood.getFatG(), targetFood.getFatG(),
                "췌장염 등 지방에 민감한 질환이 있다면 단계를 더 천천히 늘려주세요.");

        if (!allergies.isEmpty()) {
            warnings.add(
                    allergies.stream().map(Allergy::getAllergyName).collect(joining(", "))
                            + " 알러지가 있으므로 새 사료 성분에 주의하세요.");
        }
        return warnings;
    }

    private void addCalorieWarning(List<String> warnings, BigDecimal current, BigDecimal target) {
        if (current == null || target == null) return;
        BigDecimal diff = target.subtract(current);
        BigDecimal avg = current.add(target).divide(BigDecimal.valueOf(2), 4, java.math.RoundingMode.HALF_UP);
        if (avg.compareTo(BigDecimal.ZERO) == 0) return;
        BigDecimal ratio = diff.abs().divide(avg, 4, java.math.RoundingMode.HALF_UP);
        if (ratio.compareTo(CALORIE_MENTION_RATIO) < 0) return;
        int percent = ratio.multiply(BigDecimal.valueOf(100)).setScale(0, java.math.RoundingMode.HALF_UP).intValue();
        String direction = diff.signum() > 0 ? "높아요" : "낮아요";
        warnings.add(String.format(
                "새 사료는 100g당 칼로리가 기존 사료보다 약 %d%% %s(%s → %skcal). 같은 무게로 바꾸면 급여량이 달라지니 급여량 계산기로 다시 확인하세요.",
                percent, direction, current.stripTrailingZeros().toPlainString(), target.stripTrailingZeros().toPlainString()));
    }

    private void addMacroWarning(List<String> warnings, String label, BigDecimal current, BigDecimal target, String advice) {
        if (current == null || target == null) return;
        BigDecimal diff = target.subtract(current);
        if (diff.abs().compareTo(MACRO_MENTION_THRESHOLD) < 0) return;
        String direction = diff.signum() > 0 ? "많아요" : "적어요";
        warnings.add(String.format(
                "%s 함량이 100g당 %sg %s(%s → %sg). %s",
                label, diff.abs().stripTrailingZeros().toPlainString(), direction,
                current.stripTrailingZeros().toPlainString(), target.stripTrailingZeros().toPlainString(), advice));
    }
}

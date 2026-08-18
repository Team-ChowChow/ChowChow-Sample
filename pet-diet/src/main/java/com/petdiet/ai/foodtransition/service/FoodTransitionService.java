package com.petdiet.ai.foodtransition.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.ai.foodtransition.dto.FoodTransitionResponse;
import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.food.entity.CommercialFood;
import com.petdiet.food.repository.CommercialFoodRepository;
import com.petdiet.master.entity.Allergy;
import com.petdiet.master.repository.AllergyRepository;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static java.util.stream.Collectors.joining;

/**
 * 현재 급여 중인 사료에서 새 사료로 넘어갈 때, 소화 적응을 위한 단계별 배합 비율(일수별 %)을
 * OpenAI에 요청해 안내. DietRecommendService와 동일한 WebClient 직접 호출 방식을 사용.
 */
@Slf4j
@Service
public class FoodTransitionService {

    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final AllergyRepository allergyRepository;
    private final CommercialFoodRepository commercialFoodRepository;
    private final ObjectMapper objectMapper;
    private final WebClient webClient;
    private final String model;
    private final int maxTokens;

    public FoodTransitionService(
            UserRepository userRepository,
            UserPetRepository userPetRepository,
            AllergyRepository allergyRepository,
            CommercialFoodRepository commercialFoodRepository,
            ObjectMapper objectMapper,
            @Value("${openai.api-key}") String apiKey,
            @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
            @Value("${openai.model:gpt-4o}") String model,
            @Value("${openai.max-tokens:2048}") int maxTokens) {
        this.userRepository = userRepository;
        this.userPetRepository = userPetRepository;
        this.allergyRepository = allergyRepository;
        this.commercialFoodRepository = commercialFoodRepository;
        this.objectMapper = objectMapper;
        this.model = model;
        this.maxTokens = maxTokens;
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    @Transactional(readOnly = true)
    public FoodTransitionResponse recommend(UUID authUuid, Integer petId, Integer currentFoodId, Integer targetFoodId) {
        User user = userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));

        CommercialFood currentFood = commercialFoodRepository.findById(currentFoodId)
                .orElseThrow(() -> new IllegalArgumentException("현재 급여 중인 사료를 찾을 수 없습니다."));
        CommercialFood targetFood = commercialFoodRepository.findById(targetFoodId)
                .orElseThrow(() -> new IllegalArgumentException("바꿀 사료를 찾을 수 없습니다."));

        UserPet pet = null;
        List<Allergy> allergies = List.of();
        if (petId != null) {
            pet = userPetRepository.findByPetIdAndUser(petId, user).orElse(null);
            if (pet != null) {
                List<Integer> allergyIds = pet.getAllergies().stream().map(a -> a.getAllergyId()).toList();
                allergies = allergyRepository.findAllById(allergyIds);
            }
        }

        String prompt = buildPrompt(pet, allergies, currentFood, targetFood);
        return callOpenAi(prompt);
    }

    String buildPrompt(UserPet pet, List<Allergy> allergies, CommercialFood currentFood, CommercialFood targetFood) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 반려동물 영양 전문가입니다. 사료를 바꿀 때 급격한 전환으로 인한 소화불량(설사, 구토 등)을 ")
          .append("막기 위해, 현재 사료와 새 사료를 섞어 먹이는 단계별 배합 비율(전환 스케줄)을 추천해주세요.\n\n");

        if (pet != null) {
            sb.append("## 반려동물 정보\n");
            sb.append("- 종류: ").append(pet.getPetType()).append("\n");
            if (pet.getPetWeight() != null) {
                sb.append("- 체중: ").append(pet.getPetWeight()).append("kg\n");
            }
            if (!allergies.isEmpty()) {
                sb.append("- 알레르기: ").append(allergies.stream().map(Allergy::getAllergyName).collect(joining(", ")))
                  .append("\n");
            }
        }

        sb.append("\n## 현재 급여 중인 사료\n");
        appendFoodInfo(sb, currentFood);

        sb.append("\n## 새로 바꿀 사료\n");
        appendFoodInfo(sb, targetFood);

        sb.append("\n## 전환 원칙\n");
        sb.append("- 총 기간은 보통 7~10일 사이에서, 두 사료의 성분 차이(칼로리 밀도, 단백질/지방 비율)가 클수록 더 길게 잡아주세요.\n");
        sb.append("- 최소 3단계 이상으로 나누어, 새 사료 비율을 점진적으로 늘려가야 합니다.\n");
        sb.append("- 급여 중 설사·구토 등 이상 반응 시 이전 단계로 되돌아가라는 주의사항을 포함해주세요.\n");

        sb.append("\n## 응답 형식 (JSON만 반환, 마크다운 코드블록 없이)\n");
        sb.append("""
                {
                  "summary": "전체 전환 계획 한줄 요약",
                  "totalDays": 7,
                  "schedule": [
                    {"dayRange": "1~2일차", "currentFoodPercent": 75, "newFoodPercent": 25, "note": "소량 섞어 반응 관찰"}
                  ],
                  "warnings": ["주의사항 1", "주의사항 2"]
                }
                """);
        return sb.toString();
    }

    private void appendFoodInfo(StringBuilder sb, CommercialFood food) {
        sb.append("- 제품명: ").append(food.getBrandName()).append(' ').append(food.getProductName()).append("\n");
        if (food.getCaloriesPer100g() != null) {
            sb.append("- 칼로리: ").append(food.getCaloriesPer100g()).append(" kcal/100g\n");
        }
        appendMacro(sb, "단백질", food.getProteinG());
        appendMacro(sb, "지방", food.getFatG());
        appendMacro(sb, "탄수화물", food.getCarbohydrateG());
    }

    private void appendMacro(StringBuilder sb, String label, BigDecimal value) {
        if (value != null) {
            sb.append("- ").append(label).append(": ").append(value).append("g/100g\n");
        }
    }

    private FoodTransitionResponse callOpenAi(String prompt) {
        Map<String, Object> body = Map.of(
                "model", model,
                "max_tokens", maxTokens,
                "temperature", 0.7,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "response_format", Map.of("type", "json_object")
        );

        try {
            String responseBody = webClient.post()
                    .uri("/v1/chat/completions")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(responseBody);
            String content = root.path("choices").get(0).path("message").path("content").stringValue();
            return objectMapper.readValue(content, FoodTransitionResponse.class);
        } catch (Exception e) {
            log.error("OpenAI 사료 교체 가이드 API 호출 실패", e);
            throw new RuntimeException("AI 사료 교체 가이드 생성 중 오류가 발생했습니다.", e);
        }
    }
}

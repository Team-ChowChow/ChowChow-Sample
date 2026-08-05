package com.petdiet.ingredient.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.ingredient.client.FoodDataCentralClient;
import com.petdiet.ingredient.client.SpoonacularClient;
import com.petdiet.ingredient.client.SpoonacularClient.IngredientInfo;
import com.petdiet.ingredient.entity.Ingredient;
import com.petdiet.ingredient.repository.IngredientRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class IngredientEnrichService {

    private static final int TRANSLATE_BATCH = 40;

    private record ToxicityRule(boolean dog, boolean cat, String note) {}

    // ASPCA Animal Poison Control 기준 대표 위험 식재료.
    // ponytail: 부분 문자열 매칭이라 오탐 가능(예: "chocolate milk"), 정밀 매칭 필요해지면 정규화 필요.
    private static final Map<String, ToxicityRule> TOXIC_KEYWORDS = Map.ofEntries(
            Map.entry("chocolate", new ToxicityRule(true, true, "테오브로민 중독 위험 - 구토, 발작, 심장 이상")),
            Map.entry("cocoa", new ToxicityRule(true, true, "테오브로민 중독 위험 - 구토, 발작, 심장 이상")),
            Map.entry("grape", new ToxicityRule(true, true, "급성 신부전 위험")),
            Map.entry("raisin", new ToxicityRule(true, true, "급성 신부전 위험")),
            Map.entry("onion", new ToxicityRule(true, true, "적혈구 파괴(용혈성 빈혈) 위험")),
            Map.entry("garlic", new ToxicityRule(true, true, "적혈구 파괴(용혈성 빈혈) 위험")),
            Map.entry("leek", new ToxicityRule(true, true, "적혈구 파괴(용혈성 빈혈) 위험")),
            Map.entry("chive", new ToxicityRule(true, true, "적혈구 파괴(용혈성 빈혈) 위험")),
            Map.entry("xylitol", new ToxicityRule(true, true, "저혈당·간부전 위험, 소량도 치명적")),
            Map.entry("avocado", new ToxicityRule(true, true, "페르신 성분 - 구토·설사 위험")),
            Map.entry("macadamia", new ToxicityRule(true, false, "근육 떨림·마비 위험(개)")),
            Map.entry("caffeine", new ToxicityRule(true, true, "심장·신경계 이상 위험")),
            Map.entry("coffee", new ToxicityRule(true, true, "카페인 중독 위험")),
            Map.entry("alcohol", new ToxicityRule(true, true, "중추신경 억제, 치명적일 수 있음")),
            Map.entry("nutmeg", new ToxicityRule(true, true, "환각·경련 위험"))
    );

    private final IngredientRepository ingredientRepository;
    private final SpoonacularClient spoonacularClient;
    private final FoodDataCentralClient foodDataCentralClient;
    private final ObjectMapper objectMapper;
    private final WebClient openAiClient;
    private final String openAiModel;

    public IngredientEnrichService(
            IngredientRepository ingredientRepository,
            SpoonacularClient spoonacularClient,
            FoodDataCentralClient foodDataCentralClient,
            ObjectMapper objectMapper,
            @Value("${openai.api-key}") String apiKey,
            @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
            @Value("${openai.model:gpt-4o}") String model) {
        this.ingredientRepository = ingredientRepository;
        this.spoonacularClient = spoonacularClient;
        this.foodDataCentralClient = foodDataCentralClient;
        this.objectMapper = objectMapper;
        this.openAiModel = model;
        this.openAiClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    /**
     * Spoonacular에서 영양소 데이터를 가져와 저장 (batchSize건씩).
     * spoonacularId가 있고 caloriesPer100g가 없는 재료 대상.
     */
    @Transactional
    public int enrichNutrition(int batchSize) {
        List<Ingredient> targets = ingredientRepository
                .findBySpoonacularIdIsNotNullAndCaloriesPer100gIsNull(PageRequest.of(0, batchSize));
        int count = 0;
        for (Ingredient ingredient : targets) {
            IngredientInfo info = spoonacularClient.getIngredientInfo(ingredient.getSpoonacularId());
            if (info != null && info.calories() != null) {
                ingredient.updateNutrition(info.calories(), info.protein(), info.fat(),
                        info.carbohydrates(), info.fiber());
                ingredientRepository.save(ingredient);
                count++;
            }
            try { Thread.sleep(100); } catch (InterruptedException ignored) {}
        }
        log.info("영양소 보강 완료: {}건", count);
        return count;
    }

    /**
     * USDA FoodData Central에서 영양소 데이터를 가져와 저장 (batchSize건씩).
     * Spoonacular로 못 채운(spoonacularId 없거나 실패한) 재료까지 이름 검색으로 커버.
     */
    @Transactional
    public int enrichNutritionFromFdc(int batchSize) {
        List<Ingredient> targets = ingredientRepository
                .findByCaloriesPer100gIsNull(PageRequest.of(0, batchSize));
        int count = 0;
        for (Ingredient ingredient : targets) {
            FoodDataCentralClient.IngredientInfo info = foodDataCentralClient.getNutrition(ingredient.getIngredientName());
            if (info != null && info.calories() != null) {
                ingredient.updateNutrition(info.calories(), info.protein(), info.fat(),
                        info.carbohydrates(), info.fiber());
                ingredientRepository.save(ingredient);
                count++;
            }
            try { Thread.sleep(100); } catch (InterruptedException ignored) {}
        }
        log.info("FDC 영양소 보강 완료: {}건", count);
        return count;
    }

    /**
     * ASPCA 기준 대표 위험 식재료 목록으로 isToxicToDog/isToxicToCat/toxicityNote를 채운다.
     * 정적 참조 데이터라 외부 API 없이 전수 스캔.
     */
    @Transactional
    public int seedToxicity() {
        int count = 0;
        for (Ingredient ingredient : ingredientRepository.findAll()) {
            String haystack = (ingredient.getIngredientName() + " "
                    + (ingredient.getIngredientNameKo() != null ? ingredient.getIngredientNameKo() : ""))
                    .toLowerCase();
            for (var entry : TOXIC_KEYWORDS.entrySet()) {
                if (haystack.contains(entry.getKey())) {
                    ToxicityRule rule = entry.getValue();
                    ingredient.updateToxicity(rule.dog(), rule.cat(), rule.note());
                    ingredientRepository.save(ingredient);
                    count++;
                    break;
                }
            }
        }
        log.info("독성 재료 시드 완료: {}건", count);
        return count;
    }

    /**
     * OpenAI로 한글 이름 번역 (TRANSLATE_BATCH건씩).
     * ingredientNameKo가 없는 재료 대상.
     */
    @Transactional
    public int translateToKorean(int batchSize) {
        int total = 0;
        int pages = (int) Math.ceil((double) batchSize / TRANSLATE_BATCH);

        for (int page = 0; page < pages; page++) {
            List<Ingredient> targets = ingredientRepository
                    .findByIngredientNameKoIsNull(PageRequest.of(0, TRANSLATE_BATCH));
            if (targets.isEmpty()) break;

            List<String> names = targets.stream().map(Ingredient::getIngredientName).toList();
            Map<String, String> translations = callGptTranslate(names);

            for (Ingredient ingredient : targets) {
                String ko = translations.get(ingredient.getIngredientName());
                if (ko != null && !ko.isBlank()) {
                    ingredient.updateKoreanName(ko);
                    ingredientRepository.save(ingredient);
                    total++;
                }
            }
            log.info("한글 번역 진행: {}건 완료 (누적 {}건)", targets.size(), total);
        }
        return total;
    }

    private Map<String, String> callGptTranslate(List<String> names) {
        String nameList = String.join("\n", names);
        String prompt = """
                다음 영어 식재료 이름들을 반려동물 식품 맥락에서 한국어로 번역해주세요.
                JSON 형식으로만 응답하세요. 형식: {"translations": {"영어이름": "한국어이름", ...}}
                번역할 재료:
                """ + nameList;

        Map<String, Object> body = Map.of(
                "model", openAiModel,
                "max_tokens", 2048,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "response_format", Map.of("type", "json_object")
        );

        try {
            String response = openAiClient.post()
                    .uri("/v1/chat/completions")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);
            String content = root.path("choices").get(0).path("message").path("content").stringValue();
            JsonNode translationsNode = objectMapper.readTree(content).path("translations");

            @SuppressWarnings("unchecked")
            Map<String, String> result = objectMapper.convertValue(translationsNode, Map.class);
            return result != null ? result : Map.of();

        } catch (Exception e) {
            log.error("GPT 번역 실패: {}", e.getMessage());
            return Map.of();
        }
    }

    /**
     * spoonacularId가 없는 재료에 대해 이름으로 재검색해서 ID 저장.
     */
    @Transactional
    public int backfillSpoonacularIds(int batchSize) {
        List<Ingredient> targets = ingredientRepository.findAll().stream()
                .filter(i -> i.getSpoonacularId() == null)
                .limit(batchSize)
                .toList();

        int count = 0;
        for (Ingredient ingredient : targets) {
            List<SpoonacularClient.IngredientResult> results =
                    spoonacularClient.searchIngredients(ingredient.getIngredientName(), 1);
            if (!results.isEmpty() && results.get(0).id() != null) {
                ingredient.updateSpoonacularId(results.get(0).id());
                ingredientRepository.save(ingredient);
                count++;
            }
            try { Thread.sleep(200); } catch (InterruptedException ignored) {}
        }
        log.info("SpoonacularId 역채움 완료: {}건", count);
        return count;
    }
}

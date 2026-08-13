package com.petdiet.ingredient.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

import java.math.BigDecimal;
import java.util.List;

/**
 * USDA FoodData Central API 클라이언트 - 재료명 검색 한 번으로 100g당 영양소를 바로 받는다.
 * https://fdc.nal.usda.gov/api-guide.html
 */
@Slf4j
@Component
public class FoodDataCentralClient {

    // 원재료가 아닌 가공/농축 형태(건조·분말·주스·통조림 등)는 100g당 영양소가 왜곡되므로 우선순위에서 배제
    private static final List<String> PROCESSED_KEYWORDS = List.of(
            "dehydrated", "dried", "powder", "juice", "canned", "babyfood", "baby food",
            "chips", "cake", "cookie", "cereal", "syrup", "extract", "concentrate", "flour"
    );

    private final WebClient webClient;
    private final String apiKey;
    private final ObjectMapper objectMapper;

    public FoodDataCentralClient(
            @Value("${fdc.base-url:https://api.nal.usda.gov/fdc/v1}") String baseUrl,
            @Value("${fdc.api-key:}") String apiKey,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .exchangeStrategies(ExchangeStrategies.builder()
                        .codecs(c -> c.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
                        .build())
                .build();
        this.apiKey = apiKey;
        this.objectMapper = objectMapper;
    }

    public IngredientInfo getNutrition(String query) {
        try {
            String response = webClient.get()
                    .uri(uri -> uri.path("/foods/search")
                            .queryParam("query", query)
                            .queryParam("pageSize", 10)
                            .queryParam("dataType", "Foundation,SR Legacy")
                            .queryParam("api_key", apiKey)
                            .build())
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode foods = objectMapper.readTree(response).path("foods");
            if (!foods.isArray()) return null;

            // 검색 1순위 결과가 가공식품(건조/분말/주스 등)이라 100g당 영양소가 왜곡되는 경우가 있어,
            // 가공식품이 아닌 첫 결과를 우선 채택하고, 없으면 Energy 값이 채워진 첫 결과로 폴백한다.
            IngredientInfo fallback = null;
            for (JsonNode food : foods) {
                IngredientInfo info = parseNutrients(food);
                if (info == null) continue;
                if (fallback == null) fallback = info;
                if (!isProcessed(str(food.path("description")))) {
                    return info;
                }
            }
            return fallback;

        } catch (Exception e) {
            log.warn("FoodData Central 조회 실패 [query={}]: {}", query, e.getMessage());
            return null;
        }
    }

    private static IngredientInfo parseNutrients(JsonNode food) {
        BigDecimal calories = null, protein = null, fat = null, carbs = null, fiber = null;
        for (JsonNode n : food.path("foodNutrients")) {
            String name = str(n.path("nutrientName"));
            if (name == null) continue;
            BigDecimal amount = n.path("value").getNodeType() == JsonNodeType.NUMBER
                    ? BigDecimal.valueOf(n.path("value").doubleValue()) : null;
            switch (name) {
                // Energy는 KCAL/kJ 두 단위로 중복 제공되므로 KCAL만 취한다 (kJ를 잡으면 약 4.18배 부풀려짐)
                case "Energy" -> {
                    if ("KCAL".equalsIgnoreCase(str(n.path("unitName")))) calories = amount;
                }
                case "Protein" -> protein = amount;
                case "Total lipid (fat)" -> fat = amount;
                case "Carbohydrate, by difference" -> carbs = amount;
                case "Fiber, total dietary" -> fiber = amount;
            }
        }
        return calories != null ? new IngredientInfo(calories, protein, fat, carbs, fiber) : null;
    }

    private static boolean isProcessed(String description) {
        if (description == null) return false;
        String lower = description.toLowerCase();
        return PROCESSED_KEYWORDS.stream().anyMatch(lower::contains);
    }

    private static String str(JsonNode node) {
        return node.getNodeType() == JsonNodeType.STRING ? node.stringValue() : null;
    }

    public record IngredientInfo(
            BigDecimal calories,
            BigDecimal protein,
            BigDecimal fat,
            BigDecimal carbohydrates,
            BigDecimal fiber) {}
}

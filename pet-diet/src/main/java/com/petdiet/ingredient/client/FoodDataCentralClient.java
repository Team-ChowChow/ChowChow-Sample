package com.petdiet.ingredient.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

import java.math.BigDecimal;

/**
 * USDA FoodData Central API 클라이언트 - 재료명 검색 한 번으로 100g당 영양소를 바로 받는다.
 * https://fdc.nal.usda.gov/api-guide.html
 */
@Slf4j
@Component
public class FoodDataCentralClient {

    private final WebClient webClient;
    private final String apiKey;
    private final ObjectMapper objectMapper;

    public FoodDataCentralClient(
            @Value("${fdc.base-url}") String baseUrl,
            @Value("${fdc.api-key}") String apiKey,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder().baseUrl(baseUrl).build();
        this.apiKey = apiKey;
        this.objectMapper = objectMapper;
    }

    public IngredientInfo getNutrition(String query) {
        try {
            String response = webClient.get()
                    .uri(uri -> uri.path("/foods/search")
                            .queryParam("query", query)
                            .queryParam("pageSize", 5)
                            .queryParam("dataType", "Foundation,SR Legacy")
                            .queryParam("api_key", apiKey)
                            .build())
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode foods = objectMapper.readTree(response).path("foods");
            if (!foods.isArray()) return null;

            // 검색 1순위 결과가 가공식품이라 매크로 영양소가 비어있는 경우가 있어,
            // Energy 값이 실제로 채워진 첫 결과를 찾을 때까지 상위 몇 개를 훑는다.
            for (JsonNode food : foods) {
                BigDecimal calories = null, protein = null, fat = null, carbs = null, fiber = null;
                for (JsonNode n : food.path("foodNutrients")) {
                    String name = str(n.path("nutrientName"));
                    if (name == null) continue;
                    BigDecimal amount = n.path("value").getNodeType() == JsonNodeType.NUMBER
                            ? BigDecimal.valueOf(n.path("value").doubleValue()) : null;
                    switch (name) {
                        case "Energy" -> calories = amount;
                        case "Protein" -> protein = amount;
                        case "Total lipid (fat)" -> fat = amount;
                        case "Carbohydrate, by difference" -> carbs = amount;
                        case "Fiber, total dietary" -> fiber = amount;
                    }
                }
                if (calories != null) {
                    return new IngredientInfo(calories, protein, fat, carbs, fiber);
                }
            }
            return null;

        } catch (Exception e) {
            log.warn("FoodData Central 조회 실패 [query={}]: {}", query, e.getMessage());
            return null;
        }
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

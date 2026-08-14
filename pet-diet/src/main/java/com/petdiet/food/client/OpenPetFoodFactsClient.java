package com.petdiet.food.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.ExchangeStrategies;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Open Pet Food Facts(world.openpetfoodfacts.org) - 무료/무인증 오픈 사료 데이터베이스.
 * 브랜드 태그로 검색해 제품명/영양정보/원재료를 가져온다.
 * https://openfoodfacts.github.io/openfoodfacts-server/api/
 */
@Slf4j
@Component
public class OpenPetFoodFactsClient {

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    public OpenPetFoodFactsClient(
            @Value("${openpetfoodfacts.base-url:https://world.openpetfoodfacts.org}") String baseUrl,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .exchangeStrategies(ExchangeStrategies.builder()
                        .codecs(c -> c.defaultCodecs().maxInMemorySize(4 * 1024 * 1024))
                        .build())
                .build();
        this.objectMapper = objectMapper;
    }

    public record FoodResult(
            String barcode, String brand, String productName, String petType,
            BigDecimal calories, BigDecimal protein, BigDecimal fat, BigDecimal carbs,
            String ingredientsText, String imageUrl) {}

    private static final int PAGE_SIZE = 100;
    private static final int MAX_PAGES = 20; // 카테고리당 최대 2000건까지 스캔

    public List<FoodResult> searchByBrand(String brandTag, int maxResults) {
        return search("brands_tags", brandTag, maxResults);
    }

    public List<FoodResult> searchByCategory(String categoryTag, int maxResults) {
        return search("categories_tags", categoryTag, maxResults);
    }

    private record PageResult(int rawCount, List<FoodResult> filtered) {}

    private List<FoodResult> search(String paramName, String paramValue, int maxResults) {
        List<FoodResult> results = new ArrayList<>();
        for (int page = 1; page <= MAX_PAGES && results.size() < maxResults; page++) {
            PageResult page1 = fetchPage(paramName, paramValue, page);
            // 필터 통과 개수가 0이어도 원본 페이지에 데이터가 있으면 계속 탐색한다
            // (품질 낮은 항목이 몰린 페이지 때문에 조기 종료되는 것을 방지)
            if (page1.rawCount() == 0) break; // 진짜 마지막 페이지
            results.addAll(page1.filtered());
        }
        return results;
    }

    private PageResult fetchPage(String paramName, String paramValue, int page) {
        List<FoodResult> results = new ArrayList<>();
        try {
            String response = webClient.get()
                    .uri(uri -> uri.path("/api/v2/search")
                            .queryParam(paramName, paramValue)
                            .queryParam("page_size", PAGE_SIZE)
                            .queryParam("page", page)
                            .queryParam("fields", "code,product_name,brands,ingredients_text,nutriments,image_url,categories_tags")
                            .build())
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode productsNode = objectMapper.readTree(response).path("products");
            if (!productsNode.isArray()) return new PageResult(0, results);

            for (JsonNode p : productsNode) {
                FoodResult parsed = parse(p);
                if (parsed != null) results.add(parsed);
            }
            return new PageResult(productsNode.size(), results);
        } catch (Exception e) {
            log.warn("Open Pet Food Facts 조회 실패 [{}={}, page={}]: {}", paramName, paramValue, page, e.getMessage());
            return new PageResult(0, results);
        }
    }

    private FoodResult parse(JsonNode p) {
        String productName = str(p.path("product_name"));
        String brand = str(p.path("brands"));
        String ingredientsText = str(p.path("ingredients_text"));
        JsonNode n = p.path("nutriments");
        BigDecimal calories = num(n.path("energy-kcal_100g"));
        BigDecimal protein = num(n.path("proteins_100g"));
        BigDecimal fat = num(n.path("fat_100g"));
        BigDecimal carbs = num(n.path("carbohydrates_100g"));

        // 제품명/칼로리 누락이거나, 크라우드소싱 오입력으로 의심되는 비현실적 칼로리는 버린다.
        // 습식(약 60~150)/건식(약 250~450) 사료를 모두 포함하되 명백한 오입력(0.1, 1611 등)만 제외하는 넓은 범위.
        if (productName == null || productName.isBlank() || calories == null) return null;
        if (calories.compareTo(BigDecimal.valueOf(50)) < 0 || calories.compareTo(BigDecimal.valueOf(700)) > 0) return null;

        String petType = petTypeFromTags(p.path("categories_tags"));
        if (petType == null) petType = petTypeFromName(productName);

        return new FoodResult(
                str(p.path("code")), brand, productName, petType,
                calories, protein, fat, carbs, ingredientsText, str(p.path("image_url")));
    }

    private static BigDecimal num(JsonNode node) {
        return node.getNodeType() == JsonNodeType.NUMBER ? BigDecimal.valueOf(node.doubleValue()) : null;
    }

    private static String petTypeFromTags(JsonNode categoriesTags) {
        // 정확히 "en:cat-food" / "en:dog-food"만 인정한다. "en:dog-and-cat-food"처럼
        // 겸용 태그는 .contains("cat-food")가 부분 문자열로 오탐되므로 정확 일치로만 판단.
        boolean isCat = false, isDog = false;
        for (JsonNode tag : categoriesTags) {
            String t = str(tag);
            if (t == null) continue;
            if (t.equals("en:cat-food")) isCat = true;
            else if (t.equals("en:dog-food")) isDog = true;
        }
        if (isCat && !isDog) return "CAT";
        if (isDog && !isCat) return "DOG";
        return null;
    }

    // categories_tags가 크라우드소싱 데이터 특성상 비어있는 경우가 많아, 제품명 키워드(다국어)로 보완 추정.
    // ponytail: 태그보다 신뢰도는 낮은 휴리스틱. 두 키워드가 동시에 매칭되면(예: "chien et chat") 판단하지 않음.
    private static final List<String> CAT_WORDS = List.of("cat", "kitten", "chat", "gato", "gatto", "katze");
    private static final List<String> DOG_WORDS = List.of("dog", "puppy", "chien", "perro", "cane", "hund");

    private static String petTypeFromName(String productName) {
        String lower = productName.toLowerCase();
        boolean isCat = CAT_WORDS.stream().anyMatch(lower::contains);
        boolean isDog = DOG_WORDS.stream().anyMatch(lower::contains);
        if (isCat && !isDog) return "CAT";
        if (isDog && !isCat) return "DOG";
        return null;
    }

    private static String str(JsonNode node) {
        return node.getNodeType() == JsonNodeType.STRING ? node.stringValue() : null;
    }
}

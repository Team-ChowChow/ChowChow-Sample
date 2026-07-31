package com.petdiet.ingredient.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * 네이버 검색 오픈API(쇼핑) 클라이언트 - 여러 쇼핑몰의 가격을 비교해 최저가를 조회한다.
 * https://developers.naver.com/docs/serviceapi/search/shopping/shopping.md
 * Client ID/Secret은 네이버 개발자센터에서 앱 등록 즉시 발급된다(별도 심사 없음).
 */
@Slf4j
@Component
public class NaverShoppingClient {

    /** 샘플/이벤트성 상품(비정상적으로 싼 가격으로 최저가를 왜곡함)을 걸러내기 위한 키워드 */
    private static final Pattern NOISE_TITLE = Pattern.compile(
            "샘플|체험|증정|사은품|이벤트|리뷰\\s*이벤트|1개입|낱개|테스트|미니\\s*사이즈");

    /** 재료 검색이므로 식품 카테고리 외(문구/잡화 등 검색어만 겹치는 무관 상품)는 제외 */
    private static final String FOOD_CATEGORY = "식품";

    /** 100원 미끼가처럼 실거래가로 볼 수 없는 이상치를 걸러내는 최소 가격 */
    private static final long MIN_REALISTIC_PRICE = 500;

    private final WebClient webClient;
    private final String clientId;
    private final String clientSecret;
    private final ObjectMapper objectMapper;

    public NaverShoppingClient(
            @Value("${naver-search.base-url}") String baseUrl,
            @Value("${naver-search.client-id:}") String clientId,
            @Value("${naver-search.client-secret:}") String clientSecret,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder().baseUrl(baseUrl).build();
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.objectMapper = objectMapper;
    }

    public Optional<NaverProduct> searchLowestPrice(String keyword) {
        if (clientId == null || clientId.isBlank() || clientSecret == null || clientSecret.isBlank()) {
            log.info("naver shopping api key not configured, skipping search for [{}]", keyword);
            return Optional.empty();
        }
        try {
            // sort=asc(가격순)는 "100원 특가" 같은 미끼성 옵션가 상품만 최상단에 노출시키므로
            // 기본 정렬(관련도)로 받아온 뒤 노이즈를 걸러내고 그 안에서 최저가를 고른다.
            String response = webClient.get()
                    .uri(uri -> uri.path("/v1/search/shop.json")
                            .queryParam("query", keyword)
                            .queryParam("display", 30)
                            .build())
                    .header("X-Naver-Client-Id", clientId)
                    .header("X-Naver-Client-Secret", clientSecret)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);
            JsonNode items = root.path("items");
            if (!items.isArray() || items.isEmpty()) {
                return Optional.empty();
            }

            List<NaverProduct> candidates = new ArrayList<>();
            for (JsonNode item : items) {
                String title = stripTags(str(item.path("title")));
                if (title == null || title.isBlank()) continue;
                if (NOISE_TITLE.matcher(title).find()) continue;

                String category1 = str(item.path("category1"));
                if (!FOOD_CATEGORY.equals(category1)) continue;

                String rawPrice = str(item.path("lprice"));
                if (rawPrice == null || rawPrice.isBlank()) continue;
                long price = Long.parseLong(rawPrice);
                if (price < MIN_REALISTIC_PRICE) continue;

                String link = str(item.path("link"));
                if (link == null) continue;

                candidates.add(new NaverProduct(title, price, str(item.path("image")), link, str(item.path("mallName"))));
            }

            return candidates.stream().min(Comparator.comparingLong(NaverProduct::price));

        } catch (Exception e) {
            log.warn("네이버 쇼핑 최저가 검색 실패 [keyword={}]: {}", keyword, e.getMessage());
            return Optional.empty();
        }
    }

    private static String stripTags(String value) {
        return value == null ? null : value.replaceAll("<[^>]*>", "");
    }

    private static String str(JsonNode node) {
        return node.getNodeType() == JsonNodeType.STRING ? node.stringValue() : null;
    }

    public record NaverProduct(
            String productName,
            long price,
            String imageUrl,
            String productUrl,
            String mallName) {}
}

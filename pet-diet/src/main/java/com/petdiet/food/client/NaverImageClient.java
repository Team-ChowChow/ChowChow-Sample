package com.petdiet.food.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

/**
 * 네이버 이미지 검색 API 클라이언트 (NAVER API HUB) - 키워드로 대표 이미지 1장을 조회한다.
 * 기존 쇼핑검색과 달리 이미지 검색은 HUB로 정상 이관되어 계속 사용 가능하다.
 * https://naverapihub.apigw.ntruss.com/search/v1/image
 */
@Slf4j
@Component
public class NaverImageClient {

    private final WebClient webClient;
    private final String clientId;
    private final String clientSecret;
    private final ObjectMapper objectMapper;

    public NaverImageClient(
            @Value("${naver-search.hub-base-url:https://naverapihub.apigw.ntruss.com}") String baseUrl,
            @Value("${naver-search.client-id:}") String clientId,
            @Value("${naver-search.client-secret:}") String clientSecret,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder().baseUrl(baseUrl).build();
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.objectMapper = objectMapper;
    }

    public boolean isConfigured() {
        return clientId != null && !clientId.isBlank() && clientSecret != null && !clientSecret.isBlank();
    }

    /** 검색어의 첫 번째 이미지 URL을 반환. 실패하거나 결과가 없으면 null. */
    public String searchFirstImage(String query) {
        if (!isConfigured()) return null;
        try {
            String response = webClient.get()
                    .uri(uri -> uri.path("/search/v1/image")
                            .queryParam("query", query)
                            .queryParam("display", 1)
                            .queryParam("sort", "sim")
                            .build())
                    .header("X-NCP-APIGW-API-KEY-ID", clientId)
                    .header("X-NCP-APIGW-API-KEY", clientSecret)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode items = objectMapper.readTree(response).path("items");
            if (!items.isArray() || items.isEmpty()) return null;
            JsonNode link = items.get(0).path("link");
            return link.getNodeType() == JsonNodeType.STRING ? link.stringValue() : null;
        } catch (Exception e) {
            log.warn("네이버 이미지 검색 실패 [query={}]: {}", query, e.getMessage());
            return null;
        }
    }
}

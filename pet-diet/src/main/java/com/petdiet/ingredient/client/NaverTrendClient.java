package com.petdiet.ingredient.client;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.node.JsonNodeType;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 네이버 데이터랩 검색어트렌드 API 클라이언트 - 키워드 그룹별 최근 검색 관심도 변화를 조회한다.
 * https://developers.naver.com/docs/serviceapi/datalab/search/search.md
 * naver-search.* 설정(NaverShoppingClient와 동일한 앱/키)을 그대로 사용한다.
 */
@Slf4j
@Component
public class NaverTrendClient {

    /** 데이터랩 API는 한 번의 요청에 최대 5개 키워드 그룹까지만 허용한다 */
    private static final int MAX_GROUPS_PER_REQUEST = 5;
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private final WebClient webClient;
    private final String clientId;
    private final String clientSecret;
    private final ObjectMapper objectMapper;

    public NaverTrendClient(
            @Value("${naver-search.base-url}") String baseUrl,
            @Value("${naver-search.client-id:}") String clientId,
            @Value("${naver-search.client-secret:}") String clientSecret,
            ObjectMapper objectMapper) {
        this.webClient = WebClient.builder().baseUrl(baseUrl).build();
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.objectMapper = objectMapper;
    }

    public record KeywordGroup(String groupName, List<String> keywords) {}

    /** 그룹명 -> (최근 4주 평균 검색 지수, 그 이전 4주 대비 증감률 %) */
    public record TrendScore(double recentAvg, double growthPercent) {}

    public Map<String, TrendScore> getTrendScores(List<KeywordGroup> groups) {
        if (clientId == null || clientId.isBlank() || clientSecret == null || clientSecret.isBlank()) {
            log.info("naver datalab api key not configured, skipping trend lookup");
            return Map.of();
        }
        Map<String, TrendScore> result = new LinkedHashMap<>();
        for (int i = 0; i < groups.size(); i += MAX_GROUPS_PER_REQUEST) {
            List<KeywordGroup> chunk = groups.subList(i, Math.min(i + MAX_GROUPS_PER_REQUEST, groups.size()));
            result.putAll(fetchChunk(chunk));
        }
        return result;
    }

    private Map<String, TrendScore> fetchChunk(List<KeywordGroup> chunk) {
        try {
            LocalDate end = LocalDate.now();
            LocalDate start = end.minusWeeks(16);

            List<Map<String, Object>> keywordGroups = chunk.stream()
                    .map(g -> Map.<String, Object>of("groupName", g.groupName(), "keywords", g.keywords()))
                    .toList();
            Map<String, Object> body = Map.of(
                    "startDate", start.format(DATE_FORMAT),
                    "endDate", end.format(DATE_FORMAT),
                    "timeUnit", "week",
                    "keywordGroups", keywordGroups
            );

            String response = webClient.post()
                    .uri("/v1/datalab/search")
                    .header("X-Naver-Client-Id", clientId)
                    .header("X-Naver-Client-Secret", clientSecret)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(response);
            JsonNode results = root.path("results");

            Map<String, TrendScore> scores = new LinkedHashMap<>();
            for (JsonNode groupResult : results) {
                String title = str(groupResult.path("title"));
                if (title == null) continue;

                List<Double> ratios = new ArrayList<>();
                for (JsonNode point : groupResult.path("data")) {
                    if (point.path("ratio").getNodeType() == JsonNodeType.NUMBER) {
                        ratios.add(point.path("ratio").doubleValue());
                    }
                }
                // 마지막 주는 집계 중일 수 있어 완결된 주차만 사용
                if (!ratios.isEmpty()) ratios.remove(ratios.size() - 1);
                if (ratios.size() < 8) continue;

                List<Double> recent4 = ratios.subList(ratios.size() - 4, ratios.size());
                List<Double> prior4 = ratios.subList(ratios.size() - 8, ratios.size() - 4);
                double recentAvg = average(recent4);
                double priorAvg = average(prior4);
                double growth = priorAvg > 0 ? (recentAvg - priorAvg) / priorAvg * 100 : 0;

                scores.put(title, new TrendScore(recentAvg, growth));
            }
            return scores;

        } catch (Exception e) {
            log.warn("네이버 데이터랩 트렌드 조회 실패: {}", e.getMessage());
            return Map.of();
        }
    }

    private static double average(List<Double> values) {
        return values.stream().mapToDouble(Double::doubleValue).average().orElse(0);
    }

    private static String str(JsonNode node) {
        return node.getNodeType() == JsonNodeType.STRING ? node.stringValue() : null;
    }
}

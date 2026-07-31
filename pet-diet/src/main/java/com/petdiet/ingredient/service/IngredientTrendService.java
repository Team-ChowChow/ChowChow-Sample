package com.petdiet.ingredient.service;

import com.petdiet.ingredient.client.NaverTrendClient;
import com.petdiet.ingredient.client.NaverTrendClient.KeywordGroup;
import com.petdiet.ingredient.client.NaverTrendClient.TrendScore;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicReference;

/**
 * 반려동물 식재료 검색 트렌드를 매일 1회 갱신해 캐싱한다.
 * AI 레시피 생성 프롬프트에서 "요즘 뜨는 재료"를 참고할 때 사용.
 */
@Slf4j
@Service
public class IngredientTrendService {

    /** 요즘 뜨는 반려동물 식재료 후보군 - 그룹당 대표 검색어 2개 */
    private static final List<KeywordGroup> CANDIDATE_GROUPS = List.of(
            new KeywordGroup("연어", List.of("강아지 연어", "연어 간식")),
            new KeywordGroup("닭가슴살", List.of("강아지 닭가슴살", "닭가슴살 간식")),
            new KeywordGroup("브로콜리", List.of("강아지 브로콜리", "브로콜리 간식")),
            new KeywordGroup("계란", List.of("강아지 계란", "계란 간식")),
            new KeywordGroup("홍합", List.of("강아지 홍합", "초록입홍합")),
            new KeywordGroup("소고기", List.of("강아지 소고기 간식", "소고기 수제간식")),
            new KeywordGroup("오리고기", List.of("강아지 오리고기", "오리고기 간식")),
            new KeywordGroup("고구마", List.of("강아지 고구마", "고구마 간식")),
            new KeywordGroup("단호박", List.of("강아지 단호박", "단호박 간식")),
            new KeywordGroup("새우", List.of("강아지 새우", "새우 간식"))
    );

    /** 절대 검색량이 이 값 미만이면 표본이 너무 작아 증감률을 신뢰하지 않음 */
    private static final double MIN_VOLUME = 10.0;

    /** API 미설정/실패 시 사용할 대체 목록 */
    private static final List<String> FALLBACK = List.of("단호박", "새우", "오리고기", "연어", "계란");

    private final NaverTrendClient naverTrendClient;
    private final AtomicReference<List<String>> cachedTrending = new AtomicReference<>(FALLBACK);
    private volatile LocalDate cacheDate = null;

    public IngredientTrendService(NaverTrendClient naverTrendClient) {
        this.naverTrendClient = naverTrendClient;
    }

    @PostConstruct
    public void init() {
        CompletableFuture.runAsync(this::refresh);
    }

    // 매일 오전 5시에 캐시 갱신 (오늘의 팁 갱신보다 앞서 실행)
    @Scheduled(cron = "0 0 5 * * *")
    public void scheduledRefresh() {
        CompletableFuture.runAsync(this::refresh);
    }

    public List<String> getTopTrendingIngredients(int limit) {
        LocalDate today = LocalDate.now();
        if (cacheDate == null || !today.equals(cacheDate)) {
            CompletableFuture.runAsync(this::refresh);
        }
        List<String> cached = cachedTrending.get();
        return cached.size() <= limit ? cached : cached.subList(0, limit);
    }

    private void refresh() {
        LocalDate today = LocalDate.now();
        if (today.equals(cacheDate)) return;
        try {
            Map<String, TrendScore> scores = naverTrendClient.getTrendScores(CANDIDATE_GROUPS);
            List<String> ranked = scores.entrySet().stream()
                    .filter(e -> e.getValue().recentAvg() >= MIN_VOLUME)
                    .sorted(Comparator.comparingDouble((Map.Entry<String, TrendScore> e) -> e.getValue().growthPercent()).reversed())
                    .map(Map.Entry::getKey)
                    .toList();

            if (!ranked.isEmpty()) {
                cachedTrending.set(ranked);
                cacheDate = today;
                log.info("식재료 트렌드 갱신 완료: {}", ranked);
            } else {
                log.info("식재료 트렌드 조회 결과 없음, 기존 캐시 유지");
            }
        } catch (Exception e) {
            log.warn("식재료 트렌드 갱신 실패, 기존 캐시 유지", e);
        }
    }
}

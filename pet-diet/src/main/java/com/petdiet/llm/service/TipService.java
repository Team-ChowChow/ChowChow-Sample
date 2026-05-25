package com.petdiet.llm.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.llm.dto.TipResponse;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicReference;

@Slf4j
@Service
public class TipService {

    private static final TipResponse FALLBACK = TipResponse.builder()
            .tip("반려동물에게 신선한 물을 매일 충분히 제공하세요.")
            .detail("물은 반려동물의 소화, 체온 조절, 신진대사에 필수적입니다. 하루에 한 번 이상 신선한 물로 교체하고 그릇도 매일 세척하는 것이 좋습니다.")
            .build();

    private final ObjectMapper objectMapper;
    private final WebClient webClient;
    private final String model;

    private final AtomicReference<TipResponse> cachedTip = new AtomicReference<>(FALLBACK);
    private volatile LocalDate cacheDate = null;

    public TipService(
            ObjectMapper objectMapper,
            @Value("${openai.api-key}") String apiKey,
            @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
            @Value("${openai.model:gpt-4o}") String model) {
        this.objectMapper = objectMapper;
        this.model = model;
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    @PostConstruct
    public void init() {
        // 서버 시작 시 백그라운드에서 팁 미리 생성 (요청 스레드 블록 안 함)
        CompletableFuture.runAsync(this::refreshTip);
    }

    // 매일 오전 6시에 캐시 갱신
    @Scheduled(cron = "0 0 6 * * *")
    public void scheduledRefresh() {
        CompletableFuture.runAsync(this::refreshTip);
    }

    public TipResponse getDailyTip() {
        LocalDate today = LocalDate.now();
        if (cacheDate == null || !today.equals(cacheDate)) {
            // 캐시가 오래됐으면 백그라운드 갱신 예약 후 현재 캐시 즉시 반환
            CompletableFuture.runAsync(this::refreshTip);
        }
        return cachedTip.get();
    }

    private void refreshTip() {
        LocalDate today = LocalDate.now();
        if (today.equals(cacheDate)) return; // 이미 오늘 갱신됨
        try {
            TipResponse fresh = fetchTipFromOpenAI();
            cachedTip.set(fresh);
            cacheDate = today;
            log.info("오늘의 팁 갱신 완료");
        } catch (Exception e) {
            log.error("오늘의 팁 갱신 실패", e);
        }
    }

    private TipResponse fetchTipFromOpenAI() {
        String prompt = """
                반려동물(강아지/고양이) 보호자를 위한 오늘의 건강/식단 팁을 한 가지 알려주세요.
                다음 JSON 형식으로만 응답하세요 (다른 텍스트 없이):
                {
                  "tip": "한 문장 요약 팁 (30자 이내)",
                  "detail": "3~5문장의 상세 설명"
                }
                """;

        Map<String, Object> body = Map.of(
                "model", model,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "max_tokens", 300,
                "temperature", 0.8
        );

        String responseBody = webClient.post()
                .uri("/v1/chat/completions")
                .bodyValue(body)
                .retrieve()
                .bodyToMono(String.class)
                .block();

        JsonNode root = objectMapper.readTree(responseBody);
        String content = root.path("choices").get(0).path("message").path("content").stringValue();

        int start = content.indexOf('{');
        int end = content.lastIndexOf('}');
        if (start >= 0 && end > start) {
            content = content.substring(start, end + 1);
        }

        JsonNode tipNode = objectMapper.readTree(content);
        return TipResponse.builder()
                .tip(tipNode.path("tip").stringValue())
                .detail(tipNode.path("detail").stringValue())
                .build();
    }
}

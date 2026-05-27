package com.petdiet.master.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.master.entity.Breed;
import com.petdiet.master.repository.BreedRepository;
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
public class BreedEnrichService {

    private static final int TRANSLATE_BATCH = 40;

    private final BreedRepository breedRepository;
    private final ObjectMapper objectMapper;
    private final WebClient openAiClient;
    private final String openAiModel;

    public BreedEnrichService(
            BreedRepository breedRepository,
            ObjectMapper objectMapper,
            @Value("${openai.api-key}") String apiKey,
            @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
            @Value("${openai.model:gpt-4o}") String model) {
        this.breedRepository = breedRepository;
        this.objectMapper = objectMapper;
        this.openAiModel = model;
        this.openAiClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    @Transactional
    public int translateToKorean(int batchSize) {
        int total = 0;
        int pages = (int) Math.ceil((double) batchSize / TRANSLATE_BATCH);

        for (int page = 0; page < pages; page++) {
            List<Breed> targets = breedRepository.findByBreedNameKoIsNull(PageRequest.of(0, TRANSLATE_BATCH));
            if (targets.isEmpty()) break;

            List<String> names = targets.stream().map(Breed::getBreedName).toList();
            Map<String, String> translations = callGptTranslate(names);

            for (Breed breed : targets) {
                String ko = translations.get(breed.getBreedName());
                if (ko != null && !ko.isBlank()) {
                    breed.updateKoreanName(ko);
                    breedRepository.save(breed);
                    total++;
                }
            }
            log.info("품종 한글 번역 진행: {}건 완료 (누적 {}건)", targets.size(), total);
        }
        return total;
    }

    private Map<String, String> callGptTranslate(List<String> names) {
        String nameList = String.join("\n", names);
        String prompt = """
                다음 영어 반려동물 품종 이름들을 한국어로 번역해주세요.
                공식 한국어 품종명이 있으면 그것을, 없으면 발음 그대로 표기해주세요.
                JSON 형식으로만 응답하세요. 형식: {"translations": {"영어이름": "한국어이름", ...}}
                번역할 품종:
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
            log.error("GPT 품종 번역 실패: {}", e.getMessage());
            return Map.of();
        }
    }
}

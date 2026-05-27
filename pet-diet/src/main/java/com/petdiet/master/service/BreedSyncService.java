package com.petdiet.master.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class BreedSyncService {

    private static final String UPSERT_SQL =
            "INSERT INTO \"Breeds\" (\"petType\", \"breedName\", \"breedDescription\") VALUES (?, ?, ?)" +
            " ON CONFLICT (\"breedName\") DO UPDATE SET" +
            " \"petType\" = EXCLUDED.\"petType\"," +
            " \"breedDescription\" = EXCLUDED.\"breedDescription\"";

    private final JdbcTemplate jdbc;
    private final ObjectMapper objectMapper;
    private final WebClient dogClient;
    private final WebClient catClient;

    public BreedSyncService(
            JdbcTemplate jdbc,
            ObjectMapper objectMapper,
            @Value("${breed.dog-api-key}") String dogApiKey,
            @Value("${breed.cat-api-key}") String catApiKey) {
        this.jdbc = jdbc;
        this.objectMapper = objectMapper;
        this.dogClient = WebClient.builder()
                .baseUrl("https://api.thedogapi.com/v1")
                .defaultHeader("x-api-key", dogApiKey)
                .codecs(c -> c.defaultCodecs().maxInMemorySize(4 * 1024 * 1024))
                .build();
        this.catClient = WebClient.builder()
                .baseUrl("https://api.thecatapi.com/v1")
                .defaultHeader("x-api-key", catApiKey)
                .codecs(c -> c.defaultCodecs().maxInMemorySize(4 * 1024 * 1024))
                .build();
    }

    public int syncIfEmpty() {
        Long count = jdbc.queryForObject("SELECT COUNT(*) FROM \"Breeds\"", Long.class);
        if (count != null && count > 0) {
            log.info("Breeds 데이터 존재({}) — 동기화 생략", count);
            return 0;
        }
        return syncAll();
    }

    public int syncAll() {
        int dogs = syncDogs();
        int cats = syncCats();
        return dogs + cats;
    }

    public int syncForce() {
        jdbc.update("DELETE FROM \"Breeds\"");
        log.info("Breeds 기존 데이터 삭제 완료");
        return syncAll();
    }

    public int syncDogs() {
        List<Object[]> rows = fetchBreedRows(dogClient, "DOG");
        jdbc.batchUpdate(UPSERT_SQL, rows);
        log.info("Dog breeds upsert: {}건", rows.size());
        return rows.size();
    }

    public int syncCats() {
        List<Object[]> rows = fetchBreedRows(catClient, "CAT");
        jdbc.batchUpdate(UPSERT_SQL, rows);
        log.info("Cat breeds upsert: {}건", rows.size());
        return rows.size();
    }

    private List<Object[]> fetchBreedRows(WebClient client, String petType) {
        List<Object[]> rows = new ArrayList<>();
        try {
            String raw = client.get()
                    .uri("/breeds?limit=500")
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(30))
                    .block();

            JsonNode nodes = objectMapper.readTree(raw);
            for (JsonNode node : nodes) {
                String name = textOrNull(node, "name");
                if (name == null) continue;

                // 이미지 필드(image, reference_image_id)는 읽지 않음
                String description = textOrNull(node, "description");
                if (description == null) {
                    description = textOrNull(node, "temperament");
                }

                rows.add(new Object[]{ petType, name, description });
            }
        } catch (Exception e) {
            log.error("{} breed API 호출 실패", petType, e);
            throw new RuntimeException(petType + " breed 동기화 중 오류 발생", e);
        }
        return rows;
    }

    private String textOrNull(JsonNode node, String field) {
        String val = node.path(field).stringValue();
        return (val != null && !val.isBlank()) ? val : null;
    }
}

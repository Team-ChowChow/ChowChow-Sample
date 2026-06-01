package com.petdiet.config;

import com.petdiet.master.service.BreedSyncService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements ApplicationRunner {

    private final JdbcTemplate jdbc;
    private final BreedSyncService breedSyncService;

    @Override
    public void run(ApplicationArguments args) {
        log.info("마스터 데이터 초기화 시작");
        migrateBreedColumns();
        loadAllergies();
        loadDiseases();
        loadIngredients();
        loadBreeds();
        loadAllergyIngredients();
        loadMenus();
        loadRecipeTags();
        loadRecipesAllCsv();
        log.info("마스터 데이터 초기화 완료");
    }

    private void loadAllergies() {
        List<Object[]> rows = new ArrayList<>();
        for (CSVRecord r : readCsv("db/csv/allergies.csv")) {
            rows.add(new Object[]{ r.get("allergyName"), r.get("allergyDescription") });
        }
        jdbc.batchUpdate(
            "INSERT INTO \"Allergies\" (\"allergyName\", \"allergyDescription\") VALUES (?, ?)" +
            " ON CONFLICT (\"allergyName\") DO UPDATE SET \"allergyDescription\" = EXCLUDED.\"allergyDescription\"",
            rows
        );
        log.info("Allergies upsert: {}건", rows.size());
    }

    private void loadDiseases() {
        List<Object[]> rows = new ArrayList<>();
        for (CSVRecord r : readCsv("db/csv/diseases.csv")) {
            rows.add(new Object[]{ r.get("diseaseName"), r.get("diseaseDescription") });
        }
        jdbc.batchUpdate(
            "INSERT INTO \"Diseases\" (\"diseaseName\", \"diseaseDescription\") VALUES (?, ?)" +
            " ON CONFLICT (\"diseaseName\") DO UPDATE SET \"diseaseDescription\" = EXCLUDED.\"diseaseDescription\"",
            rows
        );
        log.info("Diseases upsert: {}건", rows.size());
    }

    private void loadIngredients() {
        if (count("Ingredients") > 0) return;
        List<Object[]> rows = new ArrayList<>();
        for (CSVRecord r : readCsv("db/csv/ingredients.csv")) {
            rows.add(new Object[]{
                r.get("ingredientName"),
                r.get("ingredientDescription"),
                r.get("ingredientCategory"),
                r.get("petType")
            });
        }
        jdbc.batchUpdate(
            "INSERT INTO \"Ingredients\" (\"ingredientName\", \"ingredientDescription\", \"ingredientCategory\", \"petType\") VALUES (?, ?, ?, ?) ON CONFLICT DO NOTHING",
            rows
        );
        log.info("Ingredients 삽입: {}건", rows.size());
    }

    private void migrateBreedColumns() {
        jdbc.execute("ALTER TABLE \"Breeds\" ADD COLUMN IF NOT EXISTS \"breedNameKo\" VARCHAR(100)");
    }

    private void loadBreeds() {
        int synced = breedSyncService.syncIfEmpty();
        if (synced > 0) log.info("Breeds API 동기화: {}건", synced);
    }

    private void loadAllergyIngredients() {
        if (count("AllergyIngredients") > 0) return;
        List<Object[]> rows = new ArrayList<>();
        for (CSVRecord r : readCsv("db/csv/allergy_ingredients.csv")) {
            rows.add(new Object[]{ r.get("allergyName"), r.get("ingredientName") });
        }
        jdbc.batchUpdate("""
            INSERT INTO "AllergyIngredients" ("allergyId", "ingredientId")
            SELECT a."allergyId", i."ingredientId"
            FROM "Allergies" a, "Ingredients" i
            WHERE a."allergyName" = ? AND i."ingredientName" = ?
            ON CONFLICT DO NOTHING
            """,
            rows
        );
        log.info("AllergyIngredients 삽입: {}건", rows.size());
    }

    private void loadMenus() {
        List<Object[]> rows = new ArrayList<>();
        for (CSVRecord r : readCsv("db/csv/menus.csv")) {
            rows.add(new Object[]{
                r.get("menuName"),
                r.get("menuDescription"),
                r.get("petType"),
                r.get("menuCategory"),
                r.get("menuStatus")
            });
        }
        jdbc.batchUpdate(
            "INSERT INTO \"Menus\" (\"menuName\", \"menuDescription\", \"petType\", \"menuCategory\", \"menuStatus\") VALUES (?, ?, ?, ?, ?)" +
            " ON CONFLICT (\"menuName\") DO UPDATE SET \"menuDescription\" = EXCLUDED.\"menuDescription\", \"menuStatus\" = EXCLUDED.\"menuStatus\"",
            rows
        );
        log.info("Menus upsert: {}건", rows.size());
    }

    private void loadRecipeTags() {
        if (count("RecipeTags") > 0) return;
        List<Object[]> rows = new ArrayList<>();
        for (CSVRecord r : readCsv("db/csv/recipe_tags.csv")) {
            rows.add(new Object[]{ r.get("tagName"), r.get("tagType"), r.get("tagDescription") });
        }
        jdbc.batchUpdate(
            "INSERT INTO \"RecipeTags\" (\"tagName\", \"tagType\", \"tagDescription\") VALUES (?, ?, ?) ON CONFLICT DO NOTHING",
            rows
        );
        log.info("RecipeTags 삽입: {}건", rows.size());
    }

    private void loadRecipesAllCsv() {
        Long existing = jdbc.queryForObject(
            "SELECT COUNT(*) FROM \"Recipes\" WHERE \"userId\" IS NULL AND \"recipeTitle\" = '닭가슴살 야채 볶음밥'",
            Long.class
        );
        if (existing != null && existing > 0) {
            log.info("recipes_all.csv 레시피 이미 존재 - 스킵");
            return;
        }

        Map<String, List<CSVRecord>> byTable = new LinkedHashMap<>();
        for (CSVRecord r : readCsv("db/csv/recipes_all.csv")) {
            byTable.computeIfAbsent(r.get("source_table"), k -> new ArrayList<>()).add(r);
        }

        List<CSVRecord> recipeRows    = byTable.getOrDefault("recipes", List.of());
        List<CSVRecord> allTagRows    = byTable.getOrDefault("recipe_tags", List.of());

        Map<String, List<CSVRecord>> ingByRecipe  = groupBy(byTable.getOrDefault("recipe_ingredients", List.of()), "recipe_id");
        Map<String, List<CSVRecord>> stepByRecipe = groupBy(byTable.getOrDefault("recipe_steps", List.of()), "recipe_id");
        Map<String, CSVRecord>       nutByRecipe  = new HashMap<>();
        for (CSVRecord r : byTable.getOrDefault("recipe_nutrition", List.of())) {
            nutByRecipe.put(r.get("recipe_id"), r);
        }

        int inserted = 0;
        for (CSVRecord row : recipeRows) {
            String uuid        = row.get("id");
            String title       = row.get("title");
            String description = row.get("description");
            String petType     = "dog".equalsIgnoreCase(row.get("species")) ? "DOG" : "CAT";
            String category    = row.get("category");
            String menuName    = resolveMenuName(petType, category);
            String purpose     = buildPurpose(uuid, allTagRows);

            Integer menuId;
            try {
                menuId = jdbc.queryForObject("SELECT \"menuId\" FROM \"Menus\" WHERE \"menuName\" = ?", Integer.class, menuName);
            } catch (Exception e) {
                String fallback = "DOG".equals(petType) ? "강아지 기본 일반식" : "고양이 기본 일반식";
                menuId = jdbc.queryForObject("SELECT \"menuId\" FROM \"Menus\" WHERE \"menuName\" = ?", Integer.class, fallback);
            }

            Integer recipeDbId = jdbc.queryForObject(
                "INSERT INTO \"Recipes\" (\"menuId\", \"recipeTitle\", \"recipeDescription\", \"recipePurpose\", " +
                "\"isAiGenerated\", \"isPublic\", \"recipeStatus\") VALUES (?, ?, ?, ?, false, true, 'ACTIVE') RETURNING \"recipeId\"",
                Integer.class, menuId, title, description, purpose
            );

            for (CSVRecord ing : ingByRecipe.getOrDefault(uuid, List.of())) {
                String ingName = ing.get("name");
                String amount  = ing.get("amount");
                Integer ingredientId = null;
                try {
                    ingredientId = jdbc.queryForObject(
                        "SELECT \"ingredientId\" FROM \"Ingredients\" WHERE \"ingredientName\" = ?", Integer.class, ingName);
                } catch (Exception ignored) {}
                jdbc.update(
                    "INSERT INTO \"RecipeIngredients\" (\"recipeId\", \"ingredientId\", \"ingredientAmount\", \"ingredientUnit\", \"ingredientNote\") VALUES (?, ?, ?, ?, ?)",
                    recipeDbId, ingredientId,
                    amount.isBlank() ? null : new BigDecimal(amount),
                    ing.get("unit"), ingName
                );
            }

            for (CSVRecord step : stepByRecipe.getOrDefault(uuid, List.of())) {
                int stepNo = parseIntSafe(step.get("order_no"), 1);
                jdbc.update("INSERT INTO \"RecipeSteps\" (\"recipeId\", \"stepNumber\", \"stepDescription\") VALUES (?, ?, ?)",
                    recipeDbId, stepNo, step.get("description"));
            }

            CSVRecord nut = nutByRecipe.get(uuid);
            if (nut != null && !nut.get("calories_per_100g").isBlank()) {
                jdbc.update(
                    "INSERT INTO \"RecipeNutritionSummaries\" (\"recipeId\", \"totalCalories\", \"proteinG\", \"fatG\", \"carbohydrateG\") VALUES (?, ?, ?, ?, ?)",
                    recipeDbId,
                    new BigDecimal(nut.get("calories_per_100g")),
                    new BigDecimal(nut.get("protein_g")),
                    new BigDecimal(nut.get("fat_g")),
                    new BigDecimal(nut.get("carbs_g"))
                );
            }

            inserted++;
            log.info("레시피 등록: {}", title);
        }
        log.info("recipes_all.csv 레시피 등록 완료: {}건", inserted);
    }

    private Map<String, List<CSVRecord>> groupBy(List<CSVRecord> rows, String key) {
        Map<String, List<CSVRecord>> map = new LinkedHashMap<>();
        for (CSVRecord r : rows) map.computeIfAbsent(r.get(key), k -> new ArrayList<>()).add(r);
        return map;
    }

    private String resolveMenuName(String petType, String category) {
        boolean isDog = "DOG".equals(petType);
        if (category.contains("수분")) return isDog ? "강아지 기본 일반식" : "고양이 수분 보충식";
        if (category.contains("간식") || category.contains("디저트")) return isDog ? "강아지 수제 간식" : "고양이 수제 간식";
        return isDog ? "강아지 기본 일반식" : "고양이 기본 일반식";
    }

    private String buildPurpose(String recipeUuid, List<CSVRecord> tagRows) {
        return tagRows.stream()
            .filter(r -> recipeUuid.equals(r.get("recipe_id")) && "purpose".equals(r.get("tag_type")))
            .map(r -> r.get("tag_value"))
            .collect(Collectors.joining(", "));
    }

    private int parseIntSafe(String s, int defaultVal) {
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return defaultVal; }
    }

    private long count(String table) {
        Long n = jdbc.queryForObject("SELECT COUNT(*) FROM \"" + table + "\"", Long.class);
        return n == null ? 0 : n;
    }

    private Iterable<CSVRecord> readCsv(String path) {
        try {
            byte[] bytes = new ClassPathResource(path).getInputStream().readAllBytes();
            String content = new String(bytes, StandardCharsets.UTF_8);
            if (content.startsWith("﻿")) {
                content = content.substring(1);
            }
            return CSVFormat.DEFAULT.builder()
                .setHeader()
                .setSkipHeaderRecord(true)
                .setTrim(true)
                .build()
                .parse(new java.io.StringReader(content));
        } catch (Exception e) {
            throw new RuntimeException("CSV 읽기 실패: " + path, e);
        }
    }
}

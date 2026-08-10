package com.petdiet.recipe.service;

import com.petdiet.ingredient.entity.Ingredient;
import com.petdiet.ingredient.repository.IngredientRepository;
import com.petdiet.recipe.entity.Recipe;
import com.petdiet.recipe.entity.RecipeIngredient;
import com.petdiet.recipe.entity.RecipeNutritionSummary;
import com.petdiet.recipe.repository.RecipeNutritionSummaryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 레시피의 재료(g 환산)와 재료별 100g당 영양성분을 곱해 레시피 전체 영양 요약을 계산.
 */
@Service
@RequiredArgsConstructor
public class NutritionCalculationService {

    private final IngredientRepository ingredientRepository;
    private final RecipeNutritionSummaryRepository nutritionRepository;

    // ponytail: 통상적인 눈대중 환산값(재료마다 실제 밀도는 다름). 정밀도가 필요해지면 재료별 환산표로 교체.
    private static final Map<String, BigDecimal> UNIT_TO_GRAM = Map.ofEntries(
            Map.entry("g", BigDecimal.ONE),
            Map.entry("그램", BigDecimal.ONE),
            Map.entry("kg", BigDecimal.valueOf(1000)),
            Map.entry("ml", BigDecimal.ONE),
            Map.entry("l", BigDecimal.valueOf(1000)),
            Map.entry("리터", BigDecimal.valueOf(1000)),
            Map.entry("작은술", BigDecimal.valueOf(5)),
            Map.entry("티스푼", BigDecimal.valueOf(5)),
            Map.entry("큰술", BigDecimal.valueOf(15)),
            Map.entry("테이블스푼", BigDecimal.valueOf(15)),
            Map.entry("컵", BigDecimal.valueOf(200)),
            Map.entry("개", BigDecimal.valueOf(50)),
            Map.entry("장", BigDecimal.valueOf(30)),
            Map.entry("쪽", BigDecimal.valueOf(5))
    );
    private static final BigDecimal DEFAULT_GRAM_PER_UNIT = BigDecimal.ONE;

    @Transactional
    public void calculateAndSave(Recipe recipe) {
        var ingredients = recipe.getIngredients();
        if (ingredients == null || ingredients.isEmpty()) return;

        Map<Integer, Ingredient> byId = ingredientRepository.findAllById(
                        ingredients.stream().map(RecipeIngredient::getIngredientId).filter(Objects::nonNull).toList())
                .stream().collect(Collectors.toMap(Ingredient::getIngredientId, Function.identity()));

        BigDecimal totalWeight = BigDecimal.ZERO;
        BigDecimal calories = BigDecimal.ZERO;
        BigDecimal protein = BigDecimal.ZERO;
        BigDecimal fat = BigDecimal.ZERO;
        BigDecimal carb = BigDecimal.ZERO;

        for (RecipeIngredient ri : ingredients) {
            Ingredient ingredient = byId.get(ri.getIngredientId());
            if (ingredient == null || ingredient.getCaloriesPer100g() == null || ri.getIngredientAmount() == null) {
                continue;
            }
            BigDecimal grams = ri.getIngredientAmount().multiply(gramsPerUnit(ri.getIngredientUnit()));
            BigDecimal ratio = grams.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP);

            totalWeight = totalWeight.add(grams);
            calories = calories.add(ingredient.getCaloriesPer100g().multiply(ratio));
            protein = protein.add(nullToZero(ingredient.getProteinG()).multiply(ratio));
            fat = fat.add(nullToZero(ingredient.getFatG()).multiply(ratio));
            carb = carb.add(nullToZero(ingredient.getCarbohydrateG()).multiply(ratio));
        }

        if (totalWeight.compareTo(BigDecimal.ZERO) == 0) return;

        RecipeNutritionSummary.RecipeNutritionSummaryBuilder builder = nutritionRepository
                .findByRecipeRecipeId(recipe.getRecipeId())
                .map(RecipeNutritionSummary::toBuilder)
                .orElseGet(() -> RecipeNutritionSummary.builder().recipe(recipe));

        RecipeNutritionSummary summary = builder
                .totalWeight(scale(totalWeight, 2))
                .totalCalories(scale(calories, 2))
                .proteinG(scale(protein, 2))
                .fatG(scale(fat, 2))
                .carbohydrateG(scale(carb, 2))
                .build();

        nutritionRepository.save(summary);
    }

    private BigDecimal gramsPerUnit(String unit) {
        if (unit == null) return DEFAULT_GRAM_PER_UNIT;
        return UNIT_TO_GRAM.getOrDefault(unit.trim(), DEFAULT_GRAM_PER_UNIT);
    }

    private BigDecimal nullToZero(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }

    private BigDecimal scale(BigDecimal v, int digits) {
        return v.setScale(digits, RoundingMode.HALF_UP);
    }
}

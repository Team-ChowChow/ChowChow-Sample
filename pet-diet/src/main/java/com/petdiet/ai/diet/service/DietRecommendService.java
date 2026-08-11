package com.petdiet.ai.diet.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.ai.diet.dto.DietRecommendResponse;
import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.ingredient.repository.IngredientRepository;
import com.petdiet.ingredient.service.IngredientTrendService;
import com.petdiet.master.entity.Allergy;
import com.petdiet.master.entity.Breed;
import com.petdiet.master.entity.Disease;
import com.petdiet.master.repository.AllergyRepository;
import com.petdiet.master.repository.BreedRepository;
import com.petdiet.master.repository.DiseaseRepository;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import com.petdiet.recipe.entity.Recipe;
import com.petdiet.recipe.repository.RecipeRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

import static java.util.stream.Collectors.joining;

@Slf4j
@Service
public class DietRecommendService {

    /** 매번 다른 조리 방향을 시도하도록 유도해 결과가 뻔해지지 않게 함 */
    private static final List<String> STYLE_HINTS = List.of(
            "찜/스팀 요리", "구이", "수프/죽", "토핑(사료 위에 얹는 형태)", "볼/완자 형태", "샐러드(생/데침)", "그릴드/에어프라이어 조리"
    );

    /** 검색 화면의 인기 카테고리와 동일한 태그 - 매번 다른 컨셉을 유도 */
    private static final List<String> CONCEPT_HINTS = List.of(
            "고단백", "관절건강", "다이어트", "면역력강화", "알러지프리", "저지방", "피부모질개선"
    );

    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final AllergyRepository allergyRepository;
    private final DiseaseRepository diseaseRepository;
    private final BreedRepository breedRepository;
    private final RecipeRepository recipeRepository;
    private final IngredientRepository ingredientRepository;
    private final IngredientTrendService ingredientTrendService;
    private final ObjectMapper objectMapper;
    private final WebClient webClient;
    private final String model;
    private final int maxTokens;

    public DietRecommendService(
            UserRepository userRepository,
            UserPetRepository userPetRepository,
            AllergyRepository allergyRepository,
            DiseaseRepository diseaseRepository,
            BreedRepository breedRepository,
            RecipeRepository recipeRepository,
            IngredientRepository ingredientRepository,
            IngredientTrendService ingredientTrendService,
            ObjectMapper objectMapper,
            @Value("${openai.api-key}") String apiKey,
            @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
            @Value("${openai.model:gpt-4o}") String model,
            @Value("${openai.max-tokens:2048}") int maxTokens) {
        this.userRepository = userRepository;
        this.userPetRepository = userPetRepository;
        this.allergyRepository = allergyRepository;
        this.diseaseRepository = diseaseRepository;
        this.breedRepository = breedRepository;
        this.recipeRepository = recipeRepository;
        this.ingredientRepository = ingredientRepository;
        this.ingredientTrendService = ingredientTrendService;
        this.objectMapper = objectMapper;
        this.model = model;
        this.maxTokens = maxTokens;
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .build();
    }

    public record RecommendContext(User user, UserPet pet, DietRecommendResponse response) {}

    @Transactional(readOnly = true)
    public RecommendContext recommendWithContext(UUID authUuid, Integer petId, String userNotes) {
        User user = userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));

        UserPet pet = null;
        List<Allergy> allergies = List.of();
        List<Disease> diseases = List.of();
        Breed breed = null;

        if (petId != null) {
            pet = userPetRepository.findByPetIdAndUser(petId, user)
                    .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."));
            List<Integer> allergyIds = pet.getAllergies().stream().map(a -> a.getAllergyId()).toList();
            List<Integer> diseaseIds = pet.getDiseases().stream().map(d -> d.getDiseaseId()).toList();
            allergies = allergyRepository.findAllById(allergyIds);
            diseases = diseaseRepository.findAllById(diseaseIds);
            breed = (pet.getBreedId() != null) ? breedRepository.findById(pet.getBreedId()).orElse(null) : null;
        }

        List<String> recentTitles = (pet != null
                ? recipeRepository.findTop8ByPet_PetIdAndIsAiGeneratedTrueOrderByCreatedAtDesc(pet.getPetId())
                : recipeRepository.findTop8ByIsAiGeneratedTrueOrderByCreatedAtDesc())
                .stream().map(Recipe::getRecipeTitle).filter(t -> t != null && !t.isBlank()).toList();

        List<String> trendingIngredients = ingredientTrendService.getTopTrendingIngredients(5);
        List<String> toxicIngredients = findToxicIngredientNames(pet);

        String prompt = buildPrompt(pet, breed, allergies, diseases, userNotes, recentTitles, trendingIngredients, toxicIngredients);
        DietRecommendResponse response = callOpenAi(prompt);
        return new RecommendContext(user, pet, response);
    }

    @Transactional(readOnly = true)
    public DietRecommendResponse recommend(UUID authUuid, Integer petId, String userNotes) {
        return recommendWithContext(authUuid, petId, userNotes).response();
    }

    List<String> findToxicIngredientNames(UserPet pet) {
        boolean isDog = pet == null || "DOG".equalsIgnoreCase(pet.getPetType());
        boolean isCat = pet == null || "CAT".equalsIgnoreCase(pet.getPetType());
        return ingredientRepository.findByIsToxicToDogTrueOrIsToxicToCatTrue().stream()
                .filter(i -> (isDog && Boolean.TRUE.equals(i.getIsToxicToDog()))
                        || (isCat && Boolean.TRUE.equals(i.getIsToxicToCat())))
                .map(i -> {
                    String name = i.getIngredientNameKo() != null ? i.getIngredientNameKo() : i.getIngredientName();
                    return i.getToxicityNote() != null ? name + " (" + i.getToxicityNote() + ")" : name;
                })
                .toList();
    }

    String buildPrompt(UserPet pet, Breed breed,
                                List<Allergy> allergies, List<Disease> diseases,
                                String userNotes, List<String> recentTitles, List<String> trendingIngredients,
                                List<String> toxicIngredients) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 반려동물 영양 전문가이자 트렌디한 레시피 크리에이터입니다. ")
          .append("다음 반려동물 정보를 바탕으로 안전하면서도 사용자의 눈길을 끌 만큼 독특하고 매력적인 홈메이드 레시피를 추천해주세요.\n\n");

        if (pet != null) {
            int ageMonths = 0;
            if (pet.getPetBirthdate() != null) {
                LocalDate now = LocalDate.now();
                ageMonths = (now.getYear() - pet.getPetBirthdate().getYear()) * 12
                        + (now.getMonthValue() - pet.getPetBirthdate().getMonthValue());
            }
            sb.append("## 반려동물 정보\n");
            sb.append("- 종류: ").append(pet.getPetType()).append("\n");
            sb.append("- 이름: ").append(pet.getPetName()).append("\n");
            if (breed != null) {
                sb.append("- 품종: ").append(breed.getBreedName()).append("\n");
            }
            if (ageMonths > 0) {
                sb.append("- 나이: ").append(ageMonths / 12).append("년 ").append(ageMonths % 12).append("개월\n");
            }
            if (pet.getPetWeight() != null) {
                sb.append("- 체중: ").append(pet.getPetWeight()).append("kg\n");
            }
            if (pet.getIsNeutered() != null) {
                sb.append("- 중성화: ").append(pet.getIsNeutered() ? "예" : "아니오").append("\n");
            }
            if (!allergies.isEmpty()) {
                sb.append("- 알레르기 (해당 식재료 반드시 제외): ")
                  .append(allergies.stream().map(Allergy::getAllergyName).collect(joining(", ")))
                  .append("\n");
            }
            if (!diseases.isEmpty()) {
                sb.append("- 질환 및 식단 주의사항:\n");
                for (Disease d : diseases) {
                    sb.append("  * ").append(d.getDiseaseName());
                    if (d.getDiseaseDescription() != null) {
                        sb.append(": ").append(d.getDiseaseDescription());
                    }
                    sb.append("\n");
                }
            }
        } else {
            sb.append("## 반려동물 정보\n");
            sb.append("- 반려동물 정보 미등록 (일반적인 반려견/반려묘를 위한 건강식 추천)\n");
        }
        if (userNotes != null && !userNotes.isBlank()) {
            sb.append("- 사용자 요청: ").append(userNotes).append("\n");
        }

        if (!toxicIngredients.isEmpty()) {
            sb.append("\n## 절대 금지 재료 (독성 위험 - 어떤 경우에도 사용 금지)\n");
            for (String t : toxicIngredients) {
                sb.append("- ").append(t).append("\n");
            }
        }

        if (!trendingIngredients.isEmpty()) {
            sb.append("\n## 요즘 뜨는 식재료 (네이버 검색 트렌드 기준 최근 상승세)\n");
            sb.append("- ").append(String.join(", ", trendingIngredients)).append("\n");
            sb.append("- 알레르기/질환에 문제가 없다면 이 중 최소 1개를 주재료 또는 부재료로 활용해 트렌디한 느낌을 주세요. ")
              .append("단, 안전이 우선이므로 맞지 않으면 억지로 넣지 마세요.\n");
        }

        if (!recentTitles.isEmpty()) {
            sb.append("\n## 중복 방지 - 이미 생성된 레시피 (아래와 겹치지 않는 새로운 컨셉으로 작성)\n");
            for (String title : recentTitles) {
                sb.append("- ").append(title).append("\n");
            }
            sb.append("- 위 목록과 주재료 조합, 조리 방식, 이름이 겹치지 않도록 다른 방향으로 만들어주세요.\n");
        }

        sb.append("\n## 이번 레시피의 조리 스타일 힌트\n");
        sb.append("- ").append(STYLE_HINTS.get(ThreadLocalRandom.current().nextInt(STYLE_HINTS.size())))
          .append(" 스타일을 우선 고려해보되, 반려동물 상태에 맞지 않으면 다른 방식을 선택하세요.\n");
        sb.append("- 컨셉: ").append(CONCEPT_HINTS.get(ThreadLocalRandom.current().nextInt(CONCEPT_HINTS.size())))
          .append(" 관점을 참고해 재료/설명을 구성해보세요(맞지 않으면 무시).\n");

        sb.append("\n## 응답 형식 (JSON만 반환, 마크다운 코드블록 없이)\n");
        sb.append("""
                {
                  "title": "레시피 이름 (반드시 '주재료 + 요리방식' 형태로 작성. 예: 닭가슴살 채소찜, 연어 현미죽, 소고기 호박볶음. 추상적 표현 금지)",
                  "description": "식단 설명 (1~2줄)",
                  "ingredients": [
                    {"name": "재료명", "amount": "용량"}
                  ],
                  "steps": ["조리 단계 1", "조리 단계 2"],
                  "feedingAmount": "하루 급여량 안내",
                  "warnings": ["주의사항 1", "주의사항 2"]
                }
                """);
        return sb.toString();
    }

    private DietRecommendResponse callOpenAi(String prompt) {
        Map<String, Object> body = Map.of(
                "model", model,
                "max_tokens", maxTokens,
                "temperature", 1.1,
                "messages", List.of(Map.of("role", "user", "content", prompt)),
                "response_format", Map.of("type", "json_object")
        );

        try {
            String responseBody = webClient.post()
                    .uri("/v1/chat/completions")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

            JsonNode root = objectMapper.readTree(responseBody);
            String content = root.path("choices").get(0).path("message").path("content").stringValue();
            return objectMapper.readValue(content, DietRecommendResponse.class);
        } catch (Exception e) {
            log.error("OpenAI 식단 추천 API 호출 실패", e);
            throw new RuntimeException("AI 식단 추천 중 오류가 발생했습니다.", e);
        }
    }
}

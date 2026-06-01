package com.petdiet.ai.image.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.ai.image.dto.ImageGenerateResponse;
import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.common.service.SupabaseStorageService;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class ImageGenerateService {

    private static final String FAL_BASE_URL = "https://fal.run";

    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final ObjectMapper objectMapper;
    private final SupabaseStorageService supabaseStorageService;
    private final WebClient webClient;
    private final String recipeImageModel;
    private final String characterImageModel;

    public ImageGenerateService(
            UserRepository userRepository,
            UserPetRepository userPetRepository,
            ObjectMapper objectMapper,
            SupabaseStorageService supabaseStorageService,
            @Value("${fal.api-key}") String apiKey,
            @Value("${fal.recipe-image-model:fal-ai/flux-pro/v1.1}") String recipeImageModel,
            @Value("${fal.character-image-model:fal-ai/flux/dev/image-to-image}") String characterImageModel) {
        this.userRepository = userRepository;
        this.userPetRepository = userPetRepository;
        this.objectMapper = objectMapper;
        this.supabaseStorageService = supabaseStorageService;
        this.recipeImageModel = recipeImageModel;
        this.characterImageModel = characterImageModel;
        this.webClient = WebClient.builder()
                .baseUrl(FAL_BASE_URL)
                .defaultHeader("Authorization", "Key " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .codecs(c -> c.defaultCodecs().maxInMemorySize(16 * 1024 * 1024))
                .build();
    }

    public ImageGenerateResponse generateCharacterImage(UUID authUuid, Integer petId, String style) {
        User user = userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
        UserPet pet = userPetRepository.findByPetIdAndUser(petId, user)
                .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."));

        String petImageUrl = pet.getPetProfileImg();
        if (petImageUrl == null || petImageUrl.isBlank()) {
            throw new IllegalStateException("반려동물 프로필 이미지가 등록되어 있지 않습니다.");
        }

        String prompt = buildCharacterPrompt(pet, style);
        String characterUrl = callFalImageToImage(petImageUrl, prompt);
        String noBgUrl = callFalRemoveBackground(characterUrl);
        return ImageGenerateResponse.builder()
                .imageUrl(supabaseStorageService.uploadCharacterImageFromUrl(noBgUrl))
                .build();
    }

    public ImageGenerateResponse generateRecipeImage(String recipeName, List<String> ingredients, String description) {
        String prompt = buildRecipePrompt(recipeName, ingredients, description);
        String imageUrl = callFalTextToImage(prompt);
        return ImageGenerateResponse.builder()
                .imageUrl(supabaseStorageService.uploadRecipeImageFromUrl(imageUrl))
                .build();
    }

    public ImageGenerateResponse generateStepImage(String stepDescription, String recipeName, int stepNumber) {
        String prompt = String.format(
                "Step %d of preparing homemade pet food '%s': %s. " +
                "Close-up food preparation photo, clean kitchen surface, natural soft lighting, " +
                "shallow depth of field, 8K DSLR quality, sharp focus, professional cooking photography, no text.",
                stepNumber, recipeName, stepDescription
        );
        String imageUrl = callFalTextToImage(prompt);
        return ImageGenerateResponse.builder()
                .imageUrl(supabaseStorageService.uploadRecipeImageFromUrl(imageUrl))
                .build();
    }

    private String buildCharacterPrompt(UserPet pet, String style) {
        String styleDesc = (style != null && !style.isBlank()) ? style : "cute chibi anime character";
        return String.format(
                "Transform this %s named %s into a high quality %s illustration. " +
                "Preserve the exact fur color, markings, and facial features of the original pet. " +
                "Expressive eyes, clean outlines, vibrant colors, soft shading, white background. " +
                "Professional digital art, masterpiece quality, detailed fur texture, adorable expression.",
                pet.getPetType().toLowerCase(), pet.getPetName(), styleDesc
        );
    }

    private String buildCharacterNegativePrompt() {
        return "photograph, photo, realistic, raw photo, DSLR, " +
               "scary, horror, creepy, uncanny valley, disturbing, aggressive, " +
               "deformed, distorted, mutated, extra eyes, disfigured, " +
               "ugly, blurry, noise, low quality, bad anatomy";
    }

    private String buildRecipePrompt(String recipeName, List<String> ingredients, String description) {
        StringBuilder sb = new StringBuilder();
        sb.append("A real photograph of homemade pet food '").append(recipeName).append("'");
        if (ingredients != null && !ingredients.isEmpty()) {
            sb.append(", made with ").append(String.join(", ", ingredients));
        }
        if (description != null && !description.isBlank()) {
            sb.append(". ").append(description);
        }
        sb.append(". Shot on a worn wooden kitchen table, natural window light from the side, " +
                  "85mm f/2.0 lens, slight bokeh background, casually arranged on a simple ceramic bowl, " +
                  "realistic textures, natural color grading, photo taken by home cook, " +
                  "authentic homemade look, no artificial studio lighting, no text, no watermark.");
        return sb.toString();
    }

    private String callFalTextToImage(String prompt) {
        Map<String, Object> body = new HashMap<>();
        body.put("prompt", prompt);
        body.put("image_size", "square_hd");
        body.put("num_images", 1);
        body.put("guidance_scale", 3.5);
        body.put("num_inference_steps", 35);
        return callFal("/" + recipeImageModel, body, "images");
    }

    private String callFalImageToImage(String imageUrl, String prompt) {
        Map<String, Object> body = new HashMap<>();
        body.put("image_url", imageUrl);
        body.put("prompt", prompt);
        body.put("negative_prompt", buildCharacterNegativePrompt());
        body.put("strength", 0.65);
        body.put("image_size", "square_hd");
        body.put("num_images", 1);
        body.put("guidance_scale", 8.0);
        body.put("num_inference_steps", 40);
        return callFal("/" + characterImageModel, body, "images");
    }

    private String callFalRemoveBackground(String imageUrl) {
        Map<String, Object> body = new HashMap<>();
        body.put("image_url", imageUrl);
        body.put("model", "General Use (Light)");
        return callFal("/fal-ai/birefnet", body, "image");
    }

    private String callFal(String path, Map<String, Object> body, String imageField) {
        try {
            String responseBody = webClient.post()
                    .uri(path)
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(120))
                    .block();

            JsonNode root = objectMapper.readTree(responseBody);
            // "images":[{"url":"..."}] or "image":{"url":"..."}
            JsonNode node = root.path(imageField);
            if (node.isArray()) {
                return node.get(0).path("url").stringValue();
            } else {
                return node.path("url").stringValue();
            }
        } catch (Exception e) {
            log.error("fal.ai API 호출 실패 [path={}]", path, e);
            throw new RuntimeException("AI 이미지 생성 중 오류가 발생했습니다.", e);
        }
    }
}

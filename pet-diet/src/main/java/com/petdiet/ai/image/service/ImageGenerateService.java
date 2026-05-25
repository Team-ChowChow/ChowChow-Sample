package com.petdiet.ai.image.service;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.petdiet.ai.image.dto.ImageGenerateResponse;
import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.common.service.SupabaseStorageService;
import com.petdiet.pet.entity.UserPet;
import com.petdiet.pet.repository.UserPetRepository;
import io.netty.channel.ChannelOption;
import io.netty.handler.timeout.ReadTimeoutHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.netty.http.client.HttpClient;

import java.time.Duration;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
public class ImageGenerateService {

    private final UserRepository userRepository;
    private final UserPetRepository userPetRepository;
    private final ObjectMapper objectMapper;
    private final SupabaseStorageService supabaseStorageService;
    private final WebClient webClient;
    private final String imageModel;
    private final String imageSize;
    private final String imageQuality;

    public ImageGenerateService(
            UserRepository userRepository,
            UserPetRepository userPetRepository,
            ObjectMapper objectMapper,
            SupabaseStorageService supabaseStorageService,
            @Value("${openai.api-key}") String apiKey,
            @Value("${openai.base-url:https://api.openai.com}") String baseUrl,
            @Value("${openai.image-model:gpt-image-1}") String imageModel,
            @Value("${openai.image-size:1024x1024}") String imageSize,
            @Value("${openai.image-quality:medium}") String imageQuality) {
        this.userRepository = userRepository;
        this.userPetRepository = userPetRepository;
        this.objectMapper = objectMapper;
        this.supabaseStorageService = supabaseStorageService;
        this.imageModel = imageModel;
        this.imageSize = imageSize;
        this.imageQuality = imageQuality;
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, 10_000)
                .doOnConnected(conn -> conn.addHandlerLast(
                        new ReadTimeoutHandler(120, TimeUnit.SECONDS)));

        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader("Authorization", "Bearer " + apiKey)
                .defaultHeader("Content-Type", "application/json")
                .codecs(c -> c.defaultCodecs().maxInMemorySize(16 * 1024 * 1024)) // 16MB (b64 이미지 수용)
                .build();
    }

    public ImageGenerateResponse generateCharacterImage(UUID authUuid, Integer petId, String style) {
        User user = userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
        UserPet pet = userPetRepository.findByPetIdAndUser(petId, user)
                .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다."));

        return ImageGenerateResponse.builder()
                .imageUrl(callDallE(buildCharacterPrompt(pet, style)))
                .build();
    }

    public ImageGenerateResponse generateRecipeImage(String recipeName, List<String> ingredients, String description) {
        return ImageGenerateResponse.builder()
                .imageUrl(callDallE(buildRecipePrompt(recipeName, ingredients, description)))
                .build();
    }

    public ImageGenerateResponse generateStepImage(String stepDescription, String recipeName, int stepNumber) {
        String prompt = String.format(
                "Step %d of preparing homemade pet food '%s': %s. " +
                "Close-up food preparation photo, clear and simple, natural lighting, white background, high quality.",
                stepNumber, recipeName, stepDescription
        );
        return ImageGenerateResponse.builder()
                .imageUrl(callDallE(prompt))
                .build();
    }

    private String buildCharacterPrompt(UserPet pet, String style) {
        String styleDesc = (style != null && !style.isBlank()) ? style : "cute cartoon chibi";
        return String.format(
                "A %s illustration of a %s named %s as a %s character. " +
                "The image should be vibrant, friendly, and suitable for a pet care app. " +
                "White background, high quality, digital art style.",
                styleDesc, pet.getPetType(), pet.getPetName(), styleDesc
        );
    }

    private String buildRecipePrompt(String recipeName, List<String> ingredients, String description) {
        StringBuilder sb = new StringBuilder();
        sb.append("A beautiful food photography style image of a homemade pet food dish called '")
                .append(recipeName).append("'");
        if (ingredients != null && !ingredients.isEmpty()) {
            sb.append(", made with ").append(String.join(", ", ingredients));
        }
        if (description != null && !description.isBlank()) {
            sb.append(". ").append(description);
        }
        sb.append(". Clean white plate, natural lighting, top-down view, high quality food photography.");
        return sb.toString();
    }

    private String callDallE(String prompt) {
        Map<String, Object> body = Map.of(
                "model", imageModel,
                "prompt", prompt,
                "n", 1,
                "size", imageSize,
                "quality", imageQuality
        );

        try {
            String responseBody = webClient.post()
                    .uri("/v1/images/generations")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(String.class)
                    .timeout(Duration.ofSeconds(120))
                    .block();

            JsonNode root = objectMapper.readTree(responseBody);
            JsonNode item = root.path("data").get(0);

            // gpt-image-1: b64_json 응답 → Supabase Storage 직접 업로드
            if (item.has("b64_json")) {
                byte[] imageBytes = Base64.getDecoder().decode(item.path("b64_json").stringValue());
                return supabaseStorageService.uploadRecipeImageBytes(imageBytes, "image/png");
            }
            // url 응답 방식 (fallback)
            return supabaseStorageService.uploadRecipeImageFromUrl(item.path("url").stringValue());
        } catch (Exception e) {
            log.error("이미지 생성 API 호출 실패", e);
            throw new RuntimeException("AI 이미지 생성 중 오류가 발생했습니다.", e);
        }
    }
}

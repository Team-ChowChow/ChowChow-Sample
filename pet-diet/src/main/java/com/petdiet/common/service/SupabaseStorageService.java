package com.petdiet.common.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.UUID;

/**
 * Supabase Storage 업로드 서비스.
 * 외부 URL의 이미지를 다운로드한 뒤 Supabase Storage에 영구 저장.
 */
@Slf4j
@Service
public class SupabaseStorageService {

    private final WebClient supabaseClient;
    private final WebClient downloadClient;
    private final String supabaseUrl;
    private final String recipeBucket;
    private final String mealBucket;

    public SupabaseStorageService(
            @Value("${supabase.url}") String supabaseUrl,
            @Value("${supabase.service-role-key}") String serviceRoleKey,
            @Value("${supabase.storage.bucket-recipe:recipe-images}") String recipeBucket,
            @Value("${supabase.storage.bucket-meal:meal-images}") String mealBucket) {
        this.supabaseUrl = supabaseUrl;
        this.recipeBucket = recipeBucket;
        this.mealBucket = mealBucket;

        this.supabaseClient = WebClient.builder()
                .baseUrl(supabaseUrl + "/storage/v1")
                .defaultHeader("Authorization", "Bearer " + serviceRoleKey)
                .defaultHeader("x-upsert", "true")
                .build();

        this.downloadClient = WebClient.builder()
                .codecs(c -> c.defaultCodecs().maxInMemorySize(16 * 1024 * 1024))
                .build();
    }

    /**
     * 외부 이미지 URL을 다운로드해서 레시피 이미지 버킷에 저장하고 공개 URL을 반환.
     */
    public String uploadRecipeImageFromUrl(String imageUrl) {
        String path = "recipes/" + UUID.randomUUID() + ".png";
        return uploadFromUrl(imageUrl, recipeBucket, path);
    }

    /**
     * 외부 이미지 URL을 다운로드해서 식단 기록 이미지 버킷에 저장하고 공개 URL을 반환.
     */
    public String uploadMealImageFromUrl(String imageUrl) {
        String path = "meals/" + UUID.randomUUID() + ".png";
        return uploadFromUrl(imageUrl, mealBucket, path);
    }

    /**
     * 바이트 배열을 직접 레시피 버킷에 업로드하고 공개 URL을 반환.
     */
    public String uploadRecipeImageBytes(byte[] data, String contentType) {
        String ext = contentType != null && contentType.contains("jpeg") ? ".jpg" : ".png";
        String path = "recipes/" + UUID.randomUUID() + ext;
        return uploadBytes(data, contentType != null ? contentType : "image/png", recipeBucket, path);
    }

    /**
     * 바이트 배열을 직접 식단 기록 버킷에 업로드하고 공개 URL을 반환.
     */
    public String uploadMealImageBytes(byte[] data, String contentType) {
        String ext = contentType != null && contentType.contains("jpeg") ? ".jpg" : ".png";
        String path = "meals/" + UUID.randomUUID() + ext;
        return uploadBytes(data, contentType != null ? contentType : "image/png", mealBucket, path);
    }

    private String uploadFromUrl(String imageUrl, String bucket, String path) {
        try {
            byte[] imageBytes = downloadClient.get()
                    .uri(imageUrl)
                    .retrieve()
                    .bodyToMono(byte[].class)
                    .block();

            if (imageBytes == null || imageBytes.length == 0) {
                throw new RuntimeException("이미지 다운로드 실패: 빈 응답");
            }

            return uploadBytes(imageBytes, "image/png", bucket, path);
        } catch (Exception e) {
            log.error("Supabase Storage 업로드 실패 [bucket={}, path={}]: {}", bucket, path, e.getMessage());
            throw new RuntimeException("이미지 업로드 실패", e);
        }
    }

    private String uploadBytes(byte[] data, String contentType, String bucket, String path) {
        supabaseClient.post()
                .uri("/object/" + bucket + "/" + path)
                .contentType(MediaType.parseMediaType(contentType))
                .bodyValue(data)
                .retrieve()
                .bodyToMono(String.class)
                .block();

        return supabaseUrl + "/storage/v1/object/public/" + bucket + "/" + path;
    }
}

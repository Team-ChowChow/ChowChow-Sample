package com.petdiet.common.controller;

import com.petdiet.common.service.SupabaseStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/api/common")
@RequiredArgsConstructor
public class UploadController {

    private final SupabaseStorageService supabaseStorageService;

    @PostMapping("/upload")
    public ResponseEntity<Map<String, String>> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "recipe") String type) throws Exception {
        byte[] bytes = file.getBytes();
        String contentType = resolveImageContentType(file, bytes);
        String url = switch (type) {
            case "meal" -> supabaseStorageService.uploadMealImageBytes(bytes, contentType);
            default     -> supabaseStorageService.uploadRecipeImageBytes(bytes, contentType);
        };
        return ResponseEntity.ok(Map.of("url", url));
    }

    private String resolveImageContentType(MultipartFile file, byte[] bytes) {
        String declaredType = file.getContentType();
        if (declaredType != null && declaredType.startsWith("image/")) {
            return declaredType;
        }

        if (isPng(bytes)) return "image/png";
        if (isJpeg(bytes)) return "image/jpeg";
        if (isGif(bytes)) return "image/gif";
        if (isWebp(bytes)) return "image/webp";

        String filename = file.getOriginalFilename();
        String normalizedName = filename == null ? "" : filename.toLowerCase(Locale.ROOT);
        if (normalizedName.endsWith(".png")) return "image/png";
        if (normalizedName.endsWith(".jpg") || normalizedName.endsWith(".jpeg")) return "image/jpeg";
        if (normalizedName.endsWith(".gif")) return "image/gif";
        if (normalizedName.endsWith(".webp")) return "image/webp";

        throw new IllegalArgumentException("지원하지 않는 이미지 형식입니다.");
    }

    private boolean isPng(byte[] bytes) {
        return bytes.length >= 8
                && (bytes[0] & 0xFF) == 0x89
                && bytes[1] == 0x50
                && bytes[2] == 0x4E
                && bytes[3] == 0x47;
    }

    private boolean isJpeg(byte[] bytes) {
        return bytes.length >= 3
                && (bytes[0] & 0xFF) == 0xFF
                && (bytes[1] & 0xFF) == 0xD8
                && (bytes[2] & 0xFF) == 0xFF;
    }

    private boolean isGif(byte[] bytes) {
        if (bytes.length < 6) return false;
        String signature = new String(bytes, 0, 6, StandardCharsets.US_ASCII);
        return "GIF87a".equals(signature) || "GIF89a".equals(signature);
    }

    private boolean isWebp(byte[] bytes) {
        if (bytes.length < 12) return false;
        String riff = new String(bytes, 0, 4, StandardCharsets.US_ASCII);
        String webp = new String(bytes, 8, 4, StandardCharsets.US_ASCII);
        return "RIFF".equals(riff) && "WEBP".equals(webp);
    }
}

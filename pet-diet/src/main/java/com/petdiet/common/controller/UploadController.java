package com.petdiet.common.controller;

import com.petdiet.common.service.SupabaseStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

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
        String contentType = file.getContentType();
        String url = switch (type) {
            case "meal" -> supabaseStorageService.uploadMealImageBytes(bytes, contentType);
            default     -> supabaseStorageService.uploadRecipeImageBytes(bytes, contentType);
        };
        return ResponseEntity.ok(Map.of("url", url));
    }
}

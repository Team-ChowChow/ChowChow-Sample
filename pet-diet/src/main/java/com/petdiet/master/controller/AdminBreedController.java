package com.petdiet.master.controller;

import com.petdiet.master.entity.Breed;
import com.petdiet.master.repository.BreedRepository;
import com.petdiet.master.service.BreedEnrichService;
import com.petdiet.master.service.BreedSyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/breeds")
@RequiredArgsConstructor
public class AdminBreedController {

    private final BreedSyncService breedSyncService;
    private final BreedEnrichService breedEnrichService;
    private final BreedRepository breedRepository;

    @PostMapping("/sync/dogs")
    public ResponseEntity<Map<String, Object>> syncDogs() {
        int saved = breedSyncService.syncDogs();
        return ResponseEntity.ok(Map.of("message", "Dog API 동기화 완료", "saved", saved));
    }

    @PostMapping("/sync/cats")
    public ResponseEntity<Map<String, Object>> syncCats() {
        int saved = breedSyncService.syncCats();
        return ResponseEntity.ok(Map.of("message", "Cat API 동기화 완료", "saved", saved));
    }

    @PostMapping("/sync")
    public ResponseEntity<Map<String, Object>> syncAll() {
        int saved = breedSyncService.syncAll();
        return ResponseEntity.ok(Map.of("message", "전체 breed 동기화 완료", "saved", saved));
    }

    @PostMapping("/sync/force")
    public ResponseEntity<Map<String, Object>> syncForce() {
        int saved = breedSyncService.syncForce();
        return ResponseEntity.ok(Map.of("message", "기존 데이터 삭제 후 재동기화 완료", "saved", saved));
    }

    @PostMapping("/translate")
    public ResponseEntity<Map<String, Object>> translate(
            @RequestParam(defaultValue = "200") int batchSize) {
        int count = breedEnrichService.translateToKorean(batchSize);
        return ResponseEntity.ok(Map.of("message", "품종 한글 번역 완료", "translated", count));
    }

    @GetMapping("/sample")
    public ResponseEntity<?> sample(
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String petType) {
        List<Breed> breeds = petType != null
                ? breedRepository.findByPetTypeOrderByBreedName(petType).stream().limit(size).toList()
                : breedRepository.findAll(PageRequest.of(0, size)).getContent();
        return ResponseEntity.ok(breeds.stream()
                .map(b -> Map.of(
                        "breedName", b.getBreedName(),
                        "breedNameKo", b.getBreedNameKo() != null ? b.getBreedNameKo() : "(없음)",
                        "petType", b.getPetType()
                )).toList());
    }
}

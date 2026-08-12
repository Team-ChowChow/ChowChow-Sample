package com.petdiet.walk.controller;

import com.petdiet.config.SupabasePrincipal;
import com.petdiet.walk.dto.*;
import com.petdiet.walk.service.WalkService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/walks")
@RequiredArgsConstructor
public class WalkController {

    private final WalkService walkService;

    @GetMapping("/today")
    public ResponseEntity<WalkSummaryResponse> getToday(
            @AuthenticationPrincipal SupabasePrincipal principal) {
        return ResponseEntity.ok(walkService.getToday(principal.authUuid()));
    }

    @GetMapping
    public ResponseEntity<List<WalkRecordResponse>> getRecentWalks(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(walkService.getRecentWalks(principal.authUuid(), limit));
    }

    @PostMapping
    public ResponseEntity<WalkFinishResponse> finishWalk(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody @Valid WalkFinishRequest request) {
        return ResponseEntity.ok(walkService.finishWalk(principal.authUuid(), request));
    }
}

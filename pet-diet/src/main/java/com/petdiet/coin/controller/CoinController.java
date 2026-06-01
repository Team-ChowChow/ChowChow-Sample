package com.petdiet.coin.controller;

import com.petdiet.coin.entity.CoinLog;
import com.petdiet.coin.service.CoinService;
import com.petdiet.config.SupabasePrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/coins")
@RequiredArgsConstructor
public class CoinController {

    private final CoinService coinService;

    @GetMapping("/balance")
    public ResponseEntity<?> getBalance(@AuthenticationPrincipal SupabasePrincipal principal) {
        int balance = coinService.getBalance(principal.authUuid());
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    @PostMapping("/daily-login")
    public ResponseEntity<?> dailyLogin(@AuthenticationPrincipal SupabasePrincipal principal) {
        int balance = coinService.dailyLoginReward(principal.authUuid());
        return ResponseEntity.ok(Map.of("balance", balance, "reward", CoinService.DAILY_LOGIN_REWARD));
    }

    @PostMapping("/earn")
    public ResponseEntity<?> earn(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody Map<String, Object> body) {
        String reason = (String) body.getOrDefault("reason", "활동");
        int amount = ((Number) body.getOrDefault("amount", 0)).intValue();
        if (amount <= 0) return ResponseEntity.badRequest().body(Map.of("error", "amount must be > 0"));
        int balance = coinService.earnCoins(principal.authUuid(), amount, reason);
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    @PostMapping("/spend")
    public ResponseEntity<?> spend(
            @AuthenticationPrincipal SupabasePrincipal principal,
            @RequestBody Map<String, Object> body) {
        String reason = (String) body.getOrDefault("reason", "활동");
        int amount = ((Number) body.getOrDefault("amount", 0)).intValue();
        boolean success = coinService.spendCoins(principal.authUuid(), amount, reason);
        if (!success) return ResponseEntity.badRequest().body(Map.of("error", "코인이 부족합니다."));
        int balance = coinService.getBalance(principal.authUuid());
        return ResponseEntity.ok(Map.of("balance", balance, "success", true));
    }

    @GetMapping("/logs")
    public ResponseEntity<Page<CoinLog>> getLogs(
            @AuthenticationPrincipal SupabasePrincipal principal,
            Pageable pageable) {
        return ResponseEntity.ok(coinService.getLogs(principal.authUuid(), pageable));
    }
}

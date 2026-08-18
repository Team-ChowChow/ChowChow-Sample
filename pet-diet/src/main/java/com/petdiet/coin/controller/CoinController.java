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
        int previousBalance = coinService.getBalance(principal.authUuid());
        int balance = coinService.dailyLoginReward(principal.authUuid());
        int reward = Math.max(0, balance - previousBalance);
        return ResponseEntity.ok(Map.of(
                "balance", balance,
                "reward", reward,
                "awarded", reward > 0));
    }

    @GetMapping("/missions/today")
    public ResponseEntity<?> getDailyMissions(
            @AuthenticationPrincipal SupabasePrincipal principal) {
        return ResponseEntity.ok(coinService.getDailyMissions(principal.authUuid()));
    }

    @GetMapping("/logs")
    public ResponseEntity<Page<CoinLog>> getLogs(
            @AuthenticationPrincipal SupabasePrincipal principal,
            Pageable pageable) {
        return ResponseEntity.ok(coinService.getLogs(principal.authUuid(), pageable));
    }
}

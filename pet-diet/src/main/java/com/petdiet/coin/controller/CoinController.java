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

    // TODO(임시): 코인 상점 테스트가 끝나면 엔드포인트와 함께 제거한다.
    private static final int TEST_COIN_GRANT_AMOUNT = 2_000;

    private final CoinService coinService;

    @GetMapping("/balance")
    public ResponseEntity<?> getBalance(@AuthenticationPrincipal SupabasePrincipal principal) {
        int balance = coinService.getBalance(principal.authUuid());
        return ResponseEntity.ok(Map.of("balance", balance));
    }

    @PostMapping("/test-grant")
    public ResponseEntity<?> grantTestCoins(
            @AuthenticationPrincipal SupabasePrincipal principal) {
        int balance = coinService.earnCoins(
                principal.authUuid(), TEST_COIN_GRANT_AMOUNT, "테스트 코인 지급");
        return ResponseEntity.ok(Map.of(
                "balance", balance,
                "granted", TEST_COIN_GRANT_AMOUNT));
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

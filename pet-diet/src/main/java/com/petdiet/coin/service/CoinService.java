package com.petdiet.coin.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.entity.CoinLog;
import com.petdiet.coin.entity.UserCoin;
import com.petdiet.coin.repository.CoinLogRepository;
import com.petdiet.coin.repository.UserCoinRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CoinService {

    public static final int DAILY_LOGIN_REWARD    = 5;
    public static final int COMMUNITY_POST_REWARD = 10;
    public static final int COMMUNITY_COMMENT_REWARD = 5;
    public static final int COMMUNITY_LIKE_REWARD    = 2;
    public static final int DIET_ADD_REWARD          = 10;
    public static final int LLM_GENERATE_REWARD      = 20;

    public static final int ACTIVITY_EXERCISE_COST  = 50;
    public static final int ACTIVITY_BATH_COST       = 100;

    private final UserCoinRepository coinRepository;
    private final CoinLogRepository logRepository;
    private final UserRepository userRepository;

    @Transactional
    public UserCoin getOrCreateCoin(User user) {
        return coinRepository.findByUser(user).orElseGet(() -> {
            UserCoin coin = UserCoin.builder().user(user).balance(0).build();
            return coinRepository.save(coin);
        });
    }

    @Transactional(readOnly = true)
    public int getBalance(UUID authUuid) {
        User user = findUser(authUuid);
        return getOrCreateCoin(user).getBalance();
    }

    @Transactional
    public int earnCoins(UUID authUuid, int amount, String reason) {
        User user = findUser(authUuid);
        UserCoin coin = getOrCreateCoin(user);
        coin.addCoins(amount);
        coinRepository.save(coin);
        logRepository.save(CoinLog.builder()
            .user(user).amount(amount).reason(reason)
            .balanceAfter(coin.getBalance()).build());
        log.info("코인 적립 [user={}] {} -> {}코인 ({})", user.getUserId(), amount, coin.getBalance(), reason);
        return coin.getBalance();
    }

    @Transactional
    public boolean spendCoins(UUID authUuid, int amount, String reason) {
        User user = findUser(authUuid);
        UserCoin coin = getOrCreateCoin(user);
        if (!coin.spendCoins(amount)) return false;
        coinRepository.save(coin);
        logRepository.save(CoinLog.builder()
            .user(user).amount(-amount).reason(reason)
            .balanceAfter(coin.getBalance()).build());
        log.info("코인 사용 [user={}] -{}코인 -> {}코인 ({})", user.getUserId(), amount, coin.getBalance(), reason);
        return true;
    }

    @Transactional
    public int dailyLoginReward(UUID authUuid) {
        User user = findUser(authUuid);
        UserCoin coin = getOrCreateCoin(user);
        if (!coin.canDailyLogin()) return coin.getBalance();
        coin.recordDailyLogin();
        coin.addCoins(DAILY_LOGIN_REWARD);
        coinRepository.save(coin);
        logRepository.save(CoinLog.builder()
            .user(user).amount(DAILY_LOGIN_REWARD).reason("일일 로그인")
            .balanceAfter(coin.getBalance()).build());
        return coin.getBalance();
    }

    @Transactional
    public int llmGenerateReward(UUID authUuid) {
        User user = findUser(authUuid);
        UserCoin coin = getOrCreateCoin(user);
        if (!coin.canLlmGenerate()) return coin.getBalance();
        coin.recordLlmGenerate();
        coin.addCoins(LLM_GENERATE_REWARD);
        coinRepository.save(coin);
        logRepository.save(CoinLog.builder()
            .user(user).amount(LLM_GENERATE_REWARD).reason("LLM 식단 생성")
            .balanceAfter(coin.getBalance()).build());
        return coin.getBalance();
    }

    @Transactional(readOnly = true)
    public Page<CoinLog> getLogs(UUID authUuid, Pageable pageable) {
        User user = findUser(authUuid);
        return logRepository.findByUserOrderByCreatedAtDesc(user, pageable);
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
            .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }
}

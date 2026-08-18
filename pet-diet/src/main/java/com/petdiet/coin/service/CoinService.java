package com.petdiet.coin.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.entity.CoinLog;
import com.petdiet.coin.entity.UserCoin;
import com.petdiet.coin.dto.DailyMissionResponse;
import com.petdiet.coin.dto.DailyMissionSummaryResponse;
import com.petdiet.coin.repository.CoinLogRepository;
import com.petdiet.coin.repository.UserCoinRepository;
import com.petdiet.character.repository.CharacterGrowthLogRepository;
import com.petdiet.walk.repository.WalkRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.List;
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

    public static final int FEED_MISSION_REWARD = 150;
    public static final int PET_MISSION_REWARD = 100;
    public static final int WALK_MISSION_REWARD = 100;

    private static final ZoneId REWARD_ZONE = ZoneId.of("Asia/Seoul");
    private static final String FEED_MISSION_REASON = "성장미션: 밥주기 3회";
    private static final String PET_MISSION_REASON = "성장미션: 쓰다듬기 5회";
    private static final String WALK_MISSION_REASON = "성장미션: 산책 1km";

    private final UserCoinRepository coinRepository;
    private final CoinLogRepository logRepository;
    private final UserRepository userRepository;
    private final CharacterGrowthLogRepository growthLogRepository;
    private final WalkRecordRepository walkRecordRepository;

    @Transactional
    public UserCoin getOrCreateCoin(User user) {
        return coinRepository.findByUser(user).orElseGet(() -> {
            UserCoin coin = UserCoin.builder().user(user).balance(0).build();
            return coinRepository.save(coin);
        });
    }

    @Transactional
    public int getBalance(UUID authUuid) {
        User user = findUser(authUuid);
        return getOrCreateCoin(user).getBalance();
    }

    @Transactional
    public int earnCoins(UUID authUuid, int amount, String reason) {
        if (amount <= 0) throw new IllegalArgumentException("적립 코인은 0보다 커야 합니다.");
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
        if (amount <= 0) throw new IllegalArgumentException("사용 코인은 0보다 커야 합니다.");
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
    public int earnCoinsOnce(UUID authUuid, int amount, String reason) {
        if (amount <= 0) throw new IllegalArgumentException("적립 코인은 0보다 커야 합니다.");
        User user = findUser(authUuid);
        if (logRepository.existsByUserAndReason(user, reason)) {
            return getOrCreateCoin(user).getBalance();
        }
        return earnCoins(authUuid, amount, reason);
    }

    @Transactional
    public DailyMissionSummaryResponse getDailyMissions(UUID authUuid) {
        User user = findUser(authUuid);
        LocalDate today = LocalDate.now(REWARD_ZONE);
        OffsetDateTime from = today.atStartOfDay(REWARD_ZONE).toOffsetDateTime();
        OffsetDateTime to = today.plusDays(1).atStartOfDay(REWARD_ZONE).toOffsetDateTime();

        int feedCount = Math.toIntExact(growthLogRepository
                .countByUserIdAndActivityTypeAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                        user.getUserId(), "FEED", from, to));
        int petCount = Math.toIntExact(growthLogRepository
                .countByUserIdAndActivityTypeAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                        user.getUserId(), "PET", from, to));
        Integer walkDistance = walkRecordRepository.sumDistanceByUserAndWalkDate(user, today);
        int walkMeters = walkDistance == null ? 0 : walkDistance;

        DailyMissionResponse feed = claimMission(
                authUuid, user, "feed_3", "밥주기 3회", feedCount, 3,
                FEED_MISSION_REWARD, FEED_MISSION_REASON, from, to);
        DailyMissionResponse pet = claimMission(
                authUuid, user, "pet_5", "쓰다듬기 5회", petCount, 5,
                PET_MISSION_REWARD, PET_MISSION_REASON, from, to);
        DailyMissionResponse walk = claimMission(
                authUuid, user, "walk_1km", "산책 1km", walkMeters, 1_000,
                WALK_MISSION_REWARD, WALK_MISSION_REASON, from, to);

        return new DailyMissionSummaryResponse(
                today,
                getOrCreateCoin(user).getBalance(),
                List.of(feed, pet, walk));
    }

    private DailyMissionResponse claimMission(
            UUID authUuid,
            User user,
            String key,
            String label,
            int progress,
            int target,
            int reward,
            String reason,
            OffsetDateTime from,
            OffsetDateTime to) {
        boolean completed = progress >= target;
        boolean claimed = logRepository
                .existsByUserAndReasonAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                        user, reason, from, to);
        if (completed && !claimed) {
            earnCoins(authUuid, reward, reason);
            claimed = true;
        }
        return new DailyMissionResponse(
                key, label, Math.min(progress, target), target, reward, completed, claimed);
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

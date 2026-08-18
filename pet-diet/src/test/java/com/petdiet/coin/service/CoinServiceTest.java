package com.petdiet.coin.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.character.repository.CharacterGrowthLogRepository;
import com.petdiet.coin.entity.UserCoin;
import com.petdiet.coin.repository.CoinLogRepository;
import com.petdiet.coin.repository.UserCoinRepository;
import com.petdiet.walk.repository.WalkRecordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class CoinServiceTest {

    private final UUID authUuid = UUID.randomUUID();
    private User user;
    private UserCoin coin;
    private CoinLogRepository logRepository;
    private CharacterGrowthLogRepository growthLogRepository;
    private CoinService coinService;

    @BeforeEach
    void setUp() {
        user = User.builder().userId(1).authUuid(authUuid).build();
        coin = UserCoin.builder().user(user).balance(0).build();
        UserCoinRepository coinRepository = mock(UserCoinRepository.class);
        logRepository = mock(CoinLogRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        growthLogRepository = mock(CharacterGrowthLogRepository.class);
        WalkRecordRepository walkRecordRepository = mock(WalkRecordRepository.class);

        when(userRepository.findByAuthUuid(authUuid)).thenReturn(Optional.of(user));
        when(coinRepository.findByUser(user)).thenReturn(Optional.of(coin));
        when(growthLogRepository
                .countByUserIdAndActivityTypeAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                        eq(1), eq("FEED"), any(OffsetDateTime.class), any(OffsetDateTime.class)))
                .thenReturn(3L);
        when(growthLogRepository
                .countByUserIdAndActivityTypeAndCreatedAtGreaterThanEqualAndCreatedAtLessThan(
                        eq(1), eq("PET"), any(OffsetDateTime.class), any(OffsetDateTime.class)))
                .thenReturn(0L);
        when(walkRecordRepository.sumDistanceByUserAndWalkDate(eq(user), any()))
                .thenReturn(0);

        coinService = new CoinService(
                coinRepository,
                logRepository,
                userRepository,
                growthLogRepository,
                walkRecordRepository);
    }

    @Test
    void completedFeedMissionAwardsOneHundredFiftyCoins() {
        var summary = coinService.getDailyMissions(authUuid);

        assertEquals(150, summary.balance());
        assertEquals(150, summary.missions().get(0).rewardCoins());
        assertEquals(true, summary.missions().get(0).claimed());
        verify(logRepository).save(argThat(log ->
                log.getAmount() == 150 && "성장미션: 밥주기 3회".equals(log.getReason())));
    }

    @Test
    void nonPositiveCoinChangesAreRejected() {
        assertThrows(
                IllegalArgumentException.class,
                () -> coinService.earnCoins(authUuid, 0, "invalid"));
        assertThrows(
                IllegalArgumentException.class,
                () -> coinService.spendCoins(authUuid, -1, "invalid"));
    }
}

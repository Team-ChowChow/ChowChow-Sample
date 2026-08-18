package com.petdiet.walk.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.service.CoinService;
import com.petdiet.coin.dto.DailyMissionSummaryResponse;
import com.petdiet.walk.dto.WalkFinishRequest;
import com.petdiet.walk.entity.WalkRecord;
import com.petdiet.walk.repository.WalkRecordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.List;
import java.time.LocalDate;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class WalkServiceTest {

    private final UUID authUuid = UUID.randomUUID();
    private User user;
    private WalkRecordRepository walkRecordRepository;
    private UserRepository userRepository;
    private CoinService coinService;
    private WalkService walkService;

    @BeforeEach
    void setUp() {
        user = User.builder().userId(1).authUuid(authUuid).build();
        walkRecordRepository = mock(WalkRecordRepository.class);
        userRepository = mock(UserRepository.class);
        coinService = mock(CoinService.class);
        walkService = new WalkService(walkRecordRepository, userRepository, coinService);

        when(userRepository.findByAuthUuid(authUuid)).thenReturn(Optional.of(user));
        when(walkRecordRepository.findByUserAndSessionId(any(), anyString()))
                .thenReturn(Optional.empty());
        when(walkRecordRepository.sumDistanceByUserAndWalkDate(any(), any()))
                .thenReturn(400);
        when(walkRecordRepository.save(any(WalkRecord.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(coinService.earnCoins(authUuid, 10, "산책 로드맵 달성"))
                .thenReturn(110);
        when(coinService.getDailyMissions(authUuid))
                .thenReturn(new DailyMissionSummaryResponse(LocalDate.now(), 110, List.of()));
    }

    @Test
    void finishWalkAwardsOnlyNewMilestones() {
        OffsetDateTime startedAt = OffsetDateTime.now().minusMinutes(20);
        WalkFinishRequest request = new WalkFinishRequest(
                "session-1", 1_100, 1_200, startedAt, startedAt.plusMinutes(20));

        var response = walkService.finishWalk(authUuid, request);

        assertEquals(10, response.earnedCoins());
        assertEquals(1_500, response.today().todayDistanceMeters());
        assertEquals(110, response.today().balance());
        verify(coinService).earnCoins(authUuid, 10, "산책 로드맵 달성");
    }

    @Test
    void zeroDistanceWalkFinishesWithoutCoinReward() {
        OffsetDateTime startedAt = OffsetDateTime.now().minusMinutes(1);
        WalkFinishRequest request = new WalkFinishRequest(
                "session-zero", 0, 60, startedAt, startedAt.plusMinutes(1));
        when(coinService.getBalance(authUuid)).thenReturn(100);
        when(coinService.getDailyMissions(authUuid))
                .thenReturn(new DailyMissionSummaryResponse(LocalDate.now(), 100, List.of()));

        var response = walkService.finishWalk(authUuid, request);

        assertEquals(0, response.walk().distanceMeters());
        assertEquals(0, response.earnedCoins());
        assertEquals(400, response.today().todayDistanceMeters());
        assertEquals(100, response.today().balance());
        verify(walkRecordRepository).save(any(WalkRecord.class));
        verify(coinService).getBalance(authUuid);
        verify(coinService, never()).earnCoins(any(), anyInt(), anyString());
    }

    @Test
    void unrealisticAverageSpeedIsRejected() {
        OffsetDateTime startedAt = OffsetDateTime.now().minusMinutes(2);
        WalkFinishRequest request = new WalkFinishRequest(
                "session-fast", 5_000, 120, startedAt, startedAt.plusMinutes(2));

        assertThrows(
                IllegalArgumentException.class,
                () -> walkService.finishWalk(authUuid, request)
        );
        verify(walkRecordRepository, never()).save(any());
        verifyNoInteractions(coinService);
    }
}

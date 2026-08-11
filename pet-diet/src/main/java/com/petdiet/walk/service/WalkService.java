package com.petdiet.walk.service;

import com.petdiet.auth.entity.User;
import com.petdiet.auth.repository.UserRepository;
import com.petdiet.coin.service.CoinService;
import com.petdiet.walk.dto.*;
import com.petdiet.walk.entity.WalkRecord;
import com.petdiet.walk.repository.WalkRecordRepository;
import com.petdiet.walk.reward.WalkRewardRoadmap;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WalkService {

    private static final int MAX_DISTANCE_METERS = 50_000;
    private static final double MAX_AVERAGE_SPEED_KMH = 20.0;

    private final WalkRecordRepository walkRecordRepository;
    private final UserRepository userRepository;
    private final CoinService coinService;

    @Transactional
    public WalkSummaryResponse getToday(UUID authUuid) {
        User user = findUser(authUuid);
        return buildSummary(authUuid, user, LocalDate.now());
    }

    @Transactional(readOnly = true)
    public List<WalkRecordResponse> getRecentWalks(UUID authUuid, int limit) {
        User user = findUser(authUuid);
        int safeLimit = Math.max(1, Math.min(limit, 50));
        return walkRecordRepository
                .findByUserOrderByStartedAtDesc(user, PageRequest.of(0, safeLimit))
                .stream()
                .map(WalkRecordResponse::from)
                .toList();
    }

    @Transactional
    public WalkFinishResponse finishWalk(UUID authUuid, WalkFinishRequest request) {
        User user = findUser(authUuid);

        WalkRecord existing = walkRecordRepository
                .findByUserAndSessionId(user, request.sessionId())
                .orElse(null);
        if (existing != null) {
            return new WalkFinishResponse(
                    WalkRecordResponse.from(existing),
                    buildSummary(authUuid, user, existing.getWalkDate()),
                    existing.getRewardCoins()
            );
        }

        validate(request);

        LocalDate walkDate = LocalDate.now();
        int previousDistance = sumDistance(user, walkDate);
        int newDistance = previousDistance + request.distanceMeters();
        int earnedCoins = WalkRewardRoadmap.rewardBetween(previousDistance, newDistance);

        WalkRecord saved = walkRecordRepository.save(WalkRecord.builder()
                .user(user)
                .sessionId(request.sessionId())
                .walkDate(walkDate)
                .distanceMeters(request.distanceMeters())
                .durationSeconds(request.durationSeconds())
                .rewardCoins(earnedCoins)
                .startedAt(request.startedAt())
                .endedAt(request.endedAt())
                .build());

        int balance = earnedCoins > 0
                ? coinService.earnCoins(authUuid, earnedCoins, "산책 로드맵 달성")
                : coinService.getBalance(authUuid);

        return new WalkFinishResponse(
                WalkRecordResponse.from(saved),
                WalkSummaryResponse.of(walkDate, newDistance, balance),
                earnedCoins
        );
    }

    private void validate(WalkFinishRequest request) {
        if (!request.endedAt().isAfter(request.startedAt())) {
            throw new IllegalArgumentException("산책 종료 시각은 시작 시각보다 늦어야 합니다.");
        }
        if (request.distanceMeters() > MAX_DISTANCE_METERS) {
            throw new IllegalArgumentException("한 번에 기록할 수 있는 최대 산책 거리는 50km입니다.");
        }

        long elapsedSeconds = Duration.between(request.startedAt(), request.endedAt()).getSeconds();
        if (request.durationSeconds() > elapsedSeconds + 60) {
            throw new IllegalArgumentException("산책 시간이 올바르지 않습니다.");
        }

        double averageSpeed = request.distanceMeters() * 3.6 / request.durationSeconds();
        if (request.durationSeconds() >= 30 && averageSpeed > MAX_AVERAGE_SPEED_KMH) {
            throw new IllegalArgumentException("걷기 범위를 벗어난 속도가 감지되었습니다.");
        }
    }

    private WalkSummaryResponse buildSummary(UUID authUuid, User user, LocalDate date) {
        return WalkSummaryResponse.of(
                date,
                sumDistance(user, date),
                coinService.getBalance(authUuid)
        );
    }

    private int sumDistance(User user, LocalDate date) {
        Integer distance = walkRecordRepository.sumDistanceByUserAndWalkDate(user, date);
        return distance == null ? 0 : distance;
    }

    private User findUser(UUID authUuid) {
        return userRepository.findByAuthUuid(authUuid)
                .orElseThrow(() -> new IllegalStateException("유저를 찾을 수 없습니다."));
    }
}

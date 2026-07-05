package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.entity.RewardClaim;
import com.github.jisaaa.poker.domain.entity.RewardTier;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryStockStore;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import com.github.jisaaa.poker.mapper.RewardClaimMapper;
import com.github.jisaaa.poker.mapper.RewardTierMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RewardServiceTest {

    @Mock private GameSessionMapper sessionMapper;
    @Mock private RewardTierMapper tierMapper;
    @Mock private RewardClaimMapper claimMapper;
    @Mock private InMemoryStockStore stockStore;

    @InjectMocks
    private RewardService rewardService;

    private GameSession session;

    @BeforeEach
    void setUp() {
        session = GameSession.builder()
                .id(10001L)
                .userId("user1")
                .totalScore(5000L)
                .build();
    }

    @Test
    @DisplayName("should_returnAlreadyClaimed_when_duplicateClaim")
    void should_returnAlreadyClaimed_when_duplicateClaim() {
        doReturn(new RewardClaim()).when(claimMapper).selectByUserAndSession("user1", 10001L);

        RewardService.ClaimResult result = rewardService.claim("user1", 10001L);

        assertTrue(result.isAlreadyClaimed());
    }

    @Test
    @DisplayName("should_returnNoReward_when_scoreTooLow")
    void should_returnNoReward_when_scoreTooLow() {
        doReturn(null).when(claimMapper).selectByUserAndSession("user1", 10001L);
        when(sessionMapper.selectById(10001L)).thenReturn(session);
        when(tierMapper.selectByScore(5000L)).thenReturn(null);

        RewardService.ClaimResult result = rewardService.claim("user1", 10001L);

        assertFalse(result.isSuccess());
        assertFalse(result.isOutOfStock());
        assertFalse(result.isAlreadyClaimed());
    }

    @Test
    @DisplayName("should_returnOutOfStock_when_noStockLeft")
    void should_returnOutOfStock_when_noStockLeft() {
        when(claimMapper.selectByUserAndSession("user1", 10001L)).thenReturn(null);
        when(sessionMapper.selectById(10001L)).thenReturn(session);

        RewardTier tier = RewardTier.builder().id(1).stockLimit(100).stockUsed(100).rewardName("奶茶").rewardType("drink").build();
        when(tierMapper.selectByScore(5000L)).thenReturn(tier);
        when(stockStore.decrementIfPositive(1)).thenReturn(false);

        RewardService.ClaimResult result = rewardService.claim("user1", 10001L);

        assertTrue(result.isOutOfStock());
    }

    @Test
    @DisplayName("should_returnSuccess_when_claimValid")
    void should_returnSuccess_when_claimValid() {
        when(claimMapper.selectByUserAndSession("user1", 10001L)).thenReturn(null);
        when(sessionMapper.selectById(10001L)).thenReturn(session);

        RewardTier tier = RewardTier.builder().id(2).stockLimit(1000).stockUsed(10).rewardName("奶茶升级券").rewardType("coupon").build();
        when(tierMapper.selectByScore(5000L)).thenReturn(tier);
        when(stockStore.decrementIfPositive(2)).thenReturn(true);
        doReturn(1).when(claimMapper).insert(any(RewardClaim.class));
        when(tierMapper.incrementStockUsed(2)).thenReturn(1);

        RewardService.ClaimResult result = rewardService.claim("user1", 10001L);

        assertTrue(result.isSuccess());
        assertEquals("奶茶升级券", result.getTierName());
        assertEquals("coupon", result.getTierType());
    }

    @Test
    @DisplayName("should_throwSessionNotFound_when_sessionNotExists")
    void should_throwSessionNotFound_when_sessionNotExists() {
        doReturn(null).when(claimMapper).selectByUserAndSession("user1", 99999L);
        when(sessionMapper.selectById(99999L)).thenReturn(null);

        BizException ex = assertThrows(BizException.class,
                () -> rewardService.claim("user1", 99999L));
        assertEquals(ErrorCode.SESSION_NOT_FOUND.getCode(), ex.getCode());
    }
}

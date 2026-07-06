package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.dto.RankEntry;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.entity.RewardClaim;
import com.github.jisaaa.poker.domain.entity.RewardTier;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryStockStore;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import com.github.jisaaa.poker.mapper.RewardClaimMapper;
import com.github.jisaaa.poker.mapper.RewardTierMapper;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class RewardService {

    private final GameSessionMapper sessionMapper;
    private final RewardTierMapper tierMapper;
    private final RewardClaimMapper claimMapper;
    private final InMemoryStockStore stockStore;

    public RewardTier matchTier(long score) {
        return tierMapper.selectByScore(score);
    }

    public List<RewardTier> getAllTiers() {
        return tierMapper.selectDistinctByName();
    }

    @Transactional
    public ClaimResult claim(String userId, Long sessionId) {
        // 1. Prevent duplicate
        RewardClaim existing = claimMapper.selectByUserAndSession(userId, sessionId);
        if (existing != null) return ClaimResult.alreadyClaimed();

        GameSession session = sessionMapper.selectById(sessionId);
        if (session == null) throw new BizException(ErrorCode.SESSION_NOT_FOUND);

        RewardTier tier = matchTier(session.getTotalScore());
        if (tier == null) return ClaimResult.noReward();

        // 2. In-memory atomic stock decrement
        if (tier.getStockLimit() != -1) {
            if (!stockStore.decrementIfPositive(tier.getId())) {
                return ClaimResult.outOfStock();
            }
        }

        // 3. Insert claim record (unique key prevents concurrent duplicates)
        RewardClaim claim = RewardClaim.builder()
                .userId(userId).sessionId(sessionId).tierId(tier.getId())
                .status(0) // pending
                .build();
        try {
            claimMapper.insert(claim);
        } catch (DuplicateKeyException e) {
            if (tier.getStockLimit() != -1) {
                stockStore.increment(tier.getId());
            }
            return ClaimResult.alreadyClaimed();
        }

        tierMapper.incrementStockUsed(tier.getId());
        return ClaimResult.success(tier);
    }

    // --- Claim Result ---

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ClaimResult {
        private boolean success;
        private boolean outOfStock;
        private boolean alreadyClaimed;
        private String tierName;
        private String tierType;

        public static ClaimResult success(RewardTier tier) {
            return ClaimResult.builder()
                    .success(true)
                    .tierName(tier.getRewardName())
                    .tierType(tier.getRewardType())
                    .build();
        }

        public static ClaimResult outOfStock() {
            return ClaimResult.builder().outOfStock(true).build();
        }

        public static ClaimResult alreadyClaimed() {
            return ClaimResult.builder().alreadyClaimed(true).build();
        }

        public static ClaimResult noReward() {
            return ClaimResult.builder().build();
        }
    }
}

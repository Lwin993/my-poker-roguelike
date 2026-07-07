package com.github.jisaaa.poker.game.model;

import com.github.jisaaa.poker.domain.enums.HandRank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Hand evaluation result — v3.1 dual-dimension system.
 * Contains baseChips and baseMult (replacing single baseScore).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HandResult {
    private HandRank handRank;
    private int baseChips;   // v3.1: 基础伤害 (5~100)
    private int baseMult;    // v3.1: 基础倍率 (1~8)

    /**
     * @deprecated Use {@link #getBaseChips()} instead. Kept for backward compat.
     */
    @Deprecated
    public int getBaseScore() {
        return baseChips;
    }
}

package com.github.jisaaa.poker.domain.enums;

import lombok.Getter;

/**
 * Poker hand ranks — v3.1 dual-dimension system (chips × mult).
 * Replaces single baseScore with baseChips + baseMult.
 */
@Getter
public enum HandRank {
    HIGH_CARD(0, 5, 1),
    ONE_PAIR(1, 10, 2),
    TWO_PAIR(2, 20, 2),
    THREE_OF_KIND(3, 30, 3),
    STRAIGHT(4, 30, 4),
    FLUSH(5, 25, 5),
    FULL_HOUSE(6, 40, 4),
    FOUR_OF_KIND(7, 60, 7),
    STRAIGHT_FLUSH(8, 100, 8);

    private final int code;
    private final int baseChips;   // v3.1: 基础伤害 (was baseScore)
    private final int baseMult;    // v3.1: 基础倍率

    HandRank(int code, int baseChips, int baseMult) {
        this.code = code;
        this.baseChips = baseChips;
        this.baseMult = baseMult;
    }

    /**
     * @deprecated Use {@link #getBaseChips()} instead. Kept for backward compat.
     */
    @Deprecated
    public int getBaseScore() {
        return baseChips;
    }
}

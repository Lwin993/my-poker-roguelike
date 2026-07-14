package com.github.jisaaa.poker.game.model;

import java.util.Random;

/**
 * Item modifier interface — v3.1 dual-dimension system (chips × mult).
 * All artifact/consumable effects implement this.
 * Pure logic, zero external dependency.
 */
public interface ItemModifier {

    /**
     * Apply chip (damage) addition.
     * Used by items that add to the chips dimension (e.g., 火眼金睛 adds chips per suit card).
     * @param currentChips current chip total
     * @param level item level (1-3 for artifacts, 0 for consumables)
     * @param handResult the hand evaluation result (for suit-aware items)
     * @return chip points to add
     */
    default int applyChipAdd(int currentChips, int level, HandResult handResult) {
        return 0;
    }

    /**
     * Apply mult (multiplier) addition.
     * Used by items that add flat mult (e.g., 芭蕉扇 +4/+7/+11 mult).
     * @param level item level
     * @return mult points to add
     */
    default double applyMultAdd(int level) {
        return 0.0;
    }

    /**
     * Apply mult factor (multiplicative, e.g., 斩妖剑 ×3, 分身术 ×2).
     * @param level item level
     * @return multiplier factor (default 1.0 = no change)
     */
    default double applyMultFactor(int level) {
        return 1.0;
    }

    /**
     * Get crit rate addition for the given level.
     */
    default double getCritRateAdd(int level) {
        return 0.0;
    }

    /**
     * Get crit multiplier addition for the given level.
     */
    default double getCritMultAdd(int level) {
        return 0.0;
    }

    /**
     * Get special multiplier (e.g., 人参果 low-prob ×mult).
     * @param level item level
     * @param rng random number generator
     * @return special multiplier (1.0 = no effect)
     */
    default double getSpecialMult(int level, Random rng) {
        return 1.0;
    }

    // ---- Legacy methods (kept for backward compat, will be removed) ----

    /**
     * @deprecated Use {@link #applyMultAdd(int)} instead.
     */
    @Deprecated
    default double applyMult(double currentMult, int level, Random rng) {
        return currentMult + applyMultAdd(level);
    }

    /**
     * @deprecated Use {@link #applyChipAdd(int, int, HandResult)} instead.
     */
    @Deprecated
    default int applyScoreAdd(int currentScore, int level) {
        return currentScore + applyChipAdd(currentScore, level, null);
    }
}

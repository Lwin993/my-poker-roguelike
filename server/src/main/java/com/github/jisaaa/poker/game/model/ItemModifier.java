package com.github.jisaaa.poker.game.model;

import java.util.Random;

/**
 * Item modifier interface — all joker/consumable effects implement this.
 * Pure logic, zero external dependency.
 */
public interface ItemModifier {

    /** Apply multiplier modification */
    default double applyMult(double currentMult, int level, Random rng) {
        return currentMult;
    }

    /** Apply score addition */
    default int applyScoreAdd(int currentScore, int level) {
        return currentScore;
    }

    /** Get crit rate addition for the given level */
    default double getCritRateAdd(int level) {
        return 0.0;
    }

    /** Get crit multiplier addition for the given level */
    default double getCritMultAdd(int level) {
        return 0.0;
    }
}

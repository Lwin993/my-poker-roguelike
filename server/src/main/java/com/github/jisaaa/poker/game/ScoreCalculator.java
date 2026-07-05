package com.github.jisaaa.poker.game;

import com.github.jisaaa.poker.game.model.HandResult;
import com.github.jisaaa.poker.game.model.ItemModifier;
import com.github.jisaaa.poker.game.model.ScoreResult;
import com.github.jisaaa.poker.game.registry.ItemModifierRegistry;

import java.util.List;
import java.util.Random;

/**
 * Score calculator — pure game logic, zero external dependency.
 * Computes final score from hand result + jokers + consumables + RNG.
 */
public class ScoreCalculator {

    public static ScoreResult calculate(
            HandResult handResult,
            List<JokerState> jokers,
            List<String> consumables,
            long rngSeed) {

        Random rng = new Random(rngSeed);

        // 1. Base score = hand rank base score
        double mult = 1.0;
        int baseScore = handResult.getBaseScore();

        // 2. Joker modifiers
        for (JokerState joker : jokers) {
            ItemModifier mod = ItemModifierRegistry.getModifier(joker.getId());
            if (mod != null) {
                mult = mod.applyMult(mult, joker.getLevel(), rng);
                baseScore = mod.applyScoreAdd(baseScore, joker.getLevel());
            }
        }

        // 3. Consumable modifiers
        for (String consumableId : consumables) {
            ItemModifier mod = ItemModifierRegistry.getModifier(consumableId);
            if (mod != null) {
                mult = mod.applyMult(mult, 0, rng);
            }
        }

        // 4. Crit determination (RNG-based)
        double critRate = 0.05;  // base 5%
        double critMult = 1.5;   // base 1.5x
        for (JokerState joker : jokers) {
            ItemModifier mod = ItemModifierRegistry.getModifier(joker.getId());
            if (mod != null) {
                critRate += mod.getCritRateAdd(joker.getLevel());
                critMult += mod.getCritMultAdd(joker.getLevel());
            }
        }
        boolean isCrit = rng.nextDouble() < critRate;
        if (isCrit) {
            mult *= critMult;
        }

        // 5. Final score = baseScore * totalMult, rounded
        int score = (int) Math.round(baseScore * mult);

        return ScoreResult.builder()
                .score(score)
                .isCrit(isCrit)
                .mult(mult)
                .build();
    }

    /**
     * Joker state used by ScoreCalculator — lightweight inner class.
     */
    public static class JokerState {
        private final String id;
        private final int level;
        public JokerState(String id, int level) {
            this.id = id;
            this.level = level;
        }
        public String getId() { return id; }
        public int getLevel() { return level; }
    }
}

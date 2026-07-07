package com.github.jisaaa.poker.game;

import com.github.jisaaa.poker.game.model.Card;
import com.github.jisaaa.poker.game.model.HandResult;
import com.github.jisaaa.poker.game.model.ItemModifier;
import com.github.jisaaa.poker.game.model.ScoreResult;
import com.github.jisaaa.poker.game.registry.ItemModifierRegistry;

import java.util.List;
import java.util.Random;

/**
 * Score calculator — v3.1 dual-dimension system (chips × mult).
 *
 * Formula: 最终伤害 = (基础伤害 + 伤害加成) × (基础倍率 + 倍率加成) × 特殊乘数
 *   chips = baseChips + cardChipValues + chipAdd(artifacts/consumables)
 *   mult  = baseMult + multAdd(artifacts/consumables) × multFactor(consumables)
 *   score = chips × mult × critMult(if crit) × specialMult
 *
 * Pure game logic, zero external dependency.
 */
public class ScoreCalculator {

    /** Base crit rate — v3.1: 5% */
    private static final double BASE_CRIT_RATE = 0.05;
    /** Base crit multiplier — v3.1: ×2.0 (was ×1.5) */
    private static final double BASE_CRIT_MULT = 2.0;

    public static ScoreResult calculate(
            HandResult handResult,
            List<Card> playedCards,
            List<JokerState> jokers,
            List<String> consumables,
            long rngSeed) {

        Random rng = new Random(rngSeed);

        // 1. Base chips = hand rank baseChips + card chip values
        int baseChips = handResult.getBaseChips();
        int cardChips = HandEvaluator.sumCardChips(playedCards);
        int chips = baseChips + cardChips;

        // 2. Base mult = hand rank baseMult
        double mult = (double) handResult.getBaseMult();

        // 3. Crit params
        double critRate = BASE_CRIT_RATE;
        double critMult = BASE_CRIT_MULT;
        double specialMult = 1.0;

        // 4. Artifact (joker) modifiers — dual dimension
        for (JokerState joker : jokers) {
            ItemModifier mod = ItemModifierRegistry.getModifier(joker.getId());
            if (mod != null) {
                chips += mod.applyChipAdd(chips, joker.getLevel(), handResult);
                mult += mod.applyMultAdd(joker.getLevel());
                critRate += mod.getCritRateAdd(joker.getLevel());
                critMult += mod.getCritMultAdd(joker.getLevel());
                specialMult *= mod.getSpecialMult(joker.getLevel(), rng);
            }
        }

        // 5. Consumable modifiers
        for (String consumableId : consumables) {
            ItemModifier mod = ItemModifierRegistry.getModifier(consumableId);
            if (mod != null) {
                chips += mod.applyChipAdd(chips, 0, handResult);
                mult += mod.applyMultAdd(0);
                mult *= mod.applyMultFactor(0);
                critRate += mod.getCritRateAdd(0);
                critMult += mod.getCritMultAdd(0);
            }
        }

        // 6. Crit determination
        boolean isCrit = rng.nextDouble() < Math.min(critRate, 1.0);
        if (isCrit) {
            mult *= critMult;
        }

        // 7. Final score = chips × mult × specialMult
        int score = (int) Math.round(chips * mult * specialMult);

        return ScoreResult.builder()
                .score(score)
                .chips(chips)
                .mult(mult)
                .isCrit(isCrit)
                .critMult(critMult)
                .specialMult(specialMult)
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

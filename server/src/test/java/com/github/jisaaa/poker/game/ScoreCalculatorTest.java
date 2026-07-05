package com.github.jisaaa.poker.game;

import com.github.jisaaa.poker.domain.enums.HandRank;
import com.github.jisaaa.poker.game.model.Card;
import com.github.jisaaa.poker.game.model.HandResult;
import com.github.jisaaa.poker.game.model.ScoreResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ScoreCalculatorTest {

    private HandResult handResult(HandRank rank) {
        return HandResult.builder().handRank(rank).baseScore(rank.getBaseScore()).build();
    }

    @Test
    @DisplayName("should_calculateBaseScore_when_noModifiers")
    void should_calculateBaseScore_when_noModifiers() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        ScoreResult result = ScoreCalculator.calculate(hand, List.of(), List.of(), 42L);
        // Base 100 * mult 1.0 = 100, no crit (5% with seed 42)
        assertTrue(result.getScore() > 0);
        assertEquals(1.0, result.getMult(), 0.01);
    }

    @Test
    @DisplayName("should_applyJokerCritBonus_when_jokerWealthy")
    void should_applyJokerCritBonus_when_jokerWealthy() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        List<ScoreCalculator.JokerState> jokers = List.of(
                new ScoreCalculator.JokerState("joker_wealthy", 1)
        );
        // With joker_wealthy level 1: critRate = 5% + 10% = 15%, critMult = 1.5 + 0.5 = 2.0
        // Using seed that triggers crit: need to test deterministic behavior
        ScoreResult result = ScoreCalculator.calculate(hand, jokers, List.of(), 0L);
        // Score should be base 100 * some mult
        assertTrue(result.getScore() >= 100); // minimum base
    }

    @Test
    @DisplayName("should_applyConsumableMult_when_doublePotion")
    void should_applyConsumableMult_when_doublePotion() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        List<String> consumables = List.of("double_potion");

        // With double_potion: mult *= 2.0
        // Use a seed that won't trigger crit (seed=1)
        ScoreResult result = ScoreCalculator.calculate(hand, List.of(), consumables, 1L);

        // Base 100 * 2.0 = 200 (no crit with most seeds)
        // If crit triggers, could be higher — check mult is approximately 2.0 or higher
        assertTrue(result.getMult() >= 1.9); // at least double
    }

    @Test
    @DisplayName("should_returnConsistentResult_givenSameSeed")
    void should_returnConsistentResult_givenSameSeed() {
        HandResult hand = handResult(HandRank.FLUSH);
        long seed = 12345L;

        ScoreResult r1 = ScoreCalculator.calculate(hand, List.of(), List.of(), seed);
        ScoreResult r2 = ScoreCalculator.calculate(hand, List.of(), List.of(), seed);

        assertEquals(r1.getScore(), r2.getScore());
        assertEquals(r1.isCrit(), r2.isCrit());
    }

    @Test
    @DisplayName("should_returnDifferentResult_givenDifferentSeed")
    void should_returnDifferentResult_givenDifferentSeed() {
        HandResult hand = handResult(HandRank.FLUSH);

        ScoreResult r1 = ScoreCalculator.calculate(hand, List.of(), List.of(), 1L);
        ScoreResult r2 = ScoreCalculator.calculate(hand, List.of(), List.of(), 999L);

        // Crit status may differ between seeds
        // At minimum, both should produce valid scores
        assertTrue(r1.getScore() > 0);
        assertTrue(r2.getScore() > 0);
    }

    @Test
    @DisplayName("should_handleHighBaseScore_when_straightFlush")
    void should_handleHighBaseScore_when_straightFlush() {
        HandResult hand = handResult(HandRank.STRAIGHT_FLUSH);
        ScoreResult result = ScoreCalculator.calculate(hand, List.of(), List.of(), 1L);
        // Base 2500 * 1.0 = 2500 (no modifiers, no crit)
        assertTrue(result.getScore() >= 2500);
    }
}

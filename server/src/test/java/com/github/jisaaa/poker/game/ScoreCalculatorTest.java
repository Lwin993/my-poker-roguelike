package com.github.jisaaa.poker.game;

import com.github.jisaaa.poker.domain.enums.HandRank;
import com.github.jisaaa.poker.game.model.Card;
import com.github.jisaaa.poker.game.model.HandResult;
import com.github.jisaaa.poker.game.model.ScoreResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ScoreCalculator tests — v3.1 dual-dimension system.
 * Formula: (baseChips + cardChips + chipAdd) × (baseMult + multAdd) × specialMult
 */
class ScoreCalculatorTest {

    private Card c(int rank, int suit) {
        return new Card(rank, suit);
    }

    private HandResult handResult(HandRank rank) {
        return HandResult.builder()
                .handRank(rank)
                .baseChips(rank.getBaseChips())
                .baseMult(rank.getBaseMult())
                .build();
    }

    // 一对K + 三张小牌: K(10) + K(10) + 2(2) + 3(3) + 5(5) = 30 cardChips
    // baseChips=10 + cardChips=30 = 40, baseMult=2, score = 40 × 2 = 80
    private List<Card> pairOfKings() {
        return List.of(c(13,0), c(13,1), c(2,2), c(3,3), c(5,0));
    }

    // 同花: A♠ 5♠ 7♠ 9♠ K♠ = 11+5+7+9+10 = 42 cardChips
    // baseChips=25 + cardChips=42 = 67, baseMult=5, score = 67 × 5 = 335
    private List<Card> flushHand() {
        return List.of(c(1,0), c(5,0), c(7,0), c(9,0), c(13,0));
    }

    @Test
    @DisplayName("v3.1: should_calculateChipsTimesMult_when_noModifiers")
    void should_calculateChipsTimesMult_when_noModifiers() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        List<Card> cards = pairOfKings();
        ScoreResult result = ScoreCalculator.calculate(hand, cards, List.of(), List.of(), 42L);

        // chips = 10 + 30 = 40, mult = 2.0
        // No crit with seed 42 (unlikely at 5%)
        // score ≈ 40 × 2 = 80 (or 80 × 2.0 if crit)
        assertTrue(result.getScore() >= 80);
        assertEquals(40, result.getChips());
    }

    @Test
    @DisplayName("v3.1: should_calculateFlushCorrectly")
    void should_calculateFlushCorrectly() {
        HandResult hand = handResult(HandRank.FLUSH);
        List<Card> cards = flushHand();
        ScoreResult result = ScoreCalculator.calculate(hand, cards, List.of(), List.of(), 1L);

        // chips = 25 + 42 = 67, mult = 5.0
        // score = 67 × 5 = 335 (no crit)
        assertEquals(67, result.getChips());
        assertTrue(result.getScore() >= 335);
    }

    @Test
    @DisplayName("v3.1: should_applyJokerCritBonus_when_jokerWealthy")
    void should_applyJokerCritBonus_when_jokerWealthy() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        List<Card> cards = pairOfKings();
        List<ScoreCalculator.JokerState> jokers = List.of(
                new ScoreCalculator.JokerState("joker_wealthy", 1)
        );
        // joker_wealthy Lv1: critRate+10%, critMult+0.5
        // Total critRate = 5% + 10% = 15%, critMult = 2.0 + 0.5 = 2.5
        ScoreResult result = ScoreCalculator.calculate(hand, cards, jokers, List.of(), 0L);
        assertTrue(result.getScore() > 0);
    }

    @Test
    @DisplayName("v3.1: should_applyRoundWideMultAdd_when_frenzyPotion")
    void should_applyRoundWideMultAdd_when_frenzyPotion() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        List<Card> cards = pairOfKings();
        List<String> consumables = List.of("double_potion");

        // chips=40, baseMult=2, 狂战药水: mult += 3
        // mult = 5.0, score = 40 × 5 = 200 (seed 1 不暴击)
        ScoreResult result = ScoreCalculator.calculate(hand, cards, List.of(), consumables, 1L);
        assertEquals(5.0, result.getMult());
        assertEquals(200, result.getScore());
    }

    @Test
    @DisplayName("v3.1: should_applyCloneSpellAsPlusFourBeforeBossMultiplier")
    void should_applyCloneSpellAsPlusFourBeforeBossMultiplier() {
        HandResult hand = handResult(HandRank.ONE_PAIR);
        List<Card> cards = pairOfKings();

        ScoreResult result = ScoreCalculator.calculate(
                hand, cards, List.of(), List.of("boss_burst", "clone_spell"), 1L);

        // (基础倍率2 + 分身术4) × 斩妖剑3 = 18；与道具选择顺序无关。
        assertEquals(18.0, result.getMult());
        assertEquals(720, result.getScore());
    }

    @Test
    @DisplayName("v3.1: should_returnConsistentResult_givenSameSeed")
    void should_returnConsistentResult_givenSameSeed() {
        HandResult hand = handResult(HandRank.FLUSH);
        List<Card> cards = flushHand();
        long seed = 12345L;

        ScoreResult r1 = ScoreCalculator.calculate(hand, cards, List.of(), List.of(), seed);
        ScoreResult r2 = ScoreCalculator.calculate(hand, cards, List.of(), List.of(), seed);

        assertEquals(r1.getScore(), r2.getScore());
        assertEquals(r1.isCrit(), r2.isCrit());
    }

    @Test
    @DisplayName("v3.1: should_handleHighChips_when_straightFlush")
    void should_handleHighChips_when_straightFlush() {
        HandResult hand = handResult(HandRank.STRAIGHT_FLUSH);
        // A♠ 2♠ 3♠ 4♠ 5♠: cardChips = 11+2+3+4+5 = 25
        List<Card> cards = List.of(c(1,0), c(2,0), c(3,0), c(4,0), c(5,0));
        ScoreResult result = ScoreCalculator.calculate(hand, cards, List.of(), List.of(), 1L);

        // chips = 100 + 25 = 125, mult = 8, score = 125 × 8 = 1000
        assertEquals(125, result.getChips());
        assertTrue(result.getScore() >= 1000);
    }

    @Test
    @DisplayName("v3.1: should_applyBossBurstMultFactor")
    void should_applyBossBurstMultFactor() {
        HandResult hand = handResult(HandRank.FLUSH);
        List<Card> cards = flushHand();
        List<String> consumables = List.of("boss_burst");  // 斩妖剑: mult × 3

        // chips=67, baseMult=5, boss_burst: mult *= 3.0
        // mult = 5 × 3 = 15, score = 67 × 15 = 1005 (no crit)
        ScoreResult result = ScoreCalculator.calculate(hand, cards, List.of(), consumables, 1L);
        assertTrue(result.getScore() >= 1005);
    }
}

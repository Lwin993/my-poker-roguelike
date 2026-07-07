package com.github.jisaaa.poker.game;

import com.github.jisaaa.poker.domain.enums.HandRank;
import com.github.jisaaa.poker.game.model.Card;
import com.github.jisaaa.poker.game.model.HandResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * HandEvaluator tests — v3.1 dual-dimension system.
 * Verifies baseChips + baseMult + cardChips for each hand rank.
 */
class HandEvaluatorTest {

    private Card c(int rank, int suit) {
        return new Card(rank, suit);
    }

    @Test
    @DisplayName("should_returnHighCard_when_noPatterns")
    void should_returnHighCard_when_noPatterns() {
        List<Card> cards = List.of(c(2,0), c(5,1), c(7,2), c(9,3), c(13,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.HIGH_CARD, result.getHandRank());
        assertEquals(5, result.getBaseChips());   // v3.1
        assertEquals(1, result.getBaseMult());    // v3.1: ×1
    }

    @Test
    @DisplayName("should_returnOnePair_when_singlePair")
    void should_returnOnePair_when_singlePair() {
        List<Card> cards = List.of(c(3,0), c(3,1), c(7,2), c(9,3), c(13,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.ONE_PAIR, result.getHandRank());
        assertEquals(10, result.getBaseChips());  // v3.1
        assertEquals(2, result.getBaseMult());    // v3.1: ×2
    }

    @Test
    @DisplayName("should_returnTwoPair_when_twoPairs")
    void should_returnTwoPair_when_twoPairs() {
        List<Card> cards = List.of(c(3,0), c(3,1), c(7,2), c(7,3), c(13,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.TWO_PAIR, result.getHandRank());
        assertEquals(20, result.getBaseChips());  // v3.1
        assertEquals(2, result.getBaseMult());    // v3.1: ×2
    }

    @Test
    @DisplayName("should_returnThreeOfKind_when_threeSame")
    void should_returnThreeOfKind_when_threeSame() {
        List<Card> cards = List.of(c(5,0), c(5,1), c(5,2), c(9,3), c(13,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.THREE_OF_KIND, result.getHandRank());
        assertEquals(30, result.getBaseChips());  // v3.1
        assertEquals(3, result.getBaseMult());    // v3.1: ×3
    }

    @Test
    @DisplayName("should_returnStraight_when_consecutive")
    void should_returnStraight_when_consecutive() {
        List<Card> cards = List.of(c(2,0), c(3,1), c(4,2), c(5,3), c(6,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.STRAIGHT, result.getHandRank());
        assertEquals(30, result.getBaseChips());  // v3.1
        assertEquals(4, result.getBaseMult());    // v3.1: ×4
    }

    @Test
    @DisplayName("should_returnFlush_when_sameSuit")
    void should_returnFlush_when_sameSuit() {
        List<Card> cards = List.of(c(2,2), c(5,2), c(7,2), c(9,2), c(13,2));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.FLUSH, result.getHandRank());
        assertEquals(25, result.getBaseChips());  // v3.1
        assertEquals(5, result.getBaseMult());    // v3.1: ×5
    }

    @Test
    @DisplayName("should_returnFullHouse_when_threeAndTwo")
    void should_returnFullHouse_when_threeAndTwo() {
        List<Card> cards = List.of(c(5,0), c(5,1), c(5,2), c(9,3), c(9,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.FULL_HOUSE, result.getHandRank());
        assertEquals(40, result.getBaseChips());  // v3.1
        assertEquals(4, result.getBaseMult());    // v3.1: ×4
    }

    @Test
    @DisplayName("should_returnFourOfKind_when_fourSame")
    void should_returnFourOfKind_when_fourSame() {
        List<Card> cards = List.of(c(7,0), c(7,1), c(7,2), c(7,3), c(13,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.FOUR_OF_KIND, result.getHandRank());
        assertEquals(60, result.getBaseChips());  // v3.1
        assertEquals(7, result.getBaseMult());    // v3.1: ×7
    }

    @Test
    @DisplayName("should_returnStraightFlush_when_consecutiveSameSuit")
    void should_returnStraightFlush_when_consecutiveSameSuit() {
        List<Card> cards = List.of(c(2,0), c(3,0), c(4,0), c(5,0), c(6,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.STRAIGHT_FLUSH, result.getHandRank());
        assertEquals(100, result.getBaseChips()); // v3.1
        assertEquals(8, result.getBaseMult());    // v3.1: ×8
    }

    @Test
    @DisplayName("should_returnStraight_when_aceLowWheel")
    void should_returnStraight_when_aceLowWheel() {
        List<Card> cards = List.of(c(1,0), c(2,1), c(3,2), c(4,3), c(5,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.STRAIGHT, result.getHandRank());
    }

    @Test
    @DisplayName("should_returnStraight_when_aceHighRoyal")
    void should_returnStraight_when_aceHighRoyal() {
        List<Card> cards = List.of(c(1,0), c(10,1), c(11,2), c(12,3), c(13,0));
        HandResult result = HandEvaluator.evaluate(cards);
        assertEquals(HandRank.STRAIGHT, result.getHandRank());
    }

    @Test
    @DisplayName("should_throwException_when_wrongCardCount")
    void should_throwException_when_wrongCardCount() {
        assertThrows(IllegalArgumentException.class, () -> HandEvaluator.evaluate(List.of(c(1,0), c(2,0))));
        assertThrows(IllegalArgumentException.class, () -> HandEvaluator.evaluate(null));
    }

    // ---- v3.1: Card chip value tests ----

    @Test
    @DisplayName("should_calculateCardChipsCorrectly")
    void should_calculateCardChipsCorrectly() {
        // A=11, 2-10=face, J/Q/K=10
        List<Card> cards = List.of(c(1,0), c(10,1), c(11,2), c(12,3), c(13,0));
        // A(11) + 10 + J(10) + Q(10) + K(10) = 51
        assertEquals(51, HandEvaluator.sumCardChips(cards));
    }

    @Test
    @DisplayName("should_calculateSimpleCardChips")
    void should_calculateSimpleCardChips() {
        List<Card> cards = List.of(c(2,0), c(3,1), c(4,2), c(5,3), c(6,0));
        // 2+3+4+5+6 = 20
        assertEquals(20, HandEvaluator.sumCardChips(cards));
    }
}

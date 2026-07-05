package com.github.jisaaa.poker.game;

import com.github.jisaaa.poker.domain.enums.HandRank;
import com.github.jisaaa.poker.game.model.Card;
import com.github.jisaaa.poker.game.model.HandResult;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Hand evaluator — pure game logic, zero external dependency.
 * Recognizes 9 poker hand ranks.
 */
public class HandEvaluator {

    public static HandResult evaluate(List<Card> cards) {
        if (cards == null || cards.size() != 5) {
            throw new IllegalArgumentException("Must select exactly 5 cards");
        }

        int[] ranks = cards.stream().mapToInt(Card::getRank).sorted().toArray();
        int[] suits = cards.stream().mapToInt(Card::getSuit).toArray();
        boolean flush = isFlush(suits);
        boolean straight = isStraight(ranks);
        int[] counts = countRanks(ranks);

        HandRank rank;
        if (flush && straight)                                        rank = HandRank.STRAIGHT_FLUSH;
        else if (hasCount(counts, 4))                                 rank = HandRank.FOUR_OF_KIND;
        else if (hasCount(counts, 3) && hasCount(counts, 2))         rank = HandRank.FULL_HOUSE;
        else if (flush)                                               rank = HandRank.FLUSH;
        else if (straight)                                            rank = HandRank.STRAIGHT;
        else if (hasCount(counts, 3))                                 rank = HandRank.THREE_OF_KIND;
        else if (countOf(counts, 2) == 2)                             rank = HandRank.TWO_PAIR;
        else if (countOf(counts, 2) == 1)                             rank = HandRank.ONE_PAIR;
        else                                                          rank = HandRank.HIGH_CARD;

        return HandResult.builder()
                .handRank(rank)
                .baseScore(rank.getBaseScore())
                .build();
    }

    private static boolean isFlush(int[] suits) {
        return Arrays.stream(suits).allMatch(s -> s == suits[0]);
    }

    private static boolean isStraight(int[] sorted) {
        // A-2-3-4-5 wheel
        if (Arrays.equals(sorted, new int[]{1, 2, 3, 4, 5})) return true;
        // 10-J-Q-K-A royal straight
        if (Arrays.equals(sorted, new int[]{1, 10, 11, 12, 13})) return true;
        for (int i = 1; i < sorted.length; i++) {
            if (sorted[i] - sorted[i - 1] != 1) return false;
        }
        return true;
    }

    private static int[] countRanks(int[] ranks) {
        Map<Integer, Long> map = Arrays.stream(ranks).boxed()
                .collect(Collectors.groupingBy(r -> r, Collectors.counting()));
        return map.values().stream().mapToInt(Long::intValue).sorted().toArray();
    }

    private static boolean hasCount(int[] counts, int target) {
        return Arrays.stream(counts).anyMatch(c -> c == target);
    }

    private static long countOf(int[] counts, int target) {
        return Arrays.stream(counts).filter(c -> c == target).count();
    }
}

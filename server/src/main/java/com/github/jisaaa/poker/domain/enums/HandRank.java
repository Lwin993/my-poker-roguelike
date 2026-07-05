package com.github.jisaaa.poker.domain.enums;

import lombok.Getter;

@Getter
public enum HandRank {
    HIGH_CARD(0, 50),
    ONE_PAIR(1, 100),
    TWO_PAIR(2, 180),
    THREE_OF_KIND(3, 300),
    STRAIGHT(4, 450),
    FLUSH(5, 600),
    FULL_HOUSE(6, 900),
    FOUR_OF_KIND(7, 1500),
    STRAIGHT_FLUSH(8, 2500);

    private final int code;
    private final int baseScore;

    HandRank(int code, int baseScore) {
        this.code = code;
        this.baseScore = baseScore;
    }
}

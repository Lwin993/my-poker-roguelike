package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Card model — rank 1-13 (1=A, 2-10, 11=J, 12=Q, 13=K), suit 0-3.
 * v3.1: Added getChipValue() for chips×mult dual-dimension system.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Card {
    private int rank; // 1-13 (1=A, 11=J, 12=Q, 13=K)
    private int suit; // 0=clubs, 1=diamonds, 2=hearts, 3=spades

    /**
     * v3.1: Card chip value mapping.
     * A=11, 2-10=face value, J/Q/K=10
     */
    public int getChipValue() {
        if (rank == 1) return 11;   // A
        if (rank >= 11) return 10;  // J/Q/K
        return rank;                // 2-10
    }
}

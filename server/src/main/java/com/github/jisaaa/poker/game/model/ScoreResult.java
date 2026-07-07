package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Score calculation result — v3.1 dual-dimension system.
 * Contains chips and mult breakdown for verification and UI display.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScoreResult {
    private int score;       // final score = chips × mult × special
    private int chips;       // v3.1: total chips (base + card + adds)
    private double mult;     // v3.1: total mult (base + adds × factors)
    private boolean isCrit;
    private double critMult; // v3.1: crit multiplier used (default 2.0)
    private double specialMult; // v3.1: special multiplier
}

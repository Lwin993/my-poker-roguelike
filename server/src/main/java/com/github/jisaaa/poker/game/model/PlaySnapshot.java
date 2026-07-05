package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PlaySnapshot {
    private int handRank;
    private int baseScore;
    private double mult;
    private boolean isCrit;
    private double critMult;
    private double specialMult;
}

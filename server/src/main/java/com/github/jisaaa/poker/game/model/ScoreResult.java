package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScoreResult {
    private int score;
    private boolean isCrit;
    private double mult;
}

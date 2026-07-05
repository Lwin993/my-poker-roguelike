package com.github.jisaaa.poker.domain.dto;

import lombok.Data;

@Data
public class PlaySnapshotDTO {
    private int handRank;
    private int baseScore;
    private double mult;
    private boolean isCrit;
    private double critMult;
    private double specialMult;
}

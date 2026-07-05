package com.github.jisaaa.poker.game.model;

import com.github.jisaaa.poker.domain.enums.HandRank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HandResult {
    private HandRank handRank;
    private int baseScore;
}

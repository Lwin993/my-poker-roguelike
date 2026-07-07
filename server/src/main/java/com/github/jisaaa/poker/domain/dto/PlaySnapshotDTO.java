package com.github.jisaaa.poker.domain.dto;

import lombok.Data;

/**
 * Play snapshot DTO — v3.1 dual-dimension system.
 * Client sends this for server-side score verification.
 */
@Data
public class PlaySnapshotDTO {
    private int handRank;
    private int baseChips;      // v3.1: hand rank base chips (5~100)
    private int cardChips;      // v3.1: sum of card chip values
    private int chips;          // v3.1: total chips (base + card + adds)
    private double baseMult;    // v3.1: hand rank base mult (1~8)
    private double mult;        // v3.1: total mult
    private boolean isCrit;
    private double critMult;
    private double specialMult;

    // ---- Legacy fields (kept for backward compat during migration) ----
    /** @deprecated Use baseChips instead */
    @Deprecated
    private int baseScore;
}

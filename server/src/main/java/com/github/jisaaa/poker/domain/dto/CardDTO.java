package com.github.jisaaa.poker.domain.dto;

import lombok.Data;

@Data
public class CardDTO {
    private int r; // rank 1-13
    private int s; // suit 0-3

    public CardDTO() {}

    public CardDTO(int r, int s) {
        this.r = r;
        this.s = s;
    }
}

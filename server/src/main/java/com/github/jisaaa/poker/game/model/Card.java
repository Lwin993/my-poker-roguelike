package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Card {
    private int rank; // 1-13 (1=A, 11=J, 12=Q, 13=K)
    private int suit; // 0=clubs, 1=diamonds, 2=hearts, 3=spades
}

package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Elite monster passives — v3.1 精英怪被动效果枚举.
 * Each round's elite monster has a unique passive that hinders the player.
 */
@Getter
@AllArgsConstructor
public enum ElitePassive {
    NONE(0, "无", ""),
    LOCK_CARD(1, "骷髅将", "每回合随机1张手牌不可选中"),
    FACE_DOWN(2, "小旋风", "每回合1张手牌背面朝上"),
    FIRST_PLAY_NERF(3, "火灵童", "每回合第1次出牌伤害-25%");

    private final int code;
    private final String name;
    private final String description;

    public static ElitePassive fromRound(int round) {
        switch (round) {
            case 0: return LOCK_CARD;     // R1 骷髅将
            case 1: return FACE_DOWN;     // R2 小旋风
            case 2: return FIRST_PLAY_NERF; // R3 火灵童
            default: return NONE;
        }
    }
}

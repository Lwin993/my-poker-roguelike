package com.github.jisaaa.poker.game.model;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Boss demon skills — v3.1 大妖技能枚举.
 * Each round's boss demon has a unique skill that hinders the player.
 */
@Getter
@AllArgsConstructor
public enum BossSkill {
    NONE(0, "无", ""),
    PHANTOM_CARDS(1, "白骨幻术", "2张手牌不可选"),
    SANDSTORM(2, "风沙走石", "3张手牌背面朝上"),
    HOLY_FIRE(3, "三昧真火", "仅2种牌型可造成伤害");

    private final int code;
    private final String name;
    private final String description;

    public static BossSkill fromRound(int round) {
        switch (round) {
            case 0: return PHANTOM_CARDS;  // 白骨精
            case 1: return SANDSTORM;      // 黄风怪
            case 2: return HOLY_FIRE;       // 红孩儿
            default: return NONE;
        }
    }
}

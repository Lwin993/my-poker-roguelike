package com.github.jisaaa.poker.domain.enums;

import lombok.Getter;

@Getter
public enum ReviveType {
    AD(0, "观看广告"),
    FRIEND(1, "拉好友");

    private final int code;
    private final String desc;

    ReviveType(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }
}

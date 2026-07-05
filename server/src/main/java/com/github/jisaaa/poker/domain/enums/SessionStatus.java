package com.github.jisaaa.poker.domain.enums;

import lombok.Getter;

@Getter
public enum SessionStatus {
    PLAYING(0, "进行中"),
    COMPLETED(1, "已完成"),
    ABANDONED(2, "已放弃");

    private final int code;
    private final String desc;

    SessionStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }
}

package com.github.jisaaa.poker.domain.enums;

import lombok.Getter;

@Getter
public enum ErrorCode {

    SUCCESS(0, "ok"),
    PARAM_INVALID(400, "参数校验失败"),
    UNAUTHORIZED(401, "Token无效或过期"),
    FORBIDDEN(403, "无权限"),

    SESSION_NOT_FOUND(1001, "局记录不存在"),
    SESSION_EXPIRED(1002, "局已结束或超时"),
    SESSION_USER_MISMATCH(1003, "局不属于当前用户"),
    REVIVE_LIMIT_EXCEEDED(1004, "复活次数耗尽"),
    AD_TOKEN_INVALID(1005, "广告回调token无效"),
    AD_TOKEN_EXPIRED(1006, "广告token已过期"),
    AD_TOKEN_USED(1007, "广告token已被消费"),
    FRIEND_UID_INVALID(1008, "好友UID无效"),

    SCORE_CHEAT_DETECTED(2001, "分数校验不通过"),
    HAND_RANK_MISMATCH(2002, "牌型不匹配"),

    COINS_INSUFFICIENT(3001, "游戏积分不足"),
    ITEM_NOT_AVAILABLE(3002, "道具不可购买"),
    ITEM_ALREADY_OWNED(3003, "小丑牌已拥有"),

    REWARD_OUT_OF_STOCK(4001, "奖品库存不足"),
    REWARD_ALREADY_CLAIMED(4002, "奖品已领取"),
    REWARD_TIER_NOT_MATCHED(4003, "分数未达任何奖品档位"),

    CONFIG_LOAD_FAILED(5001, "远程配置加载失败"),
    INTERNAL_ERROR(9999, "未知内部错误");

    private final int code;
    private final String msg;

    ErrorCode(int code, String msg) {
        this.code = code;
        this.msg = msg;
    }
}

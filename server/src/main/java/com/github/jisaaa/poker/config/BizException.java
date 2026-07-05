package com.github.jisaaa.poker.config;

import com.github.jisaaa.poker.domain.enums.ErrorCode;
import lombok.Getter;

@Getter
public class BizException extends RuntimeException {

    private final int code;

    public BizException(ErrorCode errorCode) {
        super(errorCode.getMsg());
        this.code = errorCode.getCode();
    }

    public BizException(int code, String msg) {
        super(msg);
        this.code = code;
    }
}

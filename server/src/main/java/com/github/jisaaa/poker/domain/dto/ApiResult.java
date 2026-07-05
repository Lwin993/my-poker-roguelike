package com.github.jisaaa.poker.domain.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResult<T> {

    private int code;
    private String msg;
    private T data;

    public static <T> ApiResult<T> ok(T data) {
        return ApiResult.<T>builder().code(0).msg("ok").data(data).build();
    }

    public static <T> ApiResult<T> ok() {
        return ApiResult.<T>builder().code(0).msg("ok").build();
    }

    public static <T> ApiResult<T> fail(int code, String msg) {
        return ApiResult.<T>builder().code(code).msg(msg).build();
    }
}

package com.github.jisaaa.poker.controller;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.config.JwtConfig;
import com.github.jisaaa.poker.domain.dto.ApiResult;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.service.RewardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/reward")
@RequiredArgsConstructor
public class RewardController {

    private final RewardService rewardService;
    private final JwtConfig jwtConfig;

    @PostMapping("/claim")
    public ApiResult<RewardService.ClaimResult> claim(
            @RequestHeader("Authorization") String auth,
            @RequestBody Map<String, Object> body) {
        String userId = extractUserId(auth);
        Long sessionId = ((Number) body.get("session_id")).longValue();

        RewardService.ClaimResult result = rewardService.claim(userId, sessionId);
        if (result.isOutOfStock()) {
            return ApiResult.fail(ErrorCode.REWARD_OUT_OF_STOCK.getCode(),
                    ErrorCode.REWARD_OUT_OF_STOCK.getMsg());
        }
        if (result.isAlreadyClaimed()) {
            return ApiResult.fail(ErrorCode.REWARD_ALREADY_CLAIMED.getCode(),
                    ErrorCode.REWARD_ALREADY_CLAIMED.getMsg());
        }
        return ApiResult.ok(result);
    }

    private String extractUserId(String auth) {
        if (auth != null && auth.startsWith("Bearer ")) {
            String uid = jwtConfig.getUserIdFromToken(auth.substring(7));
            if (uid != null) return uid;
        }
        return "demo_user";
    }
}

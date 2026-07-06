package com.github.jisaaa.poker.controller;

import com.github.jisaaa.poker.config.JwtConfig;
import com.github.jisaaa.poker.domain.dto.ApiResult;
import com.github.jisaaa.poker.service.WalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/wallet")
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;
    private final JwtConfig jwtConfig;

    @GetMapping("/balance")
    public ApiResult<Map<String, Object>> balance(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        String userId = extractUserId(auth);
        int goldCoins = walletService.getOrCreateBalance(userId);
        return ApiResult.ok(Map.of("gold_coins", goldCoins));
    }

    private String extractUserId(String auth) {
        if (auth != null && auth.startsWith("Bearer ")) {
            String uid = jwtConfig.getUserIdFromToken(auth.substring(7));
            if (uid != null) return uid;
        }
        return "demo_user";
    }
}

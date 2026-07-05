package com.github.jisaaa.poker.controller;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.config.JwtConfig;
import com.github.jisaaa.poker.domain.dto.ApiResult;
import com.github.jisaaa.poker.domain.dto.ItemDTO;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.service.ShopService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/shop")
@RequiredArgsConstructor
public class ShopController {

    private final ShopService shopService;
    private final JwtConfig jwtConfig;

    @GetMapping("/list")
    public ApiResult<ShopService.ShopListResponse> list(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestParam Long session_id,
            @RequestParam int shop_node,
            @RequestParam(defaultValue = "0") int refresh_count) {
        return ApiResult.ok(shopService.list(session_id, shop_node, refresh_count));
    }

    @PostMapping("/buy")
    public ApiResult<ShopService.BuyItemResponse> buy(
            @RequestHeader("Authorization") String auth,
            @RequestBody Map<String, Object> body) {
        String userId = extractUserId(auth);
        Long sessionId = ((Number) body.get("session_id")).longValue();
        int shopNode = ((Number) body.get("shop_node")).intValue();
        String itemId = (String) body.get("item_id");

        return ApiResult.ok(shopService.buy(userId, sessionId, shopNode, itemId));
    }

    private String extractUserId(String auth) {
        if (auth != null && auth.startsWith("Bearer ")) {
            String uid = jwtConfig.getUserIdFromToken(auth.substring(7));
            if (uid != null) return uid;
        }
        return "demo_user";
    }
}

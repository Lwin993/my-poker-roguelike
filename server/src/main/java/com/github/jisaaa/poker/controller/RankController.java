package com.github.jisaaa.poker.controller;

import com.github.jisaaa.poker.config.JwtConfig;
import com.github.jisaaa.poker.domain.dto.ApiResult;
import com.github.jisaaa.poker.domain.dto.RankEntry;
import com.github.jisaaa.poker.service.RankService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rank")
@RequiredArgsConstructor
public class RankController {

    private final RankService rankService;
    private final JwtConfig jwtConfig;

    @GetMapping("/global")
    public ApiResult<List<RankEntry>> globalRank(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResult.ok(rankService.getGlobalRank(page, size));
    }

    @GetMapping("/friends")
    public ApiResult<List<RankEntry>> friendsRank(
            @RequestHeader(value = "Authorization", required = false) String auth,
            @RequestParam(defaultValue = "20") int size) {
        String userId = extractUserId(auth);
        return ApiResult.ok(rankService.getFriendsRank(userId, size));
    }

    private String extractUserId(String auth) {
        if (auth != null && auth.startsWith("Bearer ")) {
            String uid = jwtConfig.getUserIdFromToken(auth.substring(7));
            if (uid != null) return uid;
        }
        return "demo_user";
    }
}

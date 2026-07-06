package com.github.jisaaa.poker.controller;

import com.github.jisaaa.poker.config.JwtConfig;
import com.github.jisaaa.poker.domain.dto.ApiResult;
import com.github.jisaaa.poker.domain.dto.SubmitPlayRequest;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.entity.RewardTier;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryLeaderboard;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryTokenStore;
import com.github.jisaaa.poker.service.ConfigService;
import com.github.jisaaa.poker.service.GameService;
import com.github.jisaaa.poker.service.RewardService;
import com.github.jisaaa.poker.service.WalletService;
import javax.validation.Valid;
import javax.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/game")
@RequiredArgsConstructor
public class GameController {

    private final GameService gameService;
    private final RewardService rewardService;
    private final ConfigService configService;
    private final InMemoryLeaderboard leaderboard;
    private final InMemoryTokenStore tokenStore;
    private final JwtConfig jwtConfig;
    private final WalletService walletService;

    @PostMapping("/start")
    public ApiResult<Map<String, Object>> startGame(
            @RequestHeader("Authorization") String auth) {
        String userId = extractUserId(auth);
        // Deduct entry cost from wallet (throws GOLD_INSUFFICIENT if balance too low)
        int goldCoinsBalance = walletService.deductEntryCost(userId);
        GameSession session = gameService.startGame(userId);

        Map<String, Object> data = new HashMap<>();
        data.put("session_id", session.getId());
        data.put("rng_seed", session.getRngSeed());
        data.put("gold_coins", goldCoinsBalance);
        data.put("entry_cost", configService.getIntConfig("entry_cost", 10));
        data.put("round_config", buildRoundConfig());
        data.put("item_config", Map.of("items", configService.getAllItems()));
        data.put("reward_config", buildRewardConfig());

        return ApiResult.ok(data);
    }

    @PostMapping("/submit_play")
    public ApiResult<Map<String, Object>> submitPlay(
            @RequestHeader("Authorization") String auth,
            @Valid @RequestBody SubmitPlayRequest req) {
        String userId = extractUserId(auth);
        req.setUserId(userId);
        GameService.PlayVerifyResult verifyResult = gameService.submitPlay(req);

        Map<String, Object> data = new HashMap<>();
        data.put("verified_score", verifyResult.getVerifiedScore());
        data.put("total_score", verifyResult.getTotalScore());
        data.put("is_crit", verifyResult.isCrit());

        return ApiResult.ok(data);
    }

    @PostMapping("/submit_result")
    public ApiResult<Map<String, Object>> submitResult(
            @RequestHeader("Authorization") String auth,
            @RequestBody Map<String, Object> body) {
        String userId = extractUserId(auth);
        Long sessionId = ((Number) body.get("session_id")).longValue();

        GameSession session = gameService.submitResult(userId, sessionId);

        // Exchange total_score for gold coins
        WalletService.ExchangeResult exchangeResult = walletService.exchangeScore(userId, session.getTotalScore());

        Map<String, Object> data = new HashMap<>();
        data.put("total_score", session.getTotalScore());
        data.put("gold_earned", exchangeResult.getGoldEarned());
        data.put("gold_coins", exchangeResult.getGoldCoinsBalance());
        data.put("global_rank", leaderboard.getMyGlobalRank(userId));
        data.put("friend_rank", 1); // Demo simplified

        RewardTier tier = rewardService.matchTier(session.getTotalScore());
        if (tier != null) {
            Map<String, Object> tierMap = new HashMap<>();
            tierMap.put("min_score", tier.getMinScore());
            tierMap.put("max_score", tier.getMaxScore());
            tierMap.put("reward_name", tier.getRewardName());
            tierMap.put("reward_type", tier.getRewardType());
            data.put("reward_tier", tierMap);
        }

        return ApiResult.ok(data);
    }

    @PostMapping("/revive_prepare")
    public ApiResult<Map<String, Object>> revivePrepare(
            @RequestHeader("Authorization") String auth,
            @RequestBody Map<String, Object> body) {
        String userId = extractUserId(auth);
        Long sessionId = ((Number) body.get("session_id")).longValue();
        String token = tokenStore.generateAdToken(userId, sessionId);

        return ApiResult.ok(Map.of("ad_callback_token", token));
    }

    @PostMapping("/revive")
    public ApiResult<Map<String, Object>> revive(
            @RequestHeader("Authorization") String auth,
            @RequestBody Map<String, Object> body) {
        String userId = extractUserId(auth);
        Long sessionId = ((Number) body.get("session_id")).longValue();
        String adToken = (String) body.get("ad_token");

        int count = gameService.revive(userId, sessionId, adToken);
        return ApiResult.ok(Map.of("revive_count", count));
    }

    // --- Helpers ---

    private String extractUserId(String auth) {
        if (auth != null && auth.startsWith("Bearer ")) {
            String token = auth.substring(7);
            String uid = jwtConfig.getUserIdFromToken(token);
            if (uid != null) return uid;
        }
        // Demo fallback: use "demo_user"
        return "demo_user";
    }

    private Map<String, Object> buildRoundConfig() {
        Map<String, Object> config = new HashMap<>();
        config.put("thresholds", configService.getConfigAsJson("round_thresholds"));
        config.put("coin_rewards", configService.getConfigAsJson("coin_rewards"));
        config.put("max_revives", configService.getIntConfig("max_revives", 3));
        return config;
    }

    private List<Map<String, Object>> buildRewardConfig() {
        List<RewardTier> tiers = rewardService.getAllTiers();
        List<Map<String, Object>> result = new java.util.ArrayList<>();
        for (RewardTier t : tiers) {
            Map<String, Object> tierMap = new HashMap<>();
            tierMap.put("min_score", t.getMinScore());
            tierMap.put("max_score", t.getMaxScore());
            tierMap.put("reward_name", t.getRewardName());
            tierMap.put("reward_type", t.getRewardType());
            result.add(tierMap);
        }
        return result;
    }
}

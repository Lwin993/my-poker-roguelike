package com.github.jisaaa.poker.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.dto.SubmitPlayRequest;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.entity.PlayLog;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.domain.enums.SessionStatus;
import com.github.jisaaa.poker.game.HandEvaluator;
import com.github.jisaaa.poker.game.ScoreCalculator;
import com.github.jisaaa.poker.game.model.Card;
import com.github.jisaaa.poker.game.model.HandResult;
import com.github.jisaaa.poker.game.model.ScoreResult;
import com.github.jisaaa.poker.infrastructure.anti_cheat.ScoreAuditLogger;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryLeaderboard;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import com.github.jisaaa.poker.mapper.PlayLogMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class GameService {

    private final GameSessionMapper sessionMapper;
    private final PlayLogMapper playLogMapper;
    private final ScoreAuditLogger auditLogger;
    private final InMemoryLeaderboard leaderboard;
    private final ConfigService configService;
    private final ObjectMapper objectMapper;

    private static final int TOLERANCE = 1;

    /** Start a new game session */
    @Transactional
    public GameSession startGame(String userId) {
        long rngSeed = ThreadLocalRandom.current().nextLong();
        GameSession session = GameSession.builder()
                .userId(userId)
                .startTime(LocalDateTime.now().toString())
                .totalScore(0L)
                .status(SessionStatus.PLAYING.getCode())
                .rngSeed(rngSeed)
                .reviveCount(0)
                .gameCoins(0)
                .jokerStates("[]")
                .ownedConsumables("[]")
                .build();
        sessionMapper.insert(session);
        log.info("Game started: uid={} sid={} seed={}", userId, session.getId(), rngSeed);
        return session;
    }

    /** Submit a play (card hand) and verify score */
    @Transactional
    public PlayVerifyResult submitPlay(SubmitPlayRequest req) {
        GameSession session = sessionMapper.selectById(req.getSessionId());
        if (session == null) throw new BizException(ErrorCode.SESSION_NOT_FOUND);
        if (session.getStatus() != SessionStatus.PLAYING.getCode())
            throw new BizException(ErrorCode.SESSION_EXPIRED);
        if (!session.getUserId().equals(req.getUserId()))
            throw new BizException(ErrorCode.SESSION_USER_MISMATCH);

        // 1. Server-side hand evaluation
        List<Card> cards = req.getCards().stream()
                .map(c -> new Card(c.getR(), c.getS()))
                .collect(Collectors.toList());
        HandResult handResult = HandEvaluator.evaluate(cards);

        if (handResult.getHandRank().getCode() != req.getSnapshot().getHandRank()) {
            auditLogger.logCheat(req, "hand_rank_mismatch",
                    handResult.getHandRank().getCode(), req.getSnapshot().getHandRank());
            throw new BizException(ErrorCode.HAND_RANK_MISMATCH);
        }

        // 2. Build joker states
        List<ScoreCalculator.JokerState> jokers = buildJokerStates(session.getJokerStates());

        // 3. Compute RNG sub-seed
        long rngSeed = computeRngSeed(session.getRngSeed(), req.getRound(), req.getBlind(), req.getPlayIdx());

        // 4. Server-side score recalculation
        ScoreResult serverResult = ScoreCalculator.calculate(
                handResult, jokers, req.getConsumables(), rngSeed
        );

        // 5. Compare
        int diff = Math.abs(serverResult.getScore() - req.getClaimed());
        if (diff > TOLERANCE) {
            auditLogger.logCheat(req, "score_mismatch", serverResult.getScore(), req.getClaimed());
            log.warn("Score mismatch uid={} claimed={} server={} diff={}",
                    req.getUserId(), req.getClaimed(), serverResult.getScore(), diff);
        }

        // 6. Update session total score
        session.setTotalScore(session.getTotalScore() + serverResult.getScore());
        sessionMapper.updateById(session);

        // 7. Log play
        PlayLog playLog = PlayLog.builder()
                .sessionId(req.getSessionId())
                .roundIdx(req.getRound())
                .blindIdx(req.getBlind())
                .playIdx(req.getPlayIdx())
                .cardsJson(toJson(req.getCards()))
                .consumables(toJson(req.getConsumables()))
                .score(req.getClaimed())
                .isCrit(serverResult.isCrit() ? 1 : 0)
                .snapshot(toJson(req.getSnapshot()))
                .serverScore(serverResult.getScore())
                .diff(diff)
                .build();
        playLogMapper.insert(playLog);

        return PlayVerifyResult.builder()
                .verifiedScore(serverResult.getScore())
                .totalScore(session.getTotalScore())
                .isCrit(serverResult.isCrit())
                .build();
    }

    /** Submit final result — complete the game session */
    @Transactional
    public GameSession submitResult(String userId, Long sessionId) {
        GameSession session = sessionMapper.selectById(sessionId);
        if (session == null) throw new BizException(ErrorCode.SESSION_NOT_FOUND);
        if (!session.getUserId().equals(userId)) throw new BizException(ErrorCode.SESSION_USER_MISMATCH);

        // Finalize session
        session.setStatus(SessionStatus.COMPLETED.getCode());
        session.setEndTime(LocalDateTime.now().toString());
        sessionMapper.updateById(session);

        // Update leaderboard
        leaderboard.submitScore(userId, session.getTotalScore());

        log.info("Game completed: uid={} sid={} score={}", userId, sessionId, session.getTotalScore());
        return session;
    }

    /** Revive — Demo simplified (no real ad callback) */
    @Transactional
    public int revive(String userId, Long sessionId, String adToken) {
        GameSession session = sessionMapper.selectById(sessionId);
        if (session == null) throw new BizException(ErrorCode.SESSION_NOT_FOUND);
        if (!session.getUserId().equals(userId))
            throw new BizException(ErrorCode.SESSION_USER_MISMATCH);

        int maxRevives = configService.getIntConfig("max_revives", 3);
        if (session.getReviveCount() >= maxRevives) {
            throw new BizException(ErrorCode.REVIVE_LIMIT_EXCEEDED);
        }

        session.setReviveCount(session.getReviveCount() + 1);
        sessionMapper.updateById(session);
        log.info("Revive: uid={} sid={} count={}", userId, sessionId, session.getReviveCount());
        return session.getReviveCount();
    }

    private long computeRngSeed(long baseSeed, int round, int blind, int playIdx) {
        return baseSeed ^ ((long) round << 16 | (long) blind << 8 | (long) playIdx);
    }

    @SuppressWarnings("unchecked")
    private List<ScoreCalculator.JokerState> buildJokerStates(String jokerStatesJson) {
        try {
            List<List<Object>> raw = objectMapper.readValue(jokerStatesJson, List.class);
            return raw.stream()
                    .map(j -> new ScoreCalculator.JokerState(
                            (String) j.get(0), ((Number) j.get(1)).intValue()))
                    .collect(Collectors.toList());
        } catch (JsonProcessingException e) {
            log.warn("Failed to parse joker states: {}", jokerStatesJson, e);
            return List.of();
        }
    }

    private String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            return "{}";
        }
    }

    /** Result DTO for submit_play — includes both verified score and running total */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class PlayVerifyResult {
        private int verifiedScore;
        private long totalScore;
        private boolean isCrit;
    }
}

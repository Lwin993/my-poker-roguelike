package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.dto.SubmitPlayRequest;
import com.github.jisaaa.poker.domain.dto.CardDTO;
import com.github.jisaaa.poker.domain.dto.PlaySnapshotDTO;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.domain.enums.SessionStatus;
import com.github.jisaaa.poker.infrastructure.anti_cheat.ScoreAuditLogger;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryLeaderboard;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import com.github.jisaaa.poker.mapper.PlayLogMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GameServiceTest {

    @Mock private GameSessionMapper sessionMapper;
    @Mock private PlayLogMapper playLogMapper;
    @Mock private ScoreAuditLogger auditLogger;
    @Mock private InMemoryLeaderboard leaderboard;
    @Mock private ConfigService configService;

    @InjectMocks
    private GameService gameService;

    private final ObjectMapper realObjectMapper = new ObjectMapper();

    private GameSession playingSession;

    @BeforeEach
    void setUp() {
        gameService = new GameService(sessionMapper, playLogMapper, auditLogger, leaderboard, configService, realObjectMapper);
        playingSession = GameSession.builder()
                .id(10001L)
                .userId("user1")
                .status(SessionStatus.PLAYING.getCode())
                .totalScore(0L)
                .rngSeed(12345L)
                .reviveCount(0)
                .gameCoins(100)
                .jokerStates("[]")
                .build();
    }

    // --- startGame ---

    @Test
    @DisplayName("should_createSession_when_startGame")
    void should_createSession_when_startGame() {
        doReturn(1).when(sessionMapper).insert(any(GameSession.class));

        GameSession session = gameService.startGame("user1");

        assertNotNull(session);
        assertEquals("user1", session.getUserId());
        assertEquals(SessionStatus.PLAYING.getCode(), session.getStatus());
        assertEquals(0L, session.getTotalScore());
        verify(sessionMapper).insert(any(GameSession.class));
    }

    // --- submitPlay ---

    @Test
    @DisplayName("should_throwSessionNotFound_when_sessionNotExists")
    void should_throwSessionNotFound_when_sessionNotExists() {
        when(sessionMapper.selectById(99999L)).thenReturn(null);

        SubmitPlayRequest req = new SubmitPlayRequest();
        req.setSessionId(99999L);
        req.setUserId("user1");

        BizException ex = assertThrows(BizException.class, () -> gameService.submitPlay(req));
        assertEquals(ErrorCode.SESSION_NOT_FOUND.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("should_throwSessionExpired_when_sessionCompleted")
    void should_throwSessionExpired_when_sessionCompleted() {
        playingSession.setStatus(SessionStatus.COMPLETED.getCode());
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);

        SubmitPlayRequest req = new SubmitPlayRequest();
        req.setSessionId(10001L);
        req.setUserId("user1");

        BizException ex = assertThrows(BizException.class, () -> gameService.submitPlay(req));
        assertEquals(ErrorCode.SESSION_EXPIRED.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("should_throwSessionUserMismatch_when_wrongUser")
    void should_throwSessionUserMismatch_when_wrongUser() {
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);

        SubmitPlayRequest req = new SubmitPlayRequest();
        req.setSessionId(10001L);
        req.setUserId("hacker");

        BizException ex = assertThrows(BizException.class, () -> gameService.submitPlay(req));
        assertEquals(ErrorCode.SESSION_USER_MISMATCH.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("should_throwHandRankMismatch_when_clientCheatsHandRank")
    void should_throwHandRankMismatch_when_clientCheatsHandRank() {
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);

        SubmitPlayRequest req = buildValidPlayRequest();
        req.getSnapshot().setHandRank(8);

        BizException ex = assertThrows(BizException.class, () -> gameService.submitPlay(req));
        assertEquals(ErrorCode.HAND_RANK_MISMATCH.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("should_returnVerifiedScore_when_validPlay")
    void should_returnVerifiedScore_when_validPlay() {
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);
        doReturn(1).when(sessionMapper).updateById(any(GameSession.class));
        doReturn(1).when(playLogMapper).insert(any(com.github.jisaaa.poker.domain.entity.PlayLog.class));

        SubmitPlayRequest req = buildValidPlayRequest();
        req.getSnapshot().setHandRank(1);
        req.setClaimed(100);

        GameService.PlayVerifyResult result = gameService.submitPlay(req);

        assertNotNull(result);
        assertTrue(result.getVerifiedScore() > 0);
    }

    // --- submitResult ---

    @Test
    @DisplayName("should_completeSession_when_submitResult")
    void should_completeSession_when_submitResult() {
        playingSession.setTotalScore(5000L);
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);
        doReturn(1).when(sessionMapper).updateById(any(GameSession.class));

        GameSession result = gameService.submitResult("user1", 10001L, 5000L);

        assertEquals(SessionStatus.COMPLETED.getCode(), result.getStatus());
        verify(leaderboard).submitScore("user1", 5000L);
    }

    // --- revive ---

    @Test
    @DisplayName("should_throwReviveLimitExceeded_when_maxReached")
    void should_throwReviveLimitExceeded_when_maxReached() {
        playingSession.setReviveCount(3);
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);
        when(configService.getIntConfig("max_revives", 3)).thenReturn(3);

        BizException ex = assertThrows(BizException.class,
                () -> gameService.revive("user1", 10001L, "token"));
        assertEquals(ErrorCode.REVIVE_LIMIT_EXCEEDED.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("should_incrementReviveCount_when_reviveSuccess")
    void should_incrementReviveCount_when_reviveSuccess() {
        playingSession.setReviveCount(0);
        when(sessionMapper.selectById(10001L)).thenReturn(playingSession);
        when(configService.getIntConfig("max_revives", 3)).thenReturn(3);
        doReturn(1).when(sessionMapper).updateById(any(GameSession.class));

        int count = gameService.revive("user1", 10001L, "token");

        assertEquals(1, count);
    }

    // --- Helper ---

    private SubmitPlayRequest buildValidPlayRequest() {
        SubmitPlayRequest req = new SubmitPlayRequest();
        req.setSessionId(10001L);
        req.setUserId("user1");
        req.setRound(0);
        req.setBlind(0);
        req.setPlayIdx(0);
        // Pair of 3s + 3 other cards
        req.setCards(List.of(
                new CardDTO(3, 0), new CardDTO(3, 1),
                new CardDTO(7, 2), new CardDTO(9, 3), new CardDTO(13, 0)
        ));
        req.setConsumables(List.of());
        req.setSnapshot(new PlaySnapshotDTO());
        req.getSnapshot().setHandRank(1);
        req.getSnapshot().setBaseScore(100);
        req.getSnapshot().setMult(1.0);
        req.getSnapshot().setCrit(false);
        req.getSnapshot().setCritMult(1.5);
        req.getSnapshot().setSpecialMult(1.0);
        req.setClaimed(100);
        return req;
    }
}

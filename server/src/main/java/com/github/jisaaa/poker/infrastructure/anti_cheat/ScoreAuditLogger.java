package com.github.jisaaa.poker.infrastructure.anti_cheat;

import com.github.jisaaa.poker.domain.dto.SubmitPlayRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class ScoreAuditLogger {

    public void logCheat(SubmitPlayRequest req, String reason, Object serverValue, Object clientValue) {
        log.warn("CHEAT DETECTED: uid={} sid={} round={}/blind={}/play={} reason={} server={} client={}",
                req.getUserId(), req.getSessionId(), req.getRound(), req.getBlind(), req.getPlayIdx(),
                reason, serverValue, clientValue);
    }
}

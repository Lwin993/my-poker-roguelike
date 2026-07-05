package com.github.jisaaa.poker.infrastructure.cache;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
@Slf4j
public class InMemoryTokenStore {

    private static final long TOKEN_TTL_SECONDS = 300; // 5 minutes
    private final ConcurrentHashMap<String, TokenEntry> tokenStore = new ConcurrentHashMap<>();

    /** Generate ad callback token */
    public String generateAdToken(String userId, Long sessionId) {
        String token = "ad_cb_" + UUID.randomUUID().toString().replace("-", "");
        tokenStore.put(token, new TokenEntry(userId, sessionId,
                System.currentTimeMillis() + TOKEN_TTL_SECONDS * 1000));
        return token;
    }

    /** Consume token (prevent replay) */
    public TokenEntry consumeToken(String callbackToken) {
        TokenEntry entry = tokenStore.remove(callbackToken);
        if (entry == null) return null;
        if (System.currentTimeMillis() > entry.expireAt) return null;
        return entry;
    }

    /** Check if token has been consumed */
    public boolean isAdTokenConsumed(String callbackToken) {
        return !tokenStore.containsKey(callbackToken);
    }

    /** Cleanup expired tokens every 60s */
    @Scheduled(fixedRate = 60_000)
    public void cleanupExpired() {
        long now = System.currentTimeMillis();
        tokenStore.entrySet().removeIf(e -> e.getValue().expireAt < now);
    }

    public int getTokenCount() {
        return tokenStore.size();
    }

    public static class TokenEntry {
        private final String userId;
        private final Long sessionId;
        private final long expireAt;
        public TokenEntry(String userId, Long sessionId, long expireAt) {
            this.userId = userId;
            this.sessionId = sessionId;
            this.expireAt = expireAt;
        }
        public String getUserId() { return userId; }
        public Long getSessionId() { return sessionId; }
        public long getExpireAt() { return expireAt; }
    }
}

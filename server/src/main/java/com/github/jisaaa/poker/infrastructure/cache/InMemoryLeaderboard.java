package com.github.jisaaa.poker.infrastructure.cache;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.dto.RankEntry;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Component
@RequiredArgsConstructor
@Slf4j
public class InMemoryLeaderboard implements CommandLineRunner {

    private final GameSessionMapper sessionMapper;

    private final ConcurrentHashMap<String, Long> scoreMap = new ConcurrentHashMap<>();

    @Override
    public void run(String... args) {
        init();
    }

    /** Rebuild leaderboard from SQLite on startup */
    public void init() {
        List<GameSession> topSessions = sessionMapper.selectList(
            new QueryWrapper<GameSession>()
                .select("user_id", "MAX(total_score) as total_score")
                .eq("status", 1)
                .groupBy("user_id")
        );
        topSessions.forEach(s -> scoreMap.put(s.getUserId(), s.getTotalScore()));
        log.info("Leaderboard initialized with {} users", scoreMap.size());
    }

    /** Submit score, keep only highest */
    public void submitScore(String userId, long score) {
        scoreMap.merge(userId, score, Math::max);
    }

    /** Global leaderboard (paginated) */
    public List<RankEntry> getGlobalTop(int page, int size) {
        int start = (page - 1) * size;
        List<ConcurrentHashMap.Entry<String, Long>> sorted = scoreMap.entrySet().stream()
                .sorted(ConcurrentHashMap.Entry.<String, Long>comparingByValue().reversed())
                .skip(start)
                .limit(size)
                .collect(Collectors.toList());
        return IntStream.range(0, sorted.size())
                .mapToObj(i -> RankEntry.builder()
                        .userId(sorted.get(i).getKey())
                        .score(sorted.get(i).getValue())
                        .rank(start + i + 1)
                        .build())
                .collect(Collectors.toList());
    }

    /** Get personal global rank */
    public long getMyGlobalRank(String userId) {
        Long myScore = scoreMap.get(userId);
        if (myScore == null) return -1L;
        return scoreMap.values().stream()
                .filter(s -> s > myScore)
                .count() + 1;
    }

    /** Friends rank (Demo: same as global top N) */
    public List<RankEntry> getFriendsRank(String userId, int size) {
        return getGlobalTop(1, size);
    }

    public int getTotalUsers() {
        return scoreMap.size();
    }
}

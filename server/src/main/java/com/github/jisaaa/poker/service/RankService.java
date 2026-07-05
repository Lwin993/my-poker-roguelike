package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.dto.ItemDTO;
import com.github.jisaaa.poker.domain.dto.RankEntry;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryLeaderboard;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RankService {

    private final InMemoryLeaderboard leaderboard;
    private final GameSessionMapper sessionMapper;

    public List<RankEntry> getGlobalRank(int page, int size) {
        return leaderboard.getGlobalTop(page, size);
    }

    public long getMyRank(String userId) {
        return leaderboard.getMyGlobalRank(userId);
    }

    public List<RankEntry> getFriendsRank(String userId, int size) {
        return leaderboard.getFriendsRank(userId, size);
    }
}

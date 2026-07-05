package com.github.jisaaa.poker.infrastructure.cache;

import com.github.jisaaa.poker.domain.dto.RankEntry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class InMemoryLeaderboardTest {

    private InMemoryLeaderboard leaderboard;

    @BeforeEach
    void setUp() {
        leaderboard = new InMemoryLeaderboard(null); // null sessionMapper for unit test
    }

    @Test
    @DisplayName("should_keepHighestScore_when_submitTwice")
    void should_keepHighestScore_when_submitTwice() {
        leaderboard.submitScore("user1", 1000);
        leaderboard.submitScore("user1", 2000);
        leaderboard.submitScore("user1", 500); // lower, should be ignored

        List<RankEntry> top = leaderboard.getGlobalTop(1, 10);
        assertEquals(1, top.size());
        assertEquals(2000, top.get(0).getScore());
    }

    @Test
    @DisplayName("should_returnCorrectRankOrder_when_multipleUsers")
    void should_returnCorrectRankOrder_when_multipleUsers() {
        leaderboard.submitScore("user3", 1000);
        leaderboard.submitScore("user1", 3000);
        leaderboard.submitScore("user2", 2000);

        List<RankEntry> top = leaderboard.getGlobalTop(1, 10);
        assertEquals(3, top.size());
        assertEquals("user1", top.get(0).getUserId());
        assertEquals(1, top.get(0).getRank());
        assertEquals("user2", top.get(1).getUserId());
        assertEquals(2, top.get(1).getRank());
        assertEquals("user3", top.get(2).getUserId());
        assertEquals(3, top.get(2).getRank());
    }

    @Test
    @DisplayName("should_returnNegativeOne_when_userNotOnLeaderboard")
    void should_returnNegativeOne_when_userNotOnLeaderboard() {
        assertEquals(-1L, leaderboard.getMyGlobalRank("unknown"));
    }

    @Test
    @DisplayName("should_supportPagination_when_getGlobalTop")
    void should_supportPagination_when_getGlobalTop() {
        for (int i = 0; i < 10; i++) {
            leaderboard.submitScore("user" + i, 1000 + i * 100);
        }

        List<RankEntry> page1 = leaderboard.getGlobalTop(1, 3);
        List<RankEntry> page2 = leaderboard.getGlobalTop(2, 3);

        assertEquals(3, page1.size());
        assertEquals(3, page2.size());
        assertEquals(1, page1.get(0).getRank());
        assertEquals(4, page2.get(0).getRank());
    }

    @Test
    @DisplayName("should_returnTotalUsersCount")
    void should_returnTotalUsersCount() {
        assertEquals(0, leaderboard.getTotalUsers());
        leaderboard.submitScore("user1", 100);
        assertEquals(1, leaderboard.getTotalUsers());
    }
}

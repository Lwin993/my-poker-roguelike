package com.github.jisaaa.poker.controller;

import com.github.jisaaa.poker.domain.dto.ApiResult;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryLeaderboard;
import com.github.jisaaa.poker.infrastructure.cache.InMemoryTokenStore;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class HealthController {

    private final JdbcTemplate jdbc;
    private final InMemoryLeaderboard leaderboard;

    @GetMapping("/health")
    public ApiResult<Map<String, Object>> health() {
        String dbStatus = "OK";
        try {
            jdbc.queryForObject("SELECT 1", Integer.class);
        } catch (Exception e) {
            dbStatus = "FAIL";
        }

        return ApiResult.ok(Map.of(
                "status", "UP",
                "db", dbStatus,
                "cache_entries", leaderboard.getTotalUsers()
        ));
    }
}

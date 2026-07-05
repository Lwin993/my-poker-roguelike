package com.github.jisaaa.poker.infrastructure.cache;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.github.jisaaa.poker.domain.entity.RewardTier;
import com.github.jisaaa.poker.mapper.RewardTierMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

@Component
@RequiredArgsConstructor
@Slf4j
public class InMemoryStockStore implements CommandLineRunner {

    private final RewardTierMapper tierMapper;

    private final ConcurrentHashMap<Integer, AtomicInteger> stockMap = new ConcurrentHashMap<>();

    @Override
    public void run(String... args) {
        init();
    }

    /** Rebuild stock from SQLite on startup */
    public void init() {
        tierMapper.selectList(new QueryWrapper<RewardTier>().eq("is_active", 1))
            .forEach(t -> {
                if (t.getStockLimit() != -1) {
                    stockMap.put(t.getId(),
                        new AtomicInteger(t.getStockLimit() - t.getStockUsed()));
                }
            });
        log.info("Stock store initialized with {} tiers", stockMap.size());
    }

    public boolean decrementIfPositive(int tierId) {
        return stockMap.computeIfAbsent(tierId, k -> new AtomicInteger(-1))
                .decrementAndGet() >= 0;
    }

    public void increment(int tierId) {
        AtomicInteger stock = stockMap.get(tierId);
        if (stock != null) stock.incrementAndGet();
    }

    public void initStock(int tierId, int limit) {
        stockMap.put(tierId, new AtomicInteger(limit));
    }
}

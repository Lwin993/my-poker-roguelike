package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.dto.ItemDTO;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import com.github.jisaaa.poker.game.registry.ItemModifierRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class ShopService {

    private final GameSessionMapper sessionMapper;
    private final ConfigService configService;

    private final ConcurrentHashMap<String, CachedShop> shopCache = new ConcurrentHashMap<>();
    private static final int SHOP_SLOTS = 5;
    private static final long SHOP_CACHE_TTL_MS = 30 * 60_000; // 30 min

    public ShopListResponse list(Long sessionId, int shopNode, int refreshCount) {
        String key = sessionId + ":" + shopNode;
        CachedShop cached = shopCache.get(key);

        List<ItemDTO> items;
        if (cached != null && !cached.isExpired() && refreshCount == 0) {
            items = cached.items;
        } else {
            items = generateShopItems(shopNode);
            shopCache.put(key, new CachedShop(items, System.currentTimeMillis() + SHOP_CACHE_TTL_MS));
        }

        return ShopListResponse.builder()
                .items(items)
                .refreshCost(calculateRefreshCost(refreshCount))
                .hasFreeRefresh(refreshCount == 0)
                .build();
    }

    @Transactional
    public BuyItemResponse buy(String userId, Long sessionId, int shopNode, String itemId) {
        GameSession session = sessionMapper.selectById(sessionId);
        if (session == null) throw new BizException(ErrorCode.SESSION_NOT_FOUND);

        ItemDTO itemConfig = configService.getAllItems().stream()
                .filter(i -> i.getId().equals(itemId))
                .findFirst()
                .orElseThrow(() -> new BizException(ErrorCode.ITEM_NOT_AVAILABLE));

        if (itemConfig.getItemType() == 0 && isJokerOwned(session, itemId)) {
            throw new BizException(ErrorCode.ITEM_ALREADY_OWNED);
        }

        if (session.getGameCoins() < itemConfig.getPrice()) {
            throw new BizException(ErrorCode.COINS_INSUFFICIENT);
        }

        int rows = sessionMapper.deductCoins(sessionId, itemConfig.getPrice());
        if (rows == 0) throw new BizException(ErrorCode.COINS_INSUFFICIENT);

        return BuyItemResponse.builder()
                .remainingCoins(session.getGameCoins() - itemConfig.getPrice())
                .ownedItemId(itemId)
                .build();
    }

    @Scheduled(fixedRate = 5 * 60_000)
    public void cleanupExpiredShopCache() {
        long now = System.currentTimeMillis();
        shopCache.entrySet().removeIf(e -> e.getValue().expireAt < now);
    }

    // --- Internal ---

    private List<ItemDTO> generateShopItems(int shopNode) {
        List<ItemDTO> allItems = configService.getAllItems();
        List<ItemDTO> pool = allItems.stream()
                .filter(i -> i.getItemType() == 0 || i.getItemType() == 1)
                .collect(Collectors.toList());

        List<ItemDTO> selected = new ArrayList<>();
        Random rng = new Random();
        for (int i = 0; i < SHOP_SLOTS && !pool.isEmpty(); i++) {
            int idx = weightedPick(pool, shopNode, rng);
            selected.add(pool.remove(idx));
        }
        return selected;
    }

    private int weightedPick(List<ItemDTO> pool, int shopNode, Random rng) {
        List<Double> weights = pool.stream()
                .map(i -> {
                    List<Integer> w = i.getShopWeights();
                    return (w != null && shopNode < w.size()) ? w.get(shopNode).doubleValue() : 10.0;
                })
                .collect(Collectors.toList());
        double total = weights.stream().mapToDouble(Double::doubleValue).sum();
        double r = rng.nextDouble() * total;
        double cum = 0;
        for (int i = 0; i < pool.size(); i++) {
            cum += weights.get(i);
            if (r <= cum) return i;
        }
        return pool.size() - 1;
    }

    private int calculateRefreshCost(int refreshCount) {
        return 5 + refreshCount * 5; // base=5, increment=5
    }

    @SuppressWarnings("unchecked")
    private boolean isJokerOwned(GameSession session, String itemId) {
        try {
            List<List<Object>> jokers = new com.fasterxml.jackson.databind.ObjectMapper()
                    .readValue(session.getJokerStates(), List.class);
            return jokers.stream().anyMatch(j -> itemId.equals(j.get(0)));
        } catch (Exception e) {
            return false;
        }
    }

    // --- Response DTOs ---

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ShopListResponse {
        private List<ItemDTO> items;
        private int refreshCost;
        private boolean hasFreeRefresh;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BuyItemResponse {
        private int remainingCoins;
        private String ownedItemId;
    }

    private static class CachedShop {
        private final List<ItemDTO> items;
        private final long expireAt;
        CachedShop(List<ItemDTO> items, long expireAt) {
            this.items = items;
            this.expireAt = expireAt;
        }
        boolean isExpired() { return System.currentTimeMillis() > expireAt; }
    }
}

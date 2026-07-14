package com.github.jisaaa.poker.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
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
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();
    private static final int SHOP_SLOTS = 5;
    private static final long SHOP_CACHE_TTL_MS = 30 * 60_000; // 30 min
    private static final Map<String, Integer> COUNTER_ITEM_EXPIRE_SHOP_NODES = Map.of(
            "mirror_reveal", 2,
            "wind_calmer", 5,
            "holy_dew", 8
    );

    public ShopListResponse list(Long sessionId, int shopNode, int refreshCount) {
        GameSession session = sessionMapper.selectById(sessionId);
        Set<String> purchasedRareItems = parsePurchasedItems(session);
        String purchaseFingerprint = String.join(",", new TreeSet<>(purchasedRareItems));
        String key = sessionId + ":" + shopNode + ":" + purchaseFingerprint;
        CachedShop cached = shopCache.get(key);

        List<ItemDTO> items;
        if (cached != null && !cached.isExpired() && refreshCount == 0) {
            items = cached.items;
        } else {
            items = generateShopItems(shopNode, purchasedRareItems);
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

        Set<String> purchasedRareItems = parsePurchasedItems(session);
        if (!isItemEligible(itemConfig, shopNode, purchasedRareItems)) {
            throw new BizException(ErrorCode.ITEM_NOT_AVAILABLE);
        }

        if (itemConfig.getItemType() == 0 && isJokerOwned(session, itemId)) {
            throw new BizException(ErrorCode.ITEM_ALREADY_OWNED);
        }

        if (session.getGameCoins() < itemConfig.getPrice()) {
            throw new BizException(ErrorCode.COINS_INSUFFICIENT);
        }

        int rows = sessionMapper.deductCoins(sessionId, itemConfig.getPrice());
        if (rows == 0) throw new BizException(ErrorCode.COINS_INSUFFICIENT);

        if (itemConfig.getRarity() == 1) {
            purchasedRareItems.add(itemId);
            persistPurchasedItems(session, purchasedRareItems);
            shopCache.keySet().removeIf(key -> key.startsWith(sessionId + ":"));
        }

        return BuyItemResponse.builder()
                .remainingCoins(session.getGameCoins() - itemConfig.getPrice())
                .ownedItemId(itemId)
                .build();
    }

    @Transactional
    public SellItemResponse sell(String userId, Long sessionId, String itemId) {
        GameSession session = sessionMapper.selectById(sessionId);
        if (session == null) throw new BizException(ErrorCode.SESSION_NOT_FOUND);

        ItemDTO itemConfig = configService.getAllItems().stream()
                .filter(i -> i.getId().equals(itemId))
                .findFirst()
                .orElseThrow(() -> new BizException(ErrorCode.ITEM_NOT_AVAILABLE));
        int sellPrice = Math.max(1, itemConfig.getPrice() / 2);
        int rows = sessionMapper.addCoins(sessionId, sellPrice);
        if (rows == 0) throw new BizException(ErrorCode.INTERNAL_ERROR);
        return SellItemResponse.builder()
                .remainingCoins(session.getGameCoins() + sellPrice)
                .soldItemId(itemId)
                .sellPrice(sellPrice)
                .build();
    }

    @Scheduled(fixedRate = 5 * 60_000)
    public void cleanupExpiredShopCache() {
        long now = System.currentTimeMillis();
        shopCache.entrySet().removeIf(e -> e.getValue().expireAt < now);
    }

    // --- Internal ---

    private List<ItemDTO> generateShopItems(int shopNode, Set<String> purchasedRareItems) {
        List<ItemDTO> allItems = configService.getAllItems();
        List<ItemDTO> pool = allItems.stream()
                .filter(i -> i.getItemType() == 0 || i.getItemType() == 1)
                .filter(i -> isItemEligible(i, shopNode, purchasedRareItems))
                .collect(Collectors.toList());

        List<ItemDTO> selected = new ArrayList<>();
        Random rng = new Random();
        for (int i = 0; i < SHOP_SLOTS && !pool.isEmpty(); i++) {
            int idx = weightedPick(pool, shopNode, rng);
            selected.add(pool.remove(idx));
        }
        return selected;
    }

    private boolean isItemEligible(ItemDTO item, int shopNode, Set<String> purchasedRareItems) {
        if (item.getRarity() == 1 && purchasedRareItems.contains(item.getId())) {
            return false;
        }
        Integer expireNode = COUNTER_ITEM_EXPIRE_SHOP_NODES.get(item.getId());
        return expireNode == null || shopNode < expireNode;
    }

    private Set<String> parsePurchasedItems(GameSession session) {
        if (session == null || session.getOwnedConsumables() == null || session.getOwnedConsumables().isBlank()) {
            return new HashSet<>();
        }
        try {
            List<String> ids = OBJECT_MAPPER.readValue(
                    session.getOwnedConsumables(), new TypeReference<List<String>>() {});
            return new HashSet<>(ids);
        } catch (Exception e) {
            log.warn("Failed to parse purchased item history for session {}", session.getId(), e);
            return new HashSet<>();
        }
    }

    private void persistPurchasedItems(GameSession session, Set<String> purchasedItems) {
        try {
            String json = OBJECT_MAPPER.writeValueAsString(new TreeSet<>(purchasedItems));
            int rows = sessionMapper.updateOwnedConsumables(session.getId(), json);
            if (rows == 0) {
                throw new BizException(ErrorCode.INTERNAL_ERROR);
            }
            session.setOwnedConsumables(json);
        } catch (BizException e) {
            throw e;
        } catch (Exception e) {
            throw new BizException(ErrorCode.INTERNAL_ERROR);
        }
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

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SellItemResponse {
        private int remainingCoins;
        private String soldItemId;
        private int sellPrice;
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

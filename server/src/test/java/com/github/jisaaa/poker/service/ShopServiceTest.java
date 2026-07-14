package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.dto.ItemDTO;
import com.github.jisaaa.poker.domain.entity.GameSession;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.mapper.GameSessionMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.List;

@ExtendWith(MockitoExtension.class)
class ShopServiceTest {

    @Mock private GameSessionMapper sessionMapper;
    @Mock private ConfigService configService;

    @InjectMocks
    private ShopService shopService;

    private GameSession session;

    @BeforeEach
    void setUp() {
        session = GameSession.builder()
                .id(10001L)
                .userId("user1")
                .gameCoins(100)
                .jokerStates("[]")
                .ownedConsumables("[]")
                .build();
    }

    @Test
    @DisplayName("should_generateItems_when_listShop")
    void should_generateItems_when_listShop() {
        // ConfigService returns at least some items for shop generation
        when(configService.getAllItems()).thenReturn(java.util.List.of());

        ShopService.ShopListResponse result = shopService.list(10001L, 0, 0);

        assertNotNull(result);
        assertEquals(5, result.getRefreshCost()); // base 5 + 0*5
        assertTrue(result.isHasFreeRefresh());
    }

    @Test
    @DisplayName("should_throwSessionNotFound_when_buyWithInvalidSession")
    void should_throwSessionNotFound_when_buyWithInvalidSession() {
        when(sessionMapper.selectById(99999L)).thenReturn(null);

        BizException ex = assertThrows(BizException.class,
                () -> shopService.buy("user1", 99999L, 0, "joker_wealthy"));
        assertEquals(ErrorCode.SESSION_NOT_FOUND.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("should_throwItemNotAvailable_when_itemNotInConfig")
    void should_throwItemNotAvailable_when_itemNotInConfig() {
        when(sessionMapper.selectById(10001L)).thenReturn(session);
        when(configService.getAllItems()).thenReturn(java.util.List.of());

        BizException ex = assertThrows(BizException.class,
                () -> shopService.buy("user1", 10001L, 0, "nonexistent_item"));
        assertEquals(ErrorCode.ITEM_NOT_AVAILABLE.getCode(), ex.getCode());
    }

    @Test
    @DisplayName("rare item can only be purchased once per game session")
    void should_rejectSecondRarePurchase() {
        ItemDTO rare = item("quint_crit", 1);
        when(sessionMapper.selectById(10001L)).thenReturn(session);
        when(configService.getAllItems()).thenReturn(List.of(rare));
        when(sessionMapper.deductCoins(10001L, rare.getPrice())).thenReturn(1);
        when(sessionMapper.updateOwnedConsumables(eq(10001L), anyString())).thenReturn(1);

        ShopService.BuyItemResponse first = shopService.buy("user1", 10001L, 0, rare.getId());
        assertEquals("quint_crit", first.getOwnedItemId());
        assertTrue(session.getOwnedConsumables().contains("quint_crit"));

        BizException second = assertThrows(BizException.class,
                () -> shopService.buy("user1", 10001L, 1, rare.getId()));
        assertEquals(ErrorCode.ITEM_NOT_AVAILABLE.getCode(), second.getCode());
        verify(sessionMapper, times(1)).deductCoins(10001L, rare.getPrice());
    }

    @Test
    @DisplayName("counter item disappears after its target boss is cleared")
    void should_filterExpiredCounterItemFromShop() {
        session.setOwnedConsumables("[]");
        when(sessionMapper.selectById(10001L)).thenReturn(session);
        when(configService.getAllItems()).thenReturn(List.of(
                item("mirror_reveal", 1), item("normal_1", 0), item("normal_2", 0),
                item("normal_3", 0), item("normal_4", 0), item("normal_5", 0)));

        ShopService.ShopListResponse result = shopService.list(10001L, 2, 1);
        assertEquals(5, result.getItems().size());
        assertTrue(result.getItems().stream().noneMatch(i -> "mirror_reveal".equals(i.getId())));
    }

    @Test
    @DisplayName("selling an item refunds half of its price")
    void should_refundHalfPrice_when_sellItem() {
        ItemDTO item = item("nine_elixir", 0);
        when(sessionMapper.selectById(10001L)).thenReturn(session);
        when(configService.getAllItems()).thenReturn(List.of(item));
        when(sessionMapper.addCoins(10001L, 10)).thenReturn(1);

        ShopService.SellItemResponse result = shopService.sell("user1", 10001L, item.getId());

        assertEquals(10, result.getSellPrice());
        assertEquals(110, result.getRemainingCoins());
        assertEquals(item.getId(), result.getSoldItemId());
        verify(sessionMapper).addCoins(10001L, 10);
    }

    private ItemDTO item(String id, int rarity) {
        return ItemDTO.builder()
                .id(id)
                .displayName(id)
                .description(id)
                .price(20)
                .rarity(rarity)
                .itemType(1)
                .shopWeights(List.of(10, 10, 10, 10, 10, 10, 10, 10, 10))
                .build();
    }
}

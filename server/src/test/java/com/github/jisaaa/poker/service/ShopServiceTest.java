package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
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
}

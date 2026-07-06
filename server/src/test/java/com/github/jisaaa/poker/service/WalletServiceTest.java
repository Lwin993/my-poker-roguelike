package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.entity.UserWallet;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.mapper.UserWalletMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WalletServiceTest {

    @Mock private UserWalletMapper walletMapper;
    @Mock private ConfigService configService;

    @InjectMocks
    private WalletService walletService;

    private static final String USER_ID = "test_user";

    // --- getOrCreateBalance ---

    @Test
    @DisplayName("should_createWalletWithInitialGold_when_userNotExist")
    void should_createWalletWithInitialGold_when_userNotExist() {
        when(configService.getIntConfig("initial_gold_coins", 100)).thenReturn(100);
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(null);
        doReturn(1).when(walletMapper).insert(any(UserWallet.class));

        int balance = walletService.getOrCreateBalance(USER_ID);

        assertEquals(100, balance);
        verify(walletMapper).insert(any(UserWallet.class));
    }

    @Test
    @DisplayName("should_returnExistingBalance_when_walletExists")
    void should_returnExistingBalance_when_walletExists() {
        UserWallet wallet = UserWallet.builder().userId(USER_ID).goldCoins(50).build();
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(wallet);

        int balance = walletService.getOrCreateBalance(USER_ID);

        assertEquals(50, balance);
        verify(walletMapper, never()).insert(any(UserWallet.class));
    }

    // --- deductEntryCost ---

    @Test
    @DisplayName("should_deductAndReturnBalance_when_sufficientGold")
    void should_deductAndReturnBalance_when_sufficientGold() {
        when(configService.getIntConfig("entry_cost", 10)).thenReturn(10);
        when(configService.getIntConfig("initial_gold_coins", 100)).thenReturn(100);
        when(walletMapper.selectByUserId(USER_ID))
                .thenReturn(null)  // for getOrCreateBalance
                .thenReturn(UserWallet.builder().userId(USER_ID).goldCoins(90).build());  // for balance query
        doReturn(1).when(walletMapper).insert(any(UserWallet.class));
        when(walletMapper.deductGoldCoins(USER_ID, 10)).thenReturn(1);

        int balance = walletService.deductEntryCost(USER_ID);

        assertEquals(90, balance);
        verify(walletMapper).deductGoldCoins(USER_ID, 10);
    }

    @Test
    @DisplayName("should_throwGoldInsufficient_when_balanceTooLow")
    void should_throwGoldInsufficient_when_balanceTooLow() {
        when(configService.getIntConfig("entry_cost", 10)).thenReturn(10);
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(UserWallet.builder().userId(USER_ID).goldCoins(5).build());
        when(walletMapper.deductGoldCoins(USER_ID, 10)).thenReturn(0);  // SQL乐观锁返回0行

        BizException ex = assertThrows(BizException.class, () -> walletService.deductEntryCost(USER_ID));
        assertEquals(ErrorCode.GOLD_INSUFFICIENT.getCode(), ex.getCode());
    }

    // --- exchangeScore ---

    @Test
    @DisplayName("should_exchangeScoreToGold_when_totalScorePositive")
    void should_exchangeScoreToGold_when_totalScorePositive() {
        when(configService.getIntConfig("exchange_divisor", 100)).thenReturn(100);
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(UserWallet.builder().userId(USER_ID).goldCoins(90).build());
        when(walletMapper.addGoldCoins(USER_ID, 85)).thenReturn(1);

        WalletService.ExchangeResult result = walletService.exchangeScore(USER_ID, 8500L);

        assertEquals(85, result.getGoldEarned());   // 8500 / 100 = 85
        assertEquals(90, result.getGoldCoinsBalance());
        verify(walletMapper).addGoldCoins(USER_ID, 85);
    }

    @Test
    @DisplayName("should_notAddGold_when_scoreZero")
    void should_notAddGold_when_scoreZero() {
        when(configService.getIntConfig("exchange_divisor", 100)).thenReturn(100);
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(UserWallet.builder().userId(USER_ID).goldCoins(90).build());

        WalletService.ExchangeResult result = walletService.exchangeScore(USER_ID, 0L);

        assertEquals(0, result.getGoldEarned());
        verify(walletMapper, never()).addGoldCoins(anyString(), anyInt());
    }

    @Test
    @DisplayName("should_notAddGold_when_scoreLessThanDivisor")
    void should_notAddGold_when_scoreLessThanDivisor() {
        when(configService.getIntConfig("exchange_divisor", 100)).thenReturn(100);
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(UserWallet.builder().userId(USER_ID).goldCoins(90).build());

        WalletService.ExchangeResult result = walletService.exchangeScore(USER_ID, 50L);

        assertEquals(0, result.getGoldEarned());  // 50 / 100 = 0 (integer division)
        verify(walletMapper, never()).addGoldCoins(anyString(), anyInt());
    }

    @Test
    @DisplayName("should_floorGold_when_scoreNotDivisibleByDivisor")
    void should_floorGold_when_scoreNotDivisibleByDivisor() {
        when(configService.getIntConfig("exchange_divisor", 100)).thenReturn(100);
        when(walletMapper.selectByUserId(USER_ID)).thenReturn(UserWallet.builder().userId(USER_ID).goldCoins(90).build());
        when(walletMapper.addGoldCoins(USER_ID, 84)).thenReturn(1);

        WalletService.ExchangeResult result = walletService.exchangeScore(USER_ID, 8499L);

        assertEquals(84, result.getGoldEarned());  // 8499 / 100 = 84
    }
}

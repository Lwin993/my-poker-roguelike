package com.github.jisaaa.poker.service;

import com.github.jisaaa.poker.config.BizException;
import com.github.jisaaa.poker.domain.entity.UserWallet;
import com.github.jisaaa.poker.domain.enums.ErrorCode;
import com.github.jisaaa.poker.mapper.UserWalletMapper;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
@RequiredArgsConstructor
public class WalletService {

    private final UserWalletMapper walletMapper;
    private final ConfigService configService;

    /** 获取余额，不存在则创建并赠送初始金币 */
    @Transactional
    public int getOrCreateBalance(String userId) {
        UserWallet wallet = walletMapper.selectByUserId(userId);
        if (wallet != null) return wallet.getGoldCoins();
        int initial = configService.getIntConfig("initial_gold_coins", 100);
        UserWallet newWallet = UserWallet.builder()
                .userId(userId)
                .goldCoins(initial)
                .build();
        walletMapper.insert(newWallet);
        log.info("Wallet created for user={}, initial_gold={}", userId, initial);
        return initial;
    }

    // codeflicker-fix: EDGE-Issue-1/dj8jw3oav3b23dnz7vyz — 纯SQL乐观锁扣减，无Java前置检查
    /** 扣减入场费，返回扣减后余额 */
    @Transactional
    public int deductEntryCost(String userId) {
        int entryCost = configService.getIntConfig("entry_cost", 10);
        // 确保钱包存在
        getOrCreateBalance(userId);
        // SQL乐观锁扣减：AND gold_coins >= #{amount}，返回0行表示余额不足
        int rows = walletMapper.deductGoldCoins(userId, entryCost);
        if (rows == 0) {
            throw new BizException(ErrorCode.GOLD_INSUFFICIENT);
        }
        int balance = walletMapper.selectByUserId(userId).getGoldCoins();
        log.info("Entry cost deducted: uid={}, cost={}, balance={}", userId, entryCost, balance);
        return balance;
    }

    // codeflicker-fix: EDGE-Issue-9/dj8jw3oav3b23dnz7vyz — 整数除法替代浮点乘法
    /** 兑换：total_score / exchange_divisor → 外部金币 */
    @Transactional
    public ExchangeResult exchangeScore(String userId, long totalScore) {
        int divisor = configService.getIntConfig("exchange_divisor", 100);
        int goldEarned = (int) (totalScore / Math.max(1, divisor));
        if (goldEarned > 0) {
            walletMapper.addGoldCoins(userId, goldEarned);
        }
        int balance = walletMapper.selectByUserId(userId).getGoldCoins();
        log.info("Score exchanged: uid={}, score={}, gold_earned={}, balance={}", userId, totalScore, goldEarned, balance);
        return new ExchangeResult(goldEarned, balance);
    }

    @Data
    @AllArgsConstructor
    public static class ExchangeResult {
        private int goldEarned;
        private int goldCoinsBalance;
    }
}

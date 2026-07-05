package com.github.jisaaa.poker.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@TableName("game_session")
public class GameSession {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String userId;
    private String startTime;
    private String endTime;
    private Long totalScore;
    private Integer status; // 0=playing 1=completed 2=abandoned
    private Long rngSeed;
    private Integer reviveCount;
    private Integer gameCoins;
    private String jokerStates;   // JSON string
    private String ownedConsumables; // JSON string
    private String createdAt;
    private String updatedAt;
}

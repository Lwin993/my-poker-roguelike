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
@TableName("reward_claim")
public class RewardClaim {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String userId;
    private Long sessionId;
    private Integer tierId;
    private Integer status; // 0=pending 1=fulfilled 2=failed
    private String failReason;
    private String createdAt;
    private String updatedAt;
}

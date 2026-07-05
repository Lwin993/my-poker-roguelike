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
@TableName("reward_tier")
public class RewardTier {
    @TableId(type = IdType.AUTO)
    private Integer id;
    private Long minScore;
    private Long maxScore;
    private String rewardName;
    private String rewardType;
    private Integer stockLimit;
    private Integer stockUsed;
    private Integer isActive;
}

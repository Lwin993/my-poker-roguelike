package com.github.jisaaa.poker.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.github.jisaaa.poker.domain.entity.RewardTier;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface RewardTierMapper extends BaseMapper<RewardTier> {

    @Select("SELECT * FROM reward_tier WHERE is_active = 1 AND min_score <= #{score} AND (max_score >= #{score} OR max_score = -1) ORDER BY min_score DESC LIMIT 1")
    RewardTier selectByScore(@Param("score") long score);

    @Update("UPDATE reward_tier SET stock_used = stock_used + 1 WHERE id = #{tierId}")
    int incrementStockUsed(@Param("tierId") int tierId);
}

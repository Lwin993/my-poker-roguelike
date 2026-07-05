package com.github.jisaaa.poker.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.github.jisaaa.poker.domain.entity.RewardClaim;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface RewardClaimMapper extends BaseMapper<RewardClaim> {

    @Select("SELECT * FROM reward_claim WHERE user_id = #{userId} AND session_id = #{sessionId} LIMIT 1")
    RewardClaim selectByUserAndSession(@Param("userId") String userId, @Param("sessionId") Long sessionId);
}

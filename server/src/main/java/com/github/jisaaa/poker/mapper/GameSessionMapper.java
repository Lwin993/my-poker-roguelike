package com.github.jisaaa.poker.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.github.jisaaa.poker.domain.entity.GameSession;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface GameSessionMapper extends BaseMapper<GameSession> {

    @Update("UPDATE game_session SET game_coins = game_coins - #{amount} WHERE id = #{sessionId} AND game_coins >= #{amount}")
    int deductCoins(@Param("sessionId") Long sessionId, @Param("amount") int amount);

    @Update("UPDATE game_session SET game_coins = game_coins + #{amount} WHERE id = #{sessionId}")
    int addCoins(@Param("sessionId") Long sessionId, @Param("amount") int amount);

    @Update("UPDATE game_session SET joker_states = #{jokerJson} WHERE id = #{sessionId}")
    int updateJokerStates(@Param("sessionId") Long sessionId, @Param("jokerJson") String jokerJson);

    @Update("UPDATE game_session SET owned_consumables = #{consumableJson} WHERE id = #{sessionId}")
    int updateOwnedConsumables(@Param("sessionId") Long sessionId, @Param("consumableJson") String consumableJson);
}

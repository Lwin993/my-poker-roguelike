package com.github.jisaaa.poker.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.github.jisaaa.poker.domain.entity.UserWallet;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface UserWalletMapper extends BaseMapper<UserWallet> {

    @Select("SELECT * FROM user_wallet WHERE user_id = #{userId}")
    UserWallet selectByUserId(@Param("userId") String userId);

    // codeflicker-fix: EDGE-Issue-1/dj8jw3oav3b23dnz7vyz — SQL乐观锁扣减，AND条件防超扣
    @Update("UPDATE user_wallet SET gold_coins = gold_coins - #{amount}, updated_at = datetime('now') " +
            "WHERE user_id = #{userId} AND gold_coins >= #{amount}")
    int deductGoldCoins(@Param("userId") String userId, @Param("amount") int amount);

    @Update("UPDATE user_wallet SET gold_coins = gold_coins + #{amount}, updated_at = datetime('now') " +
            "WHERE user_id = #{userId}")
    int addGoldCoins(@Param("userId") String userId, @Param("amount") int amount);
}

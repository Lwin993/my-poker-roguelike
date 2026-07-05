package com.github.jisaaa.poker.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.github.jisaaa.poker.domain.entity.GameConfig;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface GameConfigMapper extends BaseMapper<GameConfig> {
}

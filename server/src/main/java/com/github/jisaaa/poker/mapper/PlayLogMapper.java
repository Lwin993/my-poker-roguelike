package com.github.jisaaa.poker.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.github.jisaaa.poker.domain.entity.PlayLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface PlayLogMapper extends BaseMapper<PlayLog> {
}

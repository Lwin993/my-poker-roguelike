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
@TableName("play_log")
public class PlayLog {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long sessionId;
    private Integer roundIdx;
    private Integer blindIdx;
    private Integer playIdx;
    private String cardsJson;    // JSON
    private String consumables;  // JSON
    private Integer score;
    private Integer isCrit;      // 0/1
    private String snapshot;     // JSON
    private Integer serverScore;
    private Integer diff;
    private String createdAt;
}

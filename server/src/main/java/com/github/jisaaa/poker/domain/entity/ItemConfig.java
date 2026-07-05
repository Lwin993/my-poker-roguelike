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
@TableName("item_config")
public class ItemConfig {
    @TableId(type = IdType.AUTO)
    private Integer id;
    private String itemId;
    private String configData; // JSON string
    private Integer version;
    private String updatedAt;
}

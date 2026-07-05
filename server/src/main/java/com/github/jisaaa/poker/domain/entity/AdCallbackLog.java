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
@TableName("ad_callback_log")
public class AdCallbackLog {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String transId;
    private String callbackToken;
    private String userId;
    private Long sessionId;
    private String adType;
    private String scene;
    private String createdAt;
}

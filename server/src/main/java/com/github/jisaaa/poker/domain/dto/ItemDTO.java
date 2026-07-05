package com.github.jisaaa.poker.domain.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ItemDTO {
    private String id;
    private String displayName;
    private String description;
    private int price;
    private int rarity;
    private int itemType; // 0=joker 1=consumable
    private List<Integer> shopWeights;
    private List<Integer> upgradeCosts;
    private String effectClass;
    private List<Object> levelParams;
}

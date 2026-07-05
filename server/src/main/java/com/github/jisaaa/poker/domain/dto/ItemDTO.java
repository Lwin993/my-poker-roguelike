package com.github.jisaaa.poker.domain.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
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
    @JsonProperty("display_name")
    private String displayName;
    private String description;
    private int price;
    private int rarity;
    @JsonProperty("item_type")
    private int itemType; // 0=joker 1=consumable
    @JsonProperty("shop_weights")
    private List<Integer> shopWeights;
    @JsonProperty("upgrade_costs")
    private List<Integer> upgradeCosts;
    @JsonProperty("effect_class")
    private String effectClass;
    @JsonProperty("level_params")
    private List<Object> levelParams;
}

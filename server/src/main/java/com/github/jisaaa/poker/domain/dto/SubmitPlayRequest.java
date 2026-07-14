package com.github.jisaaa.poker.domain.dto;

import javax.validation.constraints.NotNull;
import javax.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class SubmitPlayRequest {

    @NotNull
    private Long sessionId;

    private String userId; // set by JWT filter

    private int round;

    private int blind;

    private int playIdx;

    @NotNull
    private List<CardDTO> cards;

    @Size(max = 3, message = "每场战斗最多携带三个道具")
    private List<String> consumables;

    @NotNull
    private PlaySnapshotDTO snapshot;

    private int claimed;
}

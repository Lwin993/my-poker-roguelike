package com.github.jisaaa.poker.game.registry;

import com.github.jisaaa.poker.domain.enums.HandRank;
import com.github.jisaaa.poker.game.model.HandResult;
import com.github.jisaaa.poker.game.model.ItemModifier;

import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Registry for ItemModifier implementations — v3.1.
 * 4 法宝(artifacts) + remaining consumables from old system.
 * Will be fully updated in Module 5 (道具系统改造).
 */
public class ItemModifierRegistry {

    private static final Map<String, ItemModifier> REGISTRY = new ConcurrentHashMap<>();

    static {
        // ---- v3.1: 4大法宝 ----
        register("artifact_jgb", new JinGuBangModifier());      // 金箍棒
        register("artifact_zjl", new ZiJinLingModifier());      // 紫金铃
        register("artifact_rsg", new RenShenGuoModifier());     // 人参果
        register("artifact_hyjj", new HuoYanJinJingModifier()); // 火眼金睛

        // ---- v3.1: 道具(消耗品) ----
        register("double_potion", new FrenzyPotionModifier());    // 狂战药水: mult+3
        register("boss_burst", new BossBurstModifier());         // 斩妖剑: mult×3
        register("crit_potion", new CritPotionModifier());       // 暴击药水: critMult+2
        register("nine_elixir", new NineElixirModifier());       // 九转金丹: chips+25
        register("clone_spell", new CloneSpellModifier());       // 分身术: mult×2
        register("mirror_reveal", new BossSuppressModifier());   // 照妖镜: 克制白骨精
        register("wind_calmer", new BossSuppressModifier());     // 定风丹: 克制黄风怪
        register("holy_dew", new BossSuppressModifier());        // 净瓶甘露: 克制红孩儿
    }

    public static void register(String id, ItemModifier modifier) {
        REGISTRY.put(id, modifier);
    }

    public static ItemModifier getModifier(String id) {
        return REGISTRY.get(id);
    }
}

// ================================================================
// v3.1: 4大法宝 Modifier 实现
// ================================================================

/** 金箍棒 — +倍率（稳定增伤） */
class JinGuBangModifier implements ItemModifier {
    private static final double[] MULT_ADD = {4.0, 7.0, 11.0};

    @Override
    public double applyMultAdd(int level) {
        return level >= 1 && level <= 3 ? MULT_ADD[level - 1] : 0;
    }
}

/** 紫金铃 — 连锁+倍率（连续同牌型倍率递增）
 *  服务端简化实现：只返回每次叠加值（客户端跟踪实际连续次数）
 *  验证时使用近似值，后续可通过HandContext传递精确连续次数 */
class ZiJinLingModifier implements ItemModifier {
    private static final double[] MULT_PER_STACK = {4.0, 6.0, 9.0};

    @Override
    public double applyMultAdd(int level) {
        // 返回单次叠加值；服务端不跟踪连续次数，由客户端快照验证
        return level >= 1 && level <= 3 ? MULT_PER_STACK[level - 1] : 0;
    }
}

/** 人参果 — 低概率×倍率 */
class RenShenGuoModifier implements ItemModifier {
    private static final double[] BOOM_PROB = {0.05, 0.08, 0.12};
    private static final double[] BOOM_MULT = {10.0, 15.0, 25.0};

    @Override
    public double getSpecialMult(int level, Random rng) {
        double prob = level >= 1 && level <= 3 ? BOOM_PROB[level - 1] : 0;
        double mult = level >= 1 && level <= 3 ? BOOM_MULT[level - 1] : 1.0;
        if (rng.nextDouble() < prob) {
            return mult;
        }
        return 1.0;
    }
}

/** 火眼金睛 — +伤害/指定花色每张牌
 *  服务端简化：不跟踪指定花色，返回0（由客户端chips快照验证） */
class HuoYanJinJingModifier implements ItemModifier {
    private static final int[] CHIP_PER_SUIT_CARD = {4, 7, 12};

    @Override
    public int applyChipAdd(int currentChips, int level, HandResult handResult) {
        // 服务端无法知道指定花色和手牌花色分布
        // 验证依赖客户端chips快照，服务端只验证handRank+最终score
        return 0;
    }
}

// ================================================================
// v3.1: 道具(消耗品) Modifier 实现
// ================================================================

/** 狂战药水 — 回合倍率+3 */
class FrenzyPotionModifier implements ItemModifier {
    @Override
    public double applyMultAdd(int level) {
        return 3.0;
    }
}

/** 斩妖剑 — 大妖回合倍率×3 */
class BossBurstModifier implements ItemModifier {
    @Override
    public double applyMultFactor(int level) {
        return 3.0;
    }
}

/** 暴击药水 — 暴击倍率+2.0 */
class CritPotionModifier implements ItemModifier {
    @Override
    public double getCritMultAdd(int level) {
        return 2.0;
    }
}

/** 九转金丹 — 伤害+25 */
class NineElixirModifier implements ItemModifier {
    @Override
    public int applyChipAdd(int currentChips, int level, HandResult handResult) {
        return 25;
    }
}

/** 分身术 — 倍率×2 */
class CloneSpellModifier implements ItemModifier {
    @Override
    public double applyMultFactor(int level) {
        return 2.0;
    }
}

/** 大妖克制道具(照妖镜/定风丹/净瓶甘露) — 无数值效果，仅压制技能 */
class BossSuppressModifier implements ItemModifier {
    // 克制效果由BossSkillManager在回合开始时检查
    // 服务端验证时不产生数值修改
}

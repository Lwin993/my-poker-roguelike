package com.github.jisaaa.poker.game.registry;

import com.github.jisaaa.poker.game.model.ItemModifier;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Registry for ItemModifier implementations.
 * In Demo, modifiers are hardcoded. Production could load from config.
 */
public class ItemModifierRegistry {

    private static final Map<String, ItemModifier> REGISTRY = new ConcurrentHashMap<>();

    static {
        // Register built-in modifiers
        register("joker_wealthy", new JokerWealthyModifier());
        register("joker_chain", new JokerChainModifier());
        register("joker_boom", new JokerBoomModifier());
        register("lucky_spark", new LuckySparkModifier());
        register("double_potion", new DoublePotionModifier());
    }

    public static void register(String id, ItemModifier modifier) {
        REGISTRY.put(id, modifier);
    }

    public static ItemModifier getModifier(String id) {
        return REGISTRY.get(id);
    }
}

// --- Built-in modifier implementations ---

class JokerWealthyModifier implements ItemModifier {
    // Level params: critRateAdd=0.10/0.18/0.25, critMultAdd=0.5/1.0/1.5
    private static final double[] CRIT_RATE = {0.10, 0.18, 0.25};
    private static final double[] CRIT_MULT = {0.5, 1.0, 1.5};

    @Override
    public double getCritRateAdd(int level) {
        return level >= 1 && level <= 3 ? CRIT_RATE[level - 1] : 0;
    }

    @Override
    public double getCritMultAdd(int level) {
        return level >= 1 && level <= 3 ? CRIT_MULT[level - 1] : 0;
    }
}

class JokerChainModifier implements ItemModifier {
    // Level params: chainMult=0.15/0.25/0.40
    private static final double[] CHAIN_MULT = {0.15, 0.25, 0.40};

    @Override
    public double applyMult(double currentMult, int level, java.util.Random rng) {
        double add = level >= 1 && level <= 3 ? CHAIN_MULT[level - 1] : 0;
        return currentMult + add;
    }
}

class JokerBoomModifier implements ItemModifier {
    // Level params: boomProb=0.03/0.05/0.08, boomMult=10/15/20
    private static final double[] BOOM_PROB = {0.03, 0.05, 0.08};
    private static final double[] BOOM_MULT = {10.0, 15.0, 20.0};

    @Override
    public double applyMult(double currentMult, int level, java.util.Random rng) {
        double prob = level >= 1 && level <= 3 ? BOOM_PROB[level - 1] : 0;
        double mult = level >= 1 && level <= 3 ? BOOM_MULT[level - 1] : 0;
        if (rng.nextDouble() < prob) {
            return currentMult * mult;
        }
        return currentMult;
    }
}

class LuckySparkModifier implements ItemModifier {
    @Override
    public double getCritRateAdd(int level) {
        return 0.20; // +20% crit rate
    }
}

class DoublePotionModifier implements ItemModifier {
    @Override
    public double applyMult(double currentMult, int level, java.util.Random rng) {
        return currentMult * 2.0;
    }
}

# ScoreCalculator.gd - Autoload 分数计算器
# v3.1: chips × mult 双维度伤害系统
# 最终伤害 = (基础伤害 + 伤害加成) × (基础倍率 + 倍率加成) × 特殊乘数
extends Node

# ----------------------------------------------------------------
# 核心计算 — 每次调用独立，不产生任何副作用
# ----------------------------------------------------------------
func calculate(
	hand_result: Dictionary,
	joker_states: Array,
	active_consumables: Array,
	remaining_hand: Array
) -> Dictionary:

	var result_data  = _build_steps(hand_result, joker_states, active_consumables, remaining_hand)
	var final_params = result_data.get("params", {})

	var chips        = float(final_params.get("chips", 0))
	var mult         = final_params.get("mult", 1.0)
	var crit_rate    = final_params.get("crit_rate", 0.05)
	var crit_mult    = final_params.get("crit_mult", 2.0)
	var special_mult = final_params.get("special_mult", 1.0)

	var is_crit = randf() < clampf(crit_rate, 0.0, 1.0)

	var score = chips * mult
	if is_crit: score *= crit_mult
	score *= special_mult
	score *= elite_nerf   # 精英怪首打削弱

	return {
		"score":        int(score),
		"is_crit":      is_crit,
		"chips":        chips,
		"mult":         mult,
		"crit_rate":    crit_rate,
		"crit_mult":    crit_mult,
		"special_mult": special_mult,
		"steps":        result_data.get("steps", []),
		"snapshot": {
			"hand_rank":    hand_result.get("rank", 0),
			"base_chips":   hand_result.get("base_chips", 0),
			"card_chips":   hand_result.get("card_chips", 0),
			"chips":        int(chips),
			"mult":         snappedf(mult, 0.0001),
			"crit_rate":    snappedf(crit_rate, 0.0001),
			"crit_mult":    snappedf(crit_mult, 0.0001),
			"special_mult": snappedf(special_mult, 0.0001),
			"is_crit":      is_crit,
		}
	}

# ----------------------------------------------------------------
# 预览参数 — 供 UI 实时展示，不触发随机暴击
# ----------------------------------------------------------------
func preview_params(
	hand_result: Dictionary,
	joker_states: Array,
	active_consumables: Array,
	remaining_hand: Array
) -> Dictionary:
	var result = _build_steps(hand_result, joker_states, active_consumables, remaining_hand)
	return result.get("params", {"chips": 0, "mult": 1.0, "crit_rate": 0.05, "crit_mult": 2.0, "special_mult": 1.0})

# ----------------------------------------------------------------
# 逐步构建 — 返回 { params: {...}, steps: [...] }
# v3.1: chips = baseChips + cardChips + chipAdd
#       mult  = baseMult + multAdd × multFactor
#       score = chips × mult × critMult(若暴击) × specialMult
# ----------------------------------------------------------------
func _build_steps(
	hand_result: Dictionary,
	joker_states: Array,
	active_consumables: Array,
	remaining_hand: Array
) -> Dictionary:

	var base_chips   = hand_result.get("base_chips", 0)
	var card_chips   = hand_result.get("card_chips", 0)
	var base_mult    = float(hand_result.get("base_mult", 1))

	var chips        = float(base_chips + card_chips)
	var mult         = base_mult
	var crit_rate    = 0.05   # v3.1: 基础暴击率5%
	var crit_mult    = 2.0   # v3.1: 基础暴击倍率×2.0
	var special_mult = 1.0
	var elite_nerf   = 1.0   # 精英怪首打削弱系数
	var steps: Array = []

	# Step 0：基础牌型（chips = baseChips + cardChips, mult = baseMult）
	steps.append({
		"type":       "base",
		"label":      hand_result.get("hand_name", ""),
		"chips":      chips,
		"mult":       mult,
		"crit_rate":  crit_rate,
		"crit_mult":  crit_mult,
		"partial":    int(chips * mult),
		"delta":      {},
	})

	# Step 0.5：精英怪被动效果（火灵童首打-25%）
	if BossSkillManager.is_first_play_nerfed():
		elite_nerf = 0.75
		steps.append({
			"type":      "elite_nerf",
			"label":     "火灵童：首打-25%",
			"chips":     chips,
			"mult":      mult,
			"crit_rate": crit_rate,
			"crit_mult": crit_mult,
			"partial":   int(chips * mult * elite_nerf),
			"delta":     {"special_mult": 0.75},
		})

	# Step 1~M：消耗品/道具直接修改参数
	for item in active_consumables:
		var delta = item.get_score_modifiers()
		var ca    = delta.get("chip_add",       0.0)
		var ma    = delta.get("mult_add",       0.0)
		var mf    = delta.get("mult_factor",    1.0)
		var dcr   = delta.get("crit_rate_add",  0.0)
		var dcm   = delta.get("crit_mult_add",  0.0)

		chips     += ca
		mult      += ma
		mult      *= mf
		crit_rate += dcr
		crit_mult += dcm

		steps.append({
			"type":      "consumable",
			"label":     item.resource_data.get("display_name", "?"),
			"chips":     chips,
			"mult":      mult,
			"crit_rate": crit_rate,
			"crit_mult": crit_mult,
			"partial":   int(chips * mult),
			"delta":     {
				"chip_add":      ca,
				"mult_add":      ma,
				"mult_factor":   mf,
				"crit_rate_add": dcr,
				"crit_mult_add": dcm,
			},
		})

	# 余牌加持
	for item in active_consumables:
		if item.resource_data.get("id", "") == "remaining_boost":
			if remaining_hand.size() > 0:
				var max_rank = 0
				for c in remaining_hand:
					if c.rank > max_rank: max_rank = c.rank
				var effective = 14 if max_rank == 1 else max_rank
				mult += float(effective)
				steps.append({
					"type":      "remain_boost",
					"label":     "余牌加持(+%d)" % effective,
					"chips":     chips,
					"mult":      mult,
					"crit_rate": crit_rate,
					"crit_mult": crit_mult,
					"partial":   int(chips * mult),
					"delta":     {"mult_add": float(effective)},
				})
			break

	# Step M+1~N：每张法宝按顺序触发
	for js in joker_states:
		var delta = js.get_passive_modifiers(hand_result)
		var ca    = delta.get("chip_add",       0.0)
		var ma    = delta.get("mult_add",       0.0)
		var dcr   = delta.get("crit_rate_add",  0.0)
		var dcm   = delta.get("crit_mult_add",  0.0)
		var dsm   = delta.get("special_mult",   1.0)

		chips        += ca
		mult         += ma
		crit_rate    += dcr
		crit_mult    += dcm
		special_mult *= dsm

		steps.append({
			"type":      "joker",
			"label":     js.resource_data.get("display_name", "?"),
			"level":     js.level,
			"mult":      mult,
			"crit_rate": crit_rate,
			"crit_mult": crit_mult,
			"partial":   int(chips * mult),
			"delta":     {
				"chip_add":      ca,
				"mult_add":      ma,
				"crit_rate_add": dcr,
				"crit_mult_add": dcm,
				"special_mult":  dsm,
			},
		})

	return {
		"params": {
			"chips":        int(chips),
			"mult":         mult,
			"crit_rate":    clampf(crit_rate, 0.0, 1.0),
			"crit_mult":    crit_mult,
			"special_mult": special_mult,
		},
		"steps": steps,
	}

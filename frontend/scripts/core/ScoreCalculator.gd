# ScoreCalculator.gd - Autoload 分数计算器
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

	var base         = float(hand_result.get("base_score", 0))
	var mult         = final_params.get("mult",         1.0)
	var crit_rate    = final_params.get("crit_rate",    0.0)
	var crit_mult    = final_params.get("crit_mult",    2.0)
	var special_mult = final_params.get("special_mult", 1.0)

	var is_crit = randf() < clampf(crit_rate, 0.0, 1.0)

	var score = base * mult
	if is_crit: score *= crit_mult
	score *= special_mult

	return {
		"score":        int(score),
		"is_crit":      is_crit,
		"mult":         mult,
		"crit_rate":    crit_rate,
		"crit_mult":    crit_mult,
		"special_mult": special_mult,
		"steps":        result_data.get("steps", []),
		"snapshot": {
			"hand_rank":    hand_result.get("rank", 0),
			"base_score":   hand_result.get("base_score", 0),
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
	return result.get("params", {"mult": 1.0, "crit_rate": 0.0, "crit_mult": 2.0, "special_mult": 1.0})

# ----------------------------------------------------------------
# 逐步构建 — 返回 { params: {...}, steps: [...] }
# ----------------------------------------------------------------
func _build_steps(
	hand_result: Dictionary,
	joker_states: Array,
	active_consumables: Array,
	remaining_hand: Array
) -> Dictionary:

	var base_score   = hand_result.get("base_score", 0)
	var mult         = 1.0
	var crit_rate    = 0.0
	var crit_mult    = 2.0
	var special_mult = 1.0
	var steps: Array = []

	# Step 0：基础牌型（只有实际有牌型时才加入 step）
	if base_score > 0:
		steps.append({
			"type":       "base",
			"label":      hand_result.get("hand_name", ""),
			"base_score": base_score,
			"mult":       mult,
			"crit_rate":  crit_rate,
			"crit_mult":  crit_mult,
			"partial":    base_score,
			"delta":      {},
		})

	# Step 1~N：每张小丑牌
	for js in joker_states:
		var delta = js.get_passive_modifiers(hand_result)
		var dm    = delta.get("mult_add",      0.0)
		var dcr   = delta.get("crit_rate_add", 0.0)
		var dcm   = delta.get("crit_mult_add", 0.0)
		var dsm   = delta.get("special_mult",  1.0)

		mult         += dm
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
			"partial":   base_score * mult,
			"delta":     {
				"mult_add":      dm,
				"crit_rate_add": dcr,
				"crit_mult_add": dcm,
				"special_mult":  dsm,
			},
		})

	# Step N+1~M：冲分道具
	for item in active_consumables:
		var delta = item.get_score_modifiers()
		var mf    = delta.get("mult_factor",   1.0)
		var ma    = delta.get("mult_add",      0.0)
		var dcr   = delta.get("crit_rate_add", 0.0)
		var dcm   = delta.get("crit_mult_add", 0.0)

		mult      *= mf
		mult      += ma
		crit_rate += dcr
		crit_mult += dcm

		steps.append({
			"type":      "consumable",
			"label":     item.resource_data.get("display_name", "?"),
			"mult":      mult,
			"crit_rate": crit_rate,
			"crit_mult": crit_mult,
			"partial":   base_score * mult,
			"delta":     {
				"mult_factor":   mf,
				"mult_add":      ma,
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
					"mult":      mult,
					"crit_rate": crit_rate,
					"crit_mult": crit_mult,
					"partial":   base_score * mult,
					"delta":     {"mult_add": float(effective)},
				})
			break

	return {
		"params": {
			"mult":         mult,
			"crit_rate":    clampf(crit_rate, 0.0, 1.0),
			"crit_mult":    crit_mult,
			"special_mult": special_mult,
		},
		"steps": steps,
	}

# ScoreCalculator.gd - Autoload 分数计算器
extends Node

func calculate(
	hand_result: Dictionary,
	joker_states: Array,
	active_consumables: Array,
	remaining_hand: Array
) -> Dictionary:

	var base       = float(hand_result.base_score)
	var mult       = 1.0
	var crit_rate  = 0.0
	var crit_mult  = 2.0
	var special_mult = 1.0

	# 1. 小丑牌被动修正
	for js in joker_states:
		var delta = js.get_passive_modifiers(hand_result)
		mult        += delta.get("mult_add", 0.0)
		crit_rate   += delta.get("crit_rate_add", 0.0)
		crit_mult   += delta.get("crit_mult_add", 0.0)
		special_mult *= delta.get("special_mult", 1.0)

	# 2. 冲分道具修正
	for item in active_consumables:
		var delta = item.get_score_modifiers()
		mult        *= delta.get("mult_factor", 1.0)
		mult        += delta.get("mult_add", 0.0)
		crit_rate   += delta.get("crit_rate_add", 0.0)
		crit_mult   += delta.get("crit_mult_add", 0.0)

	# 3. 余牌加持（稀有道具）
	var has_remain_boost = false
	for item in active_consumables:
		if item.resource_data.get("id", "") == "remaining_boost":
			has_remain_boost = true
			break

	if has_remain_boost and remaining_hand.size() > 0:
		var max_rank = 0
		for c in remaining_hand:
			if c.rank > max_rank: max_rank = c.rank
		var effective = max_rank
		if max_rank == 1: effective = 14  # A 当最高
		mult += float(effective)

	# 4. 暴击判断
	var is_crit = randf() < clampf(crit_rate, 0.0, 1.0)

	# 5. 最终分
	var score = base * mult
	if is_crit: score *= crit_mult
	score *= special_mult

	return {
		"score": int(score),
		"is_crit": is_crit,
		"mult": mult,
		"crit_mult": crit_mult if is_crit else 1.0,
		"special_mult": special_mult,
		"snapshot": {
			"hand_rank": hand_result.rank,
			"base_score": hand_result.base_score,
			"mult": snappedf(mult, 0.0001),
			"is_crit": is_crit,
			"crit_mult": snappedf(crit_mult, 0.0001),
			"special_mult": snappedf(special_mult, 0.0001),
		}
	}

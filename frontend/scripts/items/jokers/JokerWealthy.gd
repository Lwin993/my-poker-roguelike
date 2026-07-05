# JokerWealthy.gd — 暴富小丑
extends "res://scripts/items/ItemEffect.gd"

# Level 1: 暴击率+10%, 暴击倍率+0.5
# Level 2: 暴击率+18%, 暴击倍率+1.0
# Level 3: 暴击率+25%, 暴击倍率+1.5
func get_passive_modifiers(_hand_result: Dictionary) -> Dictionary:
	match level:
		1: return {"crit_rate_add": 0.10, "crit_mult_add": 0.5}
		2: return {"crit_rate_add": 0.18, "crit_mult_add": 1.0}
		3: return {"crit_rate_add": 0.25, "crit_mult_add": 1.5}
	return {}

func get_upgrade_cost() -> int:
	match level:
		1: return 40
		2: return 80
	return -1

# QuintCrit.gd — 五连暴击（稀有）：整回合暴击率50%
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {"crit_rate_add": 0.45} # 基础5% + 45% = 50%
func is_round_wide() -> bool:
	return true
func is_consumed() -> bool:
	return true
func get_use_timing() -> String:
	return "round"

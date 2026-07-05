# QuintCrit.gd — 五连暴击（稀有）：整回合暴击率100%
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {"crit_rate_add": 1.0}
func is_round_wide() -> bool:
	return true
func is_consumed() -> bool:
	return false  # 由 ItemManager 回合结束时标记

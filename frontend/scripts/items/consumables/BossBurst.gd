# BossBurst.gd — Boss爆发：Boss回合倍率×3
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	if RoundManager.current_blind == 2:
		return {"mult_factor": 3.0}
	return {}
func is_consumed() -> bool:
	return true
func can_use_now() -> bool:
	return RoundManager.current_blind == 2
func get_unavailable_reason() -> String:
	return "斩妖剑只能在大妖战使用"

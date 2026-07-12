# FinalPlayTicket.gd — 终局出牌券：Boss出牌次数+1
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {"extra_plays": 1}
func is_consumed() -> bool:
	return true
func get_use_timing() -> String:
	return "instant"
func can_use_now() -> bool:
	return RoundManager.current_blind == 2
func get_unavailable_reason() -> String:
	return "终局符只能在大妖战使用"
func apply_special_effect():
	if RoundManager.current_blind == 2:
		RoundManager.plays_left += 1

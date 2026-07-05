# FinalPlayTicket.gd — 终局出牌券：Boss出牌次数+1
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_consumed() -> bool:
	return true
func apply_special_effect():
	if RoundManager.current_blind == 2:
		RoundManager.plays_left += 1

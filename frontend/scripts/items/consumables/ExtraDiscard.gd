# ExtraDiscard.gd — 额外换牌券：换牌次数+1
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_consumed() -> bool:
	return true
func apply_special_effect():
	RoundManager.discards_left += 1

# RemainBoost.gd — 余牌加持（稀有）：剩余手牌最高点数加倍率
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_round_wide() -> bool:
	return true
func is_consumed() -> bool:
	return false

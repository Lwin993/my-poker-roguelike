# ExtraPlayTicket.gd — 额外出牌券：出牌次数+1
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_consumed() -> bool:
	return true
# 特殊效果：使用时增加出牌次数
func apply_special_effect():
	RoundManager.plays_left += 1

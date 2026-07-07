# CloudStep.gd — 筋斗云：手牌上限+1
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"hand_size_add": 1}

func is_consumed() -> bool:
	return false  # 回合持续

func is_round_wide() -> bool:
	return true

# CloudStep.gd — 筋斗云：手牌上限+1（回合持续）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {}  # 不影响分数计算

func apply_special_effect():
	DeckManager.hand_limit += 1
	DeckManager.draw_to_hand_limit()

func is_consumed() -> bool:
	return false  # 回合持续

func is_round_wide() -> bool:
	return true

# CloudStep.gd — 筋斗云：手牌上限+1（回合持续）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"hand_size_add": 1}  # v3.1: tooltip用

func apply_special_effect():
	DeckManager.hand_limit += 1
	DeckManager.draw_to_hand_limit()

func is_consumed() -> bool:
	return true

func is_round_wide() -> bool:
	return true

func get_use_timing() -> String:
	return "instant"

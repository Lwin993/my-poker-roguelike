# FarSight.gd — 千里眼：换牌+2
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"extra_discards": 2}

func is_consumed() -> bool:
	return true

func get_use_timing() -> String:
	return "instant"

func apply_special_effect():
	RoundManager.discards_left += 2

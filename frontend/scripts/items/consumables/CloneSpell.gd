# CloneSpell.gd — 分身术：倍率×2
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"mult_factor": 2.0}

func is_consumed() -> bool:
	return true

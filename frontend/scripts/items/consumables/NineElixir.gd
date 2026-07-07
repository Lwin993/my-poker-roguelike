# NineElixir.gd — 九转金丹：本回合伤害+25
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"chip_add": 25.0}

func is_consumed() -> bool:
	return true

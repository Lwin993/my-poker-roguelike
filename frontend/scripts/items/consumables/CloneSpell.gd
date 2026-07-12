# CloneSpell.gd — 分身术：当次出牌倍率+4
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"mult_add": 4.0}

func is_consumed() -> bool:
	return true

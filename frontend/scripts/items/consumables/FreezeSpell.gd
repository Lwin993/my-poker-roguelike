# FreezeSpell.gd — 定身术：出牌+1
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"extra_plays": 1}

func is_consumed() -> bool:
	return true

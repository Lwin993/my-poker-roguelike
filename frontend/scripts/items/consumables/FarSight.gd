# FarSight.gd — 千里眼：换牌+2
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"extra_discards": 2}

func is_consumed() -> bool:
	return true

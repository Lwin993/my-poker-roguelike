# LuckySpark.gd — 幸运火花：暴击率+20%
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {"crit_rate_add": 0.20}
func is_consumed() -> bool:
	return true

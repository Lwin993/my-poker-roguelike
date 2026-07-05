# CritPotion.gd — 暴击药水：暴击倍率+1.0
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {"crit_mult_add": 1.0}
func is_consumed() -> bool:
	return true

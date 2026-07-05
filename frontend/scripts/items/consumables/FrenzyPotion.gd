# FrenzyPotion.gd — 狂热药水：当回合倍率+50%
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {"mult_add": 0.5}
func is_consumed() -> bool:
	return true

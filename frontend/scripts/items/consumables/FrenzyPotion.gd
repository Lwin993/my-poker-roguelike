# FrenzyPotion.gd — 狂战药水：回合倍率+3
# v3.1: 替代旧DoublePotion(倍率×2)，改为固定+3倍率
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"mult_add": 3.0}

func is_consumed() -> bool:
	return true

func is_round_wide() -> bool:
	return true

func get_use_timing() -> String:
	return "round"

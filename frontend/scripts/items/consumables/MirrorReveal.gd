# MirrorReveal.gd — 照妖镜：破除白骨幻术1回合
# 克制：白骨精（R1大妖）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"boss_suppress": true}

func is_consumed() -> bool:
	return true

# WindCalmer.gd — 定风丹：免疫遮挡1回合
# 克制：黄风怪（R2大妖）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"boss_suppress": true}

func is_consumed() -> bool:
	return true

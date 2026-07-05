# LuckyCompass.gd — 幸运罗盘：稀有道具出现概率×10
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_consumed() -> bool:
	return true

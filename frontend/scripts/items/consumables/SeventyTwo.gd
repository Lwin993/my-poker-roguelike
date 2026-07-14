# SeventyTwo.gd — 七十二变：随机复制一个法宝 Lv1 效果（当前怪物战临时生效）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {}

func is_consumed() -> bool:
	return true

func get_use_timing() -> String:
	return "instant"

func apply_special_effect() -> String:
	return ItemManager.add_random_temporary_artifact_copy()

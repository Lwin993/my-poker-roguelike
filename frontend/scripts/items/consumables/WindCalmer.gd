# WindCalmer.gd — 定风丹：免疫遮挡1回合
# 克制：黄风怪（R2大妖）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"boss_suppress": true}

func is_consumed() -> bool:
	return true
func is_round_wide() -> bool:
	return true
func get_use_timing() -> String:
	return "round"
func can_use_now() -> bool:
	return BossSkillManager.does_consumable_counter_skill("wind_calmer")
func get_unavailable_reason() -> String:
	return "定风丹只能在黄风怪战使用"

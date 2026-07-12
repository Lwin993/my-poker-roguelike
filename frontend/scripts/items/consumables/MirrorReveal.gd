# MirrorReveal.gd — 照妖镜：破除白骨幻术1回合
# 克制：白骨精（R1大妖）
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
	return BossSkillManager.does_consumable_counter_skill("mirror_reveal")
func get_unavailable_reason() -> String:
	return "照妖镜只能在白骨精战使用"

# HolyDew.gd — 净瓶甘露：熄灭三昧真火1回合
# 克制：红孩儿（R3大妖）
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
	return BossSkillManager.does_consumable_counter_skill("holy_dew")
func get_unavailable_reason() -> String:
	return "净瓶甘露只能在红孩儿战使用"

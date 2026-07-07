# HolyDew.gd — 净瓶甘露：熄灭三昧真火1回合
# 克制：红孩儿（R3大妖）
extends "res://scripts/items/ItemEffect.gd"

func get_score_modifiers() -> Dictionary:
	return {"boss_suppress": true}

func is_consumed() -> bool:
	return true

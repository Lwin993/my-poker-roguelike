# RenShenGuo.gd — 人参果：低概率极高倍率乘数
# 原著灵感：五庄观人参果，三千年一熟
# 对应 Balatro: Space / Brainstorm
# Level 1: 5%概率×10倍率  Level 2: 8%概率×15倍率  Level 3: 12%概率×25倍率
extends "res://scripts/items/ItemEffect.gd"

func get_passive_modifiers(_hand_result: Dictionary) -> Dictionary:
	var prob: float
	var mult: float
	match level:
		1: prob = 0.05; mult = 10.0
		2: prob = 0.08; mult = 15.0
		3: prob = 0.12; mult = 25.0
		_: prob = 0.0; mult = 1.0
	if randf() < prob:
		return {"special_mult": mult}
	return {"special_mult": 1.0}

func get_upgrade_cost() -> int:
	match level:
		1: return 60
		2: return 120
	return -1

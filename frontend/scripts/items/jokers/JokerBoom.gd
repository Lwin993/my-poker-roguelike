# JokerBoom.gd — 爆炸小丑
extends "res://scripts/items/ItemEffect.gd"

# Level 1: 3%概率战斗分×10
# Level 2: 5%概率战斗分×15
# Level 3: 8%概率战斗分×20
func get_passive_modifiers(_hand_result: Dictionary) -> Dictionary:
	var prob: float
	var mult: float
	match level:
		1: prob = 0.03; mult = 10.0
		2: prob = 0.05; mult = 15.0
		3: prob = 0.08; mult = 20.0
		_: prob = 0.0; mult = 1.0
	if randf() < prob:
		return {"special_mult": mult}
	return {"special_mult": 1.0}

func get_upgrade_cost() -> int:
	match level:
		1: return 60
		2: return 120
	return -1

# BaJiaoShan.gd — 芭蕉扇：+倍率（稳定增伤）
# 原著灵感：铁扇公主持有的芭蕉扇，可扇出罡风、熄灭火焰山烈火
# 对应 Balatro: Banner / Steel Joker
# Level 1: +4倍率  Level 2: +7倍率  Level 3: +11倍率
extends "res://scripts/items/ItemEffect.gd"

func get_passive_modifiers(_hand_result: Dictionary) -> Dictionary:
	var bonus: float
	match level:
		1: bonus = 4.0
		2: bonus = 7.0
		3: bonus = 11.0
		_: bonus = 0.0
	return {"mult_add": bonus}

func get_upgrade_cost() -> int:
	match level:
		1: return 40
		2: return 80
	return -1

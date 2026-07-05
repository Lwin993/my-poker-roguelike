# ItemEffect.gd - 道具效果基类
extends RefCounted

var resource_data: Dictionary = {}
var level: int = 1

func get_passive_modifiers(_hand_result: Dictionary) -> Dictionary:
	return {}

func get_score_modifiers() -> Dictionary:
	return {}

func is_round_wide() -> bool:
	return false

func is_consumed() -> bool:
	return false

func get_upgrade_cost() -> int:
	return -1

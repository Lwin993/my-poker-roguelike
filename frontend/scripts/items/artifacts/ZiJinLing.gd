# ZiJinLing.gd — 紫金铃：连锁+倍率（连续同牌型倍率递增）
# 原著灵感：太上老君的铃铛，摇一摇出火，再摇出烟，三摇出沙
# 对应 Balatro: Ride the Bus / Runner
# Level 1: 连续同牌型+4倍率/次  Level 2: +6倍率/次  Level 3: +9倍率/次
extends "res://scripts/items/ItemEffect.gd"

var _consecutive: int = 0
var _last_hand_rank: int = -1

const HAND_NAMES = {
	0: "高牌",
	1: "一对",
	2: "两对",
	3: "三条",
	4: "顺子",
	5: "同花",
	6: "葫芦",
	7: "四条",
	8: "同花顺",
}

func get_passive_modifiers(hand_result: Dictionary) -> Dictionary:
	var rank = hand_result.get("rank", -1)
	if rank == _last_hand_rank:
		_consecutive += 1
	else:
		_consecutive = 1
	_last_hand_rank = rank

	var bonus: float
	match level:
		1: bonus = 4.0 * _consecutive
		2: bonus = 6.0 * _consecutive
		3: bonus = 9.0 * _consecutive
		_: bonus = 0.0
	return {"mult_add": bonus}

func get_bonus_per_stack() -> float:
	match level:
		1: return 4.0
		2: return 6.0
		3: return 9.0
	return 0.0

func get_current_bonus() -> float:
	return get_bonus_per_stack() * _consecutive

func get_chain_info() -> Dictionary:
	return {
		"has_chain": _last_hand_rank != -1,
		"hand_name": HAND_NAMES.get(_last_hand_rank, "尚未触发"),
		"consecutive": _consecutive,
		"per_stack": get_bonus_per_stack(),
		"current_bonus": get_current_bonus(),
	}

func get_upgrade_cost() -> int:
	match level:
		1: return 50
		2: return 100
	return -1

# JokerChain.gd — 连锁小丑
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

# Level 1: 连续同牌型每次+0.15倍率
# Level 2: 连续同牌型每次+0.25倍率
# Level 3: 连续同牌型每次+0.40倍率
func get_passive_modifiers(hand_result: Dictionary) -> Dictionary:
	if not hand_result.has("rank"):
		return {"mult_add": get_current_bonus()}

	var rank = hand_result.rank
	if rank == _last_hand_rank:
		_consecutive += 1
	else:
		_consecutive = 1
	_last_hand_rank = rank

	var bonus: float
	match level:
		1: bonus = 0.15 * _consecutive
		2: bonus = 0.25 * _consecutive
		3: bonus = 0.40 * _consecutive
		_: bonus = 0.0
	return {"mult_add": bonus}

func get_bonus_per_stack() -> float:
	match level:
		1: return 0.15
		2: return 0.25
		3: return 0.40
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

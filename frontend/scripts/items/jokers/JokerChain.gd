# JokerChain.gd — 连锁小丑
extends "res://scripts/items/ItemEffect.gd"

var _consecutive: int = 0
var _last_hand_rank: int = -1

# Level 1: 连续同牌型每次+0.15倍率
# Level 2: 连续同牌型每次+0.25倍率
# Level 3: 连续同牌型每次+0.40倍率
func get_passive_modifiers(hand_result: Dictionary) -> Dictionary:
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

func get_upgrade_cost() -> int:
	match level:
		1: return 50
		2: return 100
	return -1

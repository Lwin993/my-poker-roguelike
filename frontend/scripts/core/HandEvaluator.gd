# HandEvaluator.gd - Autoload 牌型识别
extends Node

enum HandRank {
	HIGH_CARD,       # 高牌    基础伤害5  基础倍率×1
	ONE_PAIR,        # 一对    基础伤害10 基础倍率×2
	TWO_PAIR,        # 两对    基础伤害20 基础倍率×2
	THREE_OF_KIND,   # 三条    基础伤害30 基础倍率×3
	STRAIGHT,        # 顺子    基础伤害30 基础倍率×4
	FLUSH,           # 同花    基础伤害25 基础倍率×5
	FULL_HOUSE,      # 葫芦    基础伤害40 基础倍率×4
	FOUR_OF_KIND,    # 四条    基础伤害60 基础倍率×7
	STRAIGHT_FLUSH   # 同花顺  基础伤害100 基础倍率×8
}

# v3.1: 双维度系统 — base_chips + base_mult 替代原 base_score
const BASE_CHIPS: Dictionary = {
	0: 5,    # HIGH_CARD
	1: 10,   # ONE_PAIR
	2: 20,   # TWO_PAIR
	3: 30,   # THREE_OF_KIND
	4: 30,   # STRAIGHT
	5: 25,   # FLUSH
	6: 40,   # FULL_HOUSE
	7: 60,   # FOUR_OF_KIND
	8: 100,  # STRAIGHT_FLUSH
}

const BASE_MULTS: Dictionary = {
	0: 1,    # HIGH_CARD    ×1
	1: 2,    # ONE_PAIR     ×2
	2: 2,    # TWO_PAIR     ×2
	3: 3,    # THREE_OF_KIND ×3
	4: 4,    # STRAIGHT     ×4
	5: 5,    # FLUSH        ×5
	6: 4,    # FULL_HOUSE   ×4
	7: 7,    # FOUR_OF_KIND ×7
	8: 8,    # STRAIGHT_FLUSH ×8
}

# 保留旧字段名用于向后兼容，后续模块统一替换
const BASE_SCORES: Dictionary = BASE_CHIPS

const HAND_NAMES: Dictionary = {
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

func evaluate(cards: Array) -> Dictionary:
	assert(cards.size() == 5, "出牌必须选 5 张")

	var ranks = []
	var suits = []
	for c in cards:
		ranks.append(c.rank)
		suits.append(c.suit)
	ranks.sort()

	var is_flush    = suits.count(suits[0]) == 5
	var is_straight = _check_straight(ranks)
	var count_map   = _count_ranks(ranks)
	var counts      = count_map.values()
	counts.sort()

	var hand_rank: int
	if   is_flush and is_straight:           hand_rank = HandRank.STRAIGHT_FLUSH
	elif counts == [1, 4]:                   hand_rank = HandRank.FOUR_OF_KIND
	elif counts == [2, 3]:                   hand_rank = HandRank.FULL_HOUSE
	elif is_flush:                           hand_rank = HandRank.FLUSH
	elif is_straight:                        hand_rank = HandRank.STRAIGHT
	elif counts == [1, 1, 3]:               hand_rank = HandRank.THREE_OF_KIND
	elif counts == [1, 2, 2]:               hand_rank = HandRank.TWO_PAIR
	elif counts == [1, 1, 1, 2]:            hand_rank = HandRank.ONE_PAIR
	else:                                    hand_rank = HandRank.HIGH_CARD

	# v3.1: 双维度返回 — base_chips + base_mult
	var base_chips = BASE_CHIPS[hand_rank]
	var base_mult  = BASE_MULTS[hand_rank]
	# 计算手牌面值之和 (A=11, 2-10=点数, J/Q/K=10)
	var card_chips = 0
	for c in cards:
		card_chips += c.get_chip_value()

	return {
		"rank": hand_rank,
		"base_chips": base_chips,
		"base_mult": base_mult,
		"card_chips": card_chips,
		"hand_name": HAND_NAMES[hand_rank],
		"cards": cards,
	}

func _check_straight(sorted_ranks: Array) -> bool:
	if sorted_ranks == [1, 2, 3, 4, 5]: return true
	if sorted_ranks == [1, 10, 11, 12, 13]: return true
	for i in range(1, sorted_ranks.size()):
		if sorted_ranks[i] - sorted_ranks[i - 1] != 1: return false
	return true

func _count_ranks(ranks: Array) -> Dictionary:
	var map = {}
	for r in ranks:
		map[r] = map.get(r, 0) + 1
	return map

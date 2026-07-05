# HandEvaluator.gd - Autoload 牌型识别
extends Node

enum HandRank {
	HIGH_CARD,       # 高牌    基础分 50
	ONE_PAIR,        # 一对    基础分 100
	TWO_PAIR,        # 两对    基础分 180
	THREE_OF_KIND,   # 三条    基础分 300
	STRAIGHT,        # 顺子    基础分 450
	FLUSH,           # 同花    基础分 600
	FULL_HOUSE,      # 葫芦    基础分 900
	FOUR_OF_KIND,    # 四条    基础分 1500
	STRAIGHT_FLUSH   # 同花顺  基础分 2500
}

const BASE_SCORES: Dictionary = {
	0: 50,   # HIGH_CARD
	1: 100,  # ONE_PAIR
	2: 180,  # TWO_PAIR
	3: 300,  # THREE_OF_KIND
	4: 450,  # STRAIGHT
	5: 600,  # FLUSH
	6: 900,  # FULL_HOUSE
	7: 1500, # FOUR_OF_KIND
	8: 2500, # STRAIGHT_FLUSH
}

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

	return {
		"rank": hand_rank,
		"base_score": BASE_SCORES[hand_rank],
		"hand_name": HAND_NAMES[hand_rank],
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

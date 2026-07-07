# DeckManager.gd - Autoload 牌堆/手牌/弃牌区管理
extends Node

class Card:
	var rank: int  # 1=A, 2-10, 11=J, 12=Q, 13=K
	var suit: int  # 0=♠ 1=♥ 2=♦ 3=♣

	func _init(r: int = 1, s: int = 0):
		rank = r
		suit = s

	func serialize() -> Dictionary:
		return {"r": rank, "s": suit}

	static func deserialize(d: Dictionary) -> Card:
		return Card.new(d.get("r", 1), d.get("s", 0))

	func _to_string() -> String:
		const RANKS = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
		const SUITS = ["♠", "♥", "♦", "♣"]
		return RANKS[rank] + SUITS[suit]

	func get_suit_name() -> String:
		const SUIT_NAMES = ["spades", "hearts", "diamonds", "clubs"]
		return SUIT_NAMES[suit]

	func get_rank_name() -> String:
		const RANKS = ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
		return RANKS[rank]

	# v3.1: 牌面值→chips映射 (A=11, 2-10=点数, J/Q/K=10)
	func get_chip_value() -> int:
		if rank == 1:    return 11   # A
		if rank >= 11:   return 10   # J/Q/K
		return rank                 # 2-10

var hand_limit: int = 8  # v3.1: 可被筋斗云临时增加
const DECK_SIZE = 52

var deck: Array = []
var hand: Array = []
var discard_pile: Array = []

func reset():
	hand_limit = 8  # 重置手牌上限
	deck.clear()
	hand.clear()
	discard_pile.clear()
	_init_standard_deck()
	_shuffle()
	draw_to_hand_limit()

func _init_standard_deck():
	for suit in range(4):
		for rank in range(1, 14):
			deck.append(Card.new(rank, suit))

# Fisher-Yates 洗牌，O(n) 无偏
func _shuffle():
	var n = deck.size()
	for i in range(n - 1, 0, -1):
		var j = randi_range(0, i)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp

# 补手牌到上限
func draw_to_hand_limit():
	while hand.size() < hand_limit and deck.size() > 0:
		hand.append(deck.pop_back())
	# 牌堆耗尽：洗回弃牌区
	if deck.size() == 0 and discard_pile.size() > 0:
		deck = discard_pile.duplicate()
		discard_pile.clear()
		_shuffle()
		while hand.size() < hand_limit and deck.size() > 0:
			hand.append(deck.pop_back())

# 出牌：从手牌移走选中的5张，放入弃牌区，补牌
func play_cards(selected_indices: Array) -> Array:
	assert(selected_indices.size() == 5, "必须选5张出牌")

	var sorted_idx = selected_indices.duplicate()
	sorted_idx.sort_custom(func(a, b): return a > b)

	var played: Array = []
	for idx in sorted_idx:
		played.append(hand[idx])
		hand.remove_at(idx)

	discard_pile.append_array(played)
	draw_to_hand_limit()
	return played

# 换牌：从手牌移走选中的牌，弃掉，补新牌
func discard_and_draw(selected_indices: Array) -> void:
	var sorted_idx = selected_indices.duplicate()
	sorted_idx.sort_custom(func(a, b): return a > b)

	for idx in sorted_idx:
		discard_pile.append(hand[idx])
		hand.remove_at(idx)

	draw_to_hand_limit()

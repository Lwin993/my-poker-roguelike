# HuoYanJinJing.gd — 火眼金睛：+伤害/指定花色每张牌
# 原著灵感：八卦炉炼就，看穿妖魔本相
# 对应 Balatro: Greedy/Lusty Jester
# Level 1: 指定花色每张+4伤害  Level 2: +7伤害  Level 3: +12伤害
extends "res://scripts/items/ItemEffect.gd"

var designated_suit: int = 0  # 玩家指定花色(0=♠ 1=♥ 2=♦ 3=♣)

const SUIT_NAMES = ["♠黑桃", "♥红心", "♦方块", "♣梅花"]

func get_passive_modifiers(hand_result: Dictionary) -> Dictionary:
	var chip_add: float = 0.0
	var cards = hand_result.get("cards", [])
	for c in cards:
		if c.suit == designated_suit:
			match level:
				1: chip_add += 4.0
				2: chip_add += 7.0
				3: chip_add += 12.0
	return {"chip_add": chip_add}

func set_designated_suit(suit: int):
	designated_suit = suit

func get_designated_suit_name() -> String:
	return SUIT_NAMES[designated_suit]

func get_upgrade_cost() -> int:
	match level:
		1: return 45
		2: return 90
	return -1

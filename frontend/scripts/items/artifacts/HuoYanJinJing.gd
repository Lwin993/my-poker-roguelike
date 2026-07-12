# HuoYanJinJing.gd — 火眼金睛：看穿妖魔本相，随机指定花色每张牌获得额外伤害
# 原著灵感：太上老君八卦炉炼就，孙悟空因此练就火眼金睛
# 每回合开始时随机指定一种花色，该花色的每张手牌提供额外伤害
# Level 1: 指定花色每张牌 +4 伤害
# Level 2: 指定花色每张牌 +7 伤害
# Level 3: 指定花色每张牌 +12 伤害
extends "res://scripts/items/ItemEffect.gd"

var designated_suit: int = randi() % 4  # 每回合随机花色(0=♠ 1=♥ 2=♦ 3=♣)

const SUIT_NAMES = ["♠黑桃", "♥红心", "♦方块", "♣梅花"]
const CHIP_PER_LEVEL = [0, 4, 7, 12]  # level 0 unused

func get_passive_modifiers(hand_result: Dictionary) -> Dictionary:
	var chip_add: float = 0.0
	var cards = hand_result.get("cards", [])
	var per_card = CHIP_PER_LEVEL[clamp(level, 1, 3)]
	for c in cards:
		if c.suit == designated_suit:
			chip_add += per_card
	return {"chip_add": chip_add}

# 每回合开始时随机刷新指定花色
func randomize_suit():
	designated_suit = randi() % 4

# 预览时显示"每张+N伤害"
func get_preview_modifiers(hand_result: Dictionary) -> Dictionary:
	var per_card = CHIP_PER_LEVEL[clamp(level, 1, 3)]
	if hand_result.get("cards", []).is_empty():
		return {"chip_add": float(per_card), "_preview_per_card": true}
	var result = get_passive_modifiers(hand_result)
	result["_preview_per_card"] = true
	return result

func get_suit_name() -> String:
	return SUIT_NAMES[designated_suit]

# 动态描述，反映当前随机花色和等级
func get_dynamic_description() -> String:
	var suit_name = SUIT_NAMES[designated_suit]
	var per_card  = CHIP_PER_LEVEL[clamp(level, 1, 3)]
	return "本回合指定花色【%s】\n该花色每张出牌 +%d 伤害\n每场怪物战开始随机更换\nLv1:+4  Lv2:+7  Lv3:+12" % [suit_name, per_card]

func get_upgrade_cost() -> int:
	match level:
		1: return 45
		2: return 90
	return -1

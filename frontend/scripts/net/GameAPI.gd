# GameAPI.gd - Autoload HTTP 请求封装（本地 Mock 模式）
extends Node

var session_id: int = 0
var _mock_mode: bool = true  # 本地开发使用 Mock

# 默认 Mock 道具配置
const MOCK_ITEMS = [
	{
		"id": "joker_wealthy", "display_name": "暴富小丑",
		"description": "暴击率+10%，暴击倍率+0.5（可升级）",
		"price": 30, "rarity": 0, "item_type": 0,
		"shop_weights": [30, 25, 20, 15, 10, 5],
		"upgrade_costs": [40, 80], "effect_class": "jokers/JokerWealthy",
	},
	{
		"id": "joker_chain", "display_name": "连锁小丑",
		"description": "记录第一手牌型；连续打出同牌型时，每次提升倍率（可升级）",
		"price": 40, "rarity": 0, "item_type": 0,
		"shop_weights": [25, 25, 25, 20, 15, 10],
		"upgrade_costs": [50, 100], "effect_class": "jokers/JokerChain",
	},
	{
		"id": "joker_boom", "display_name": "爆炸小丑",
		"description": "3%概率战斗分×10（可升级）",
		"price": 50, "rarity": 0, "item_type": 0,
		"shop_weights": [15, 12, 15, 18, 15, 10],
		"upgrade_costs": [60, 120], "effect_class": "jokers/JokerBoom",
	},
	{
		"id": "lucky_spark", "display_name": "幸运火花",
		"description": "本次出牌暴击率+20%",
		"price": 8, "rarity": 0, "item_type": 1,
		"shop_weights": [40, 35, 30, 25, 20, 15],
		"effect_class": "consumables/LuckySpark",
	},
	{
		"id": "crit_potion", "display_name": "暴击药水",
		"description": "本次出牌暴击倍率+1.0",
		"price": 10, "rarity": 0, "item_type": 1,
		"shop_weights": [35, 35, 30, 30, 25, 20],
		"effect_class": "consumables/CritPotion",
	},
	{
		"id": "double_potion", "display_name": "双倍药水",
		"description": "本次出牌倍率×2",
		"price": 12, "rarity": 0, "item_type": 1,
		"shop_weights": [30, 30, 30, 30, 30, 30],
		"effect_class": "consumables/DoublePotion",
	},
	{
		"id": "boss_burst", "display_name": "Boss爆发",
		"description": "Boss回合倍率×3",
		"price": 15, "rarity": 0, "item_type": 1,
		"shop_weights": [0, 15, 0, 18, 0, 20],
		"effect_class": "consumables/BossBurst",
	},
	{
		"id": "frenzy_potion", "display_name": "狂热药水",
		"description": "当回合倍率+50%",
		"price": 12, "rarity": 0, "item_type": 1,
		"shop_weights": [0, 10, 12, 15, 18, 20],
		"effect_class": "consumables/FrenzyPotion",
	},
	{
		"id": "extra_play", "display_name": "额外出牌券",
		"description": "出牌次数+1",
		"price": 10, "rarity": 0, "item_type": 1,
		"shop_weights": [20, 22, 25, 25, 25, 25],
		"effect_class": "consumables/ExtraPlayTicket",
	},
	{
		"id": "final_play", "display_name": "终局出牌券",
		"description": "Boss回合出牌次数+1",
		"price": 15, "rarity": 0, "item_type": 1,
		"shop_weights": [0, 0, 0, 8, 0, 10],
		"effect_class": "consumables/FinalPlayTicket",
	},
	{
		"id": "extra_discard", "display_name": "额外换牌券",
		"description": "换牌次数+1",
		"price": 8, "rarity": 0, "item_type": 1,
		"shop_weights": [25, 25, 25, 25, 25, 25],
		"effect_class": "consumables/ExtraDiscard",
	},
	{
		"id": "refresh_ticket", "display_name": "刷新券",
		"description": "下次商店刷新免费",
		"price": 5, "rarity": 0, "item_type": 1,
		"shop_weights": [30, 30, 30, 30, 30, 30],
		"effect_class": "consumables/RefreshTicket",
	},
	{
		"id": "lucky_compass", "display_name": "幸运罗盘",
		"description": "下次商店稀有道具出现概率×10",
		"price": 15, "rarity": 0, "item_type": 1,
		"shop_weights": [0, 10, 12, 15, 18, 20],
		"effect_class": "consumables/LuckyCompass",
	},
	{
		"id": "quint_crit", "display_name": "五连暴击",
		"description": "【稀有】整回合暴击率100%",
		"price": 30, "rarity": 1, "item_type": 1,
		"shop_weights": [0, 0, 0, 2, 3, 5],
		"effect_class": "consumables/QuintCrit",
	},
	{
		"id": "remaining_boost", "display_name": "余牌加持",
		"description": "【稀有】剩余手牌最高点数加入倍率",
		"price": 25, "rarity": 1, "item_type": 1,
		"shop_weights": [0, 0, 0, 2, 3, 5],
		"effect_class": "consumables/RemainBoost",
	},
]

signal game_started(data: Dictionary)
signal result_submitted(data: Dictionary)

func start_game():
	session_id = randi_range(10000, 99999)
	var mock_response = {
		"round_config": {
			"thresholds": [[300,800,1500],[1500,3000,5000],[3500,6000,10000]],
			"coin_rewards": [[30,50,80],[50,80,120],[80,120,180]],
			"max_revives": 3,
		},
		"item_config": {"items": MOCK_ITEMS},
		"reward_config": ConfigLoader.reward_tiers,
	}
	ConfigLoader.load_from_server(mock_response)
	game_started.emit(mock_response)

func submit_result():
	var tier = ConfigLoader.get_reward_tier(RoundManager.total_score)
	var mock_response = {
		"total_score": RoundManager.total_score,
		"global_rank": randi_range(100, 9999),
		"friend_rank": randi_range(1, 50),
		"reward_tier": tier,
	}
	result_submitted.emit(mock_response)

# 商店列表生成（本地权重计算）
func get_shop_items(shop_node: int, rare_boost: bool = false) -> Array:
	var pool = []
	for item in MOCK_ITEMS:
		var weights = item.get("shop_weights", [])
		var w = weights[shop_node] if shop_node < weights.size() else 0
		if rare_boost and item.get("rarity", 0) == 1:
			w *= 10
		if w > 0:
			pool.append({"item": item, "weight": w})

	# 加入稀有保底逻辑（简化版：直接随机）
	var selected = []
	var pool_copy = pool.duplicate()
	for _i in range(5):
		if pool_copy.is_empty(): break
		var picked = _weighted_pick(pool_copy)
		selected.append(picked.item)
		pool_copy.erase(picked)

	return selected

func _weighted_pick(pool: Array) -> Dictionary:
	var total = 0.0
	for entry in pool:
		total += entry.weight
	var roll = randf() * total
	var cum = 0.0
	for entry in pool:
		cum += entry.weight
		if roll <= cum:
			return entry
	return pool[pool.size() - 1]

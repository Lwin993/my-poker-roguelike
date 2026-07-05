# ConfigLoader.gd - Autoload 远程配置加载（本地 Mock）
extends Node

var _round_config: Dictionary = {}
var _item_configs: Array = []
var _reward_configs: Array = []

# 默认奖品档位（本地 Mock）
var reward_tiers: Array = [
	{"min_score": 0,     "max_score": 999,   "reward_name": "参与奖",     "reward_type": "digital"},
	{"min_score": 1000,  "max_score": 2999,  "reward_name": "雪碧",       "reward_type": "drink"},
	{"min_score": 3000,  "max_score": 5999,  "reward_name": "奶茶",       "reward_type": "drink"},
	{"min_score": 6000,  "max_score": 9999,  "reward_name": "奶茶升级券", "reward_type": "coupon"},
	{"min_score": 10000, "max_score": -1,    "reward_name": "稀有奖品",   "reward_type": "rare"},
]

func load_from_server(data: Dictionary):
	_round_config   = data.get("round_config", {})
	_item_configs   = data.get("item_config", {}).get("items", [])
	_reward_configs = data.get("reward_config", [])

	if _round_config.has("thresholds"):
		RoundManager.thresholds = _round_config.get("thresholds")
	if _round_config.has("coin_rewards"):
		RoundManager.coin_rewards = _round_config.get("coin_rewards")
	if _round_config.has("max_revives"):
		RoundManager.max_revives = _round_config.get("max_revives")

	if _item_configs.size() > 0:
		_rebuild_item_resources()
	if _reward_configs.size() > 0:
		reward_tiers = _reward_configs

func _rebuild_item_resources():
	ItemManager.clear_registered_items()
	for item_data in _item_configs:
		ItemManager.register_item_resource(item_data)

func get_reward_tier(score: int) -> Dictionary:
	for tier in reward_tiers:
		var max_s = tier.get("max_score", -1)
		if score >= tier.get("min_score", 0) and (max_s == -1 or score <= max_s):
			return tier
	return {}

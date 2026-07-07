# ItemManager.gd - Autoload 道具持有/使用/效果管理
extends Node

var jokers: Array = []
var consumables: Array = []
var _registered_items: Dictionary = {}  # id -> item_data

const CONSUMABLE_LIMIT := 3

# ---- 初始化 ----
func reset():
	jokers.clear()
	consumables.clear()

func clear_registered_items():
	_registered_items.clear()

func register_item_resource(item_data: Dictionary):
	_registered_items[item_data.get("id", "")] = item_data

func get_all_registered() -> Array:
	return _registered_items.values()

func get_item_data(id: String) -> Dictionary:
	return _registered_items.get(id, {})

# ---- 购买 ----
func buy_item(item_data: Dictionary) -> bool:
	var price = item_data.get("price", 0)
	if RoundManager.game_coins < price: return false
	var item_type = item_data.get("item_type", 1)
	# v3.1: 法宝不可重复购买
	if item_type == 0 and has_joker(item_data.get("id", "")):
		return false
	if item_type != 0 and not can_add_consumable():
		return false
	RoundManager.game_coins -= price

	var effect = _create_effect(item_data)
	if item_type == 0:
		jokers.append(effect)
	else:
		consumables.append(effect)
	return true

func can_add_consumable() -> bool:
	return consumables.size() < CONSUMABLE_LIMIT

func get_consumable_limit() -> int:
	return CONSUMABLE_LIMIT

func get_active_joker_states() -> Array:
	return jokers

func get_consumable_by_id(id: String):
	for item in consumables:
		if item.resource_data.get("id", "") == id:
			return item
	return null

func consume_item(id: String):
	for i in range(consumables.size() - 1, -1, -1):
		if consumables[i].resource_data.get("id", "") == id and consumables[i].is_consumed():
			consumables.remove_at(i)
			return

func on_round_end():
	for i in range(consumables.size() - 1, -1, -1):
		if consumables[i].is_round_wide():
			consumables.remove_at(i)

func upgrade_joker(joker) -> bool:
	if joker.level >= 3: return false
	var cost = joker.get_upgrade_cost()
	if RoundManager.game_coins < cost: return false
	RoundManager.game_coins -= cost
	joker.level += 1
	return true

func has_joker(id: String) -> bool:
	for j in jokers:
		if j.resource_data.get("id", "") == id:
			return true
	return false

func _create_effect(item_data: Dictionary):
	var effect_class = item_data.get("effect_class", "")
	# Auto-prefix path based on item_type if not already included
	if effect_class != "" and "/" not in effect_class:
		var item_type = item_data.get("item_type", 1)
		if item_type == 0:
			effect_class = "artifacts/" + effect_class  # v3.1: 法宝在artifacts目录
		else:
			effect_class = "consumables/" + effect_class
	var script_path = "res://scripts/items/%s.gd" % effect_class
	if ResourceLoader.exists(script_path):
		var script = load(script_path)
		var effect = script.new()
		effect.resource_data = item_data
		return effect
	# Fallback：返回基础效果
	push_warning("Item effect script not found: %s (id=%s)" % [script_path, item_data.get("id", "?")])
	var base = load("res://scripts/items/ItemEffect.gd").new()
	base.resource_data = item_data
	return base

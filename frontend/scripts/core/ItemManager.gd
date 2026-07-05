# ItemManager.gd - Autoload 道具持有/使用/效果管理
extends Node

var jokers: Array = []
var consumables: Array = []
var _registered_items: Dictionary = {}  # id -> item_data

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
	RoundManager.game_coins -= price

	var effect = _create_effect(item_data)
	if item_data.get("item_type", 1) == 0:
		jokers.append(effect)
	else:
		consumables.append(effect)
	return true

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
	var script_path = "res://scripts/items/%s.gd" % effect_class
	if ResourceLoader.exists(script_path):
		var script = load(script_path)
		var effect = script.new()
		effect.resource_data = item_data
		return effect
	# Fallback：返回基础效果
	var base = load("res://scripts/items/ItemEffect.gd").new()
	base.resource_data = item_data
	return base

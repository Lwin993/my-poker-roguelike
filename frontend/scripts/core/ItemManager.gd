# ItemManager.gd - Autoload 道具持有/使用/效果管理
extends Node

var jokers: Array = []
var consumables: Array = []
var active_round_consumables: Array = []
var _registered_items: Dictionary = {}  # id -> item_data

const CONSUMABLE_LIMIT := -1  # v3.1: 道具不限制携带与同次使用数量
const ARTIFACT_IDS := ["artifact_jgb", "artifact_zjl", "artifact_rsg", "artifact_hyjj"]

const ARTIFACT_TEXTURE_PATHS := {
	"artifact_jgb": "res://assets/artifacts/jingubang.png",
	"artifact_zjl": "res://assets/artifacts/zijinling.png",
	"artifact_rsg": "res://assets/artifacts/renshenguo.png",
	"artifact_hyjj": "res://assets/artifacts/huoyanjinjing.png",
}

const ITEM_ICONS := {
	"artifact_jgb": "🏏", "artifact_zjl": "🔔", "artifact_rsg": "🍑", "artifact_hyjj": "👁",
	"nine_elixir": "💊", "boss_burst": "⚔", "clone_spell": "🐒", "double_potion": "🔥",
	"crit_potion": "💥", "freeze_spell": "🖐", "far_sight": "🔭", "final_play_ticket": "📜",
	"extra_play": "📜", "refresh_ticket": "🎟", "mirror_reveal": "🪞", "wind_calmer": "🟡",
	"holy_dew": "💧", "quint_crit": "⚡", "cloud_step": "☁", "seventy_two": "🌀",
}

# ---- 初始化 ----
func reset():
	jokers.clear()
	consumables.clear()
	active_round_consumables.clear()

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
	return CONSUMABLE_LIMIT < 0 or consumables.size() < CONSUMABLE_LIMIT

func get_consumable_limit() -> int:
	return CONSUMABLE_LIMIT

func get_active_joker_states() -> Array:
	return jokers

func get_active_round_consumables() -> Array:
	return active_round_consumables

func get_item_icon(item_or_data) -> String:
	var data = item_or_data.resource_data if item_or_data is RefCounted else item_or_data
	return ITEM_ICONS.get(data.get("id", ""), "🎴")

func get_artifact_texture_path(item_or_data) -> String:
	var data = item_or_data.resource_data if item_or_data is RefCounted else item_or_data
	return ARTIFACT_TEXTURE_PATHS.get(data.get("id", ""), "")

func get_artifact_texture(item_or_data) -> Texture2D:
	var path := get_artifact_texture_path(item_or_data)
	return load(path) if path != "" and ResourceLoader.exists(path) else null

func get_item_type_label(item_data: Dictionary) -> String:
	if item_data.get("item_type", 1) == 0:
		return "法宝 · 永久生效"
	return "稀有道具" if item_data.get("rarity", 0) == 1 else "消耗道具"

func create_item_effect(item_data: Dictionary):
	return _create_effect(item_data)

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

func consume_instance(item) -> bool:
	var idx = consumables.find(item)
	if idx == -1:
		return false
	consumables.remove_at(idx)
	return true

func activate_round_consumable(item) -> bool:
	if not consume_instance(item):
		return false
	active_round_consumables.append(item)
	return true

func on_round_end():
	active_round_consumables.clear()

func restore_items(joker_states: Array, consumable_ids: Array, active_round_ids: Array = []):
	jokers.clear()
	consumables.clear()
	active_round_consumables.clear()
	for state in joker_states:
		var id = state.get("id", "")
		var data = get_item_data(id)
		if data.is_empty(): continue
		var effect = _create_effect(data)
		effect.level = clampi(int(state.get("level", 1)), 1, 3)
		jokers.append(effect)
	for id in consumable_ids:
		var data = get_item_data(str(id))
		if not data.is_empty(): consumables.append(_create_effect(data))
	for id in active_round_ids:
		var data = get_item_data(str(id))
		if not data.is_empty(): active_round_consumables.append(_create_effect(data))

# 七十二变：随机复制一个法宝 Lv1 效果，作为新的永久法宝加入。
func add_random_artifact_copy() -> String:
	var candidates: Array = []
	for id in ARTIFACT_IDS:
		if _registered_items.has(id): candidates.append(id)
	if candidates.is_empty():
		return ""
	var copied_id: String = candidates.pick_random()
	var effect = _create_effect(get_item_data(copied_id))
	effect.level = 1
	jokers.append(effect)
	return effect.resource_data.get("display_name", "法宝")

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

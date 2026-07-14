# ItemManager.gd - Autoload 道具持有/使用/效果管理
extends Node

var jokers: Array = []
var consumables: Array = []
var active_round_consumables: Array = []
var purchased_rare_item_ids: Array = []
var _registered_items: Dictionary = {}  # id -> item_data

const CONSUMABLE_LIMIT := 3  # 出牌区固定三个道具槽，持续道具也占用携带位
const ARTIFACT_LIMIT := 3    # 行囊最多保留三个常驻法宝；临时复制品不占永久携带位
const ARTIFACT_IDS := ["artifact_bjs", "artifact_zjl", "artifact_rsg", "artifact_hyjj"]
const LEGACY_ITEM_ID_ALIASES := {"artifact_jgb": "artifact_bjs"}
# 对应大妖通关后的商店节点；到达该节点后，克制道具不再进入刷新池。
const COUNTER_ITEM_EXPIRE_SHOP_NODES := {
	"mirror_reveal": 2,
	"wind_calmer": 5,
	"holy_dew": 8,
}

const ARTIFACT_TEXTURE_PATHS := {
	"artifact_bjs": "res://assets/artifacts/bajiaoshan.png",
	"artifact_zjl": "res://assets/artifacts/zijinling.png",
	"artifact_rsg": "res://assets/artifacts/renshenguo.png",
	"artifact_hyjj": "res://assets/artifacts/huoyanjinjing.png",
}

const CONSUMABLE_ATLAS_PATH := "res://assets/items/consumables-atlas.png"
const CONSUMABLE_ATLAS_INDEX := {
	"nine_elixir": Vector2i(0, 0), "boss_burst": Vector2i(1, 0),
	"clone_spell": Vector2i(2, 0), "double_potion": Vector2i(3, 0),
	"crit_potion": Vector2i(0, 1), "freeze_spell": Vector2i(1, 1),
	"far_sight": Vector2i(2, 1), "final_play_ticket": Vector2i(3, 1),
	"extra_play": Vector2i(0, 2), "refresh_ticket": Vector2i(1, 2),
	"mirror_reveal": Vector2i(2, 2), "wind_calmer": Vector2i(3, 2),
	"holy_dew": Vector2i(0, 3), "quint_crit": Vector2i(1, 3),
	"cloud_step": Vector2i(2, 3), "seventy_two": Vector2i(3, 3),
}

const ITEM_ICONS := {
	"artifact_bjs": "🪭", "artifact_zjl": "🔔", "artifact_rsg": "🍑", "artifact_hyjj": "👁",
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
	purchased_rare_item_ids.clear()

func clear_registered_items():
	_registered_items.clear()

func register_item_resource(item_data: Dictionary):
	var normalized := normalize_item_data(item_data)
	_registered_items[normalized.get("id", "")] = normalized

func get_all_registered() -> Array:
	return _registered_items.values()

func get_item_data(id: String) -> Dictionary:
	return _registered_items.get(_canonical_item_id(id), {})

func _canonical_item_id(id: String) -> String:
	return LEGACY_ITEM_ID_ALIASES.get(id, id)

# 兼容旧后端/旧存档：原金箍棒法宝统一迁移为芭蕉扇；攻击金箍棒不属于装备数据。
func normalize_item_data(item_data: Dictionary) -> Dictionary:
	if str(item_data.get("id", "")) != "artifact_jgb":
		return item_data
	var normalized: Dictionary = item_data.duplicate(true)
	normalized["id"] = "artifact_bjs"
	normalized["display_name"] = "芭蕉扇"
	normalized["description"] = "每次出牌掀起罡风，固定增加倍率"
	normalized["item_type"] = 0
	normalized["effect_class"] = "BaJiaoShan"
	return normalized

# ---- 购买 ----
func buy_item(item_data: Dictionary, shop_node: int = -1) -> bool:
	item_data = normalize_item_data(item_data)
	var price = item_data.get("price", 0)
	if RoundManager.game_coins < price: return false
	var item_type = item_data.get("item_type", 1)
	var item_id: String = str(item_data.get("id", ""))
	if not is_shop_item_available(item_data, shop_node):
		return false
	# v3.1: 法宝不可重复购买
	if item_type == 0 and (has_joker(item_id) or not can_add_artifact()):
		return false
	if item_type != 0 and not can_add_consumable():
		return false
	RoundManager.game_coins -= price

	var effect = _create_effect(item_data)
	if item_type == 0:
		jokers.append(effect)
	else:
		consumables.append(effect)
	if int(item_data.get("rarity", 0)) == 1:
		purchased_rare_item_ids.append(item_id)
	return true

func has_purchased_rare_item(id: String) -> bool:
	return purchased_rare_item_ids.has(_canonical_item_id(id))

func is_counter_item_expired(id: String, shop_node: int) -> bool:
	id = _canonical_item_id(id)
	if not COUNTER_ITEM_EXPIRE_SHOP_NODES.has(id):
		return false
	return shop_node >= int(COUNTER_ITEM_EXPIRE_SHOP_NODES[id])

func is_shop_item_available(item_data: Dictionary, shop_node: int) -> bool:
	var id: String = _canonical_item_id(str(item_data.get("id", "")))
	if int(item_data.get("rarity", 0)) == 1 and has_purchased_rare_item(id):
		return false
	if shop_node >= 0 and is_counter_item_expired(id, shop_node):
		return false
	return true

func can_add_consumable() -> bool:
	return consumables.size() + active_round_consumables.size() < CONSUMABLE_LIMIT

func can_add_artifact() -> bool:
	return jokers.filter(func(joker): return not joker.is_temporary).size() < ARTIFACT_LIMIT

func get_artifact_limit() -> int:
	return ARTIFACT_LIMIT

func get_consumable_limit() -> int:
	return CONSUMABLE_LIMIT

func get_sell_price(item) -> int:
	var data: Dictionary = item.resource_data if item is RefCounted else item
	return maxi(1, int(data.get("price", 0)) / 2)

func sell_item(item) -> int:
	if item == null or bool(item.get("is_temporary")):
		return 0
	var collection: Array = jokers if jokers.has(item) else consumables
	var index := collection.find(item)
	if index == -1:
		return 0
	var sell_price := get_sell_price(item)
	collection.remove_at(index)
	RoundManager.game_coins += sell_price
	return sell_price

func get_active_joker_states() -> Array:
	return jokers

func get_active_round_consumables() -> Array:
	return active_round_consumables

func get_item_icon(item_or_data) -> String:
	var data = item_or_data.resource_data if item_or_data is RefCounted else item_or_data
	return ITEM_ICONS.get(_canonical_item_id(data.get("id", "")), "🎴")

func get_artifact_texture_path(item_or_data) -> String:
	var data = item_or_data.resource_data if item_or_data is RefCounted else item_or_data
	return ARTIFACT_TEXTURE_PATHS.get(_canonical_item_id(data.get("id", "")), "")

func get_artifact_texture(item_or_data) -> Texture2D:
	var path := get_artifact_texture_path(item_or_data)
	return load(path) if path != "" and ResourceLoader.exists(path) else null

func get_consumable_texture(item_or_data) -> Texture2D:
	var data = item_or_data.resource_data if item_or_data is RefCounted else item_or_data
	var atlas_cell = CONSUMABLE_ATLAS_INDEX.get(data.get("id", ""), null)
	if atlas_cell == null or not ResourceLoader.exists(CONSUMABLE_ATLAS_PATH):
		return null
	var atlas: Texture2D = load(CONSUMABLE_ATLAS_PATH)
	var cell_size := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 4.0)
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(Vector2(atlas_cell) * cell_size, cell_size)
	texture.filter_clip = true
	return texture

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
	for i in range(jokers.size() - 1, -1, -1):
		if jokers[i].is_temporary:
			jokers.remove_at(i)

func restore_items(joker_states: Array, consumable_ids: Array, active_round_ids: Array = [], purchased_rare_ids: Array = []):
	jokers.clear()
	consumables.clear()
	active_round_consumables.clear()
	purchased_rare_item_ids.clear()
	for purchased_id in purchased_rare_ids:
		var canonical_id := _canonical_item_id(str(purchased_id))
		if not purchased_rare_item_ids.has(canonical_id):
			purchased_rare_item_ids.append(canonical_id)
	for state in joker_states:
		if jokers.size() >= ARTIFACT_LIMIT:
			break
		var id = _canonical_item_id(state.get("id", ""))
		var data = get_item_data(id)
		if data.is_empty(): continue
		var effect = _create_effect(data)
		effect.level = clampi(int(state.get("level", 1)), 1, 3)
		effect.is_temporary = bool(state.get("temporary", false))
		jokers.append(effect)
	# 持续生效的道具优先恢复，并与未使用道具共同占用三个携带位。
	for id in active_round_ids:
		if active_round_consumables.size() >= CONSUMABLE_LIMIT:
			break
		var data = get_item_data(str(id))
		if not data.is_empty(): active_round_consumables.append(_create_effect(data))
	for id in consumable_ids:
		if consumables.size() + active_round_consumables.size() >= CONSUMABLE_LIMIT:
			break
		var data = get_item_data(str(id))
		if not data.is_empty(): consumables.append(_create_effect(data))

# 七十二变：随机复制一个法宝 Lv1 效果，只在当前怪物战中生效。
func add_random_temporary_artifact_copy() -> String:
	var candidates: Array = []
	for id in ARTIFACT_IDS:
		if _registered_items.has(id): candidates.append(id)
	if candidates.is_empty():
		return ""
	var copied_id: String = candidates.pick_random()
	var effect = _create_effect(get_item_data(copied_id))
	effect.level = 1
	effect.is_temporary = true
	jokers.append(effect)
	return effect.resource_data.get("display_name", "法宝")

func upgrade_joker(joker) -> bool:
	if joker.is_temporary: return false
	if joker.level >= 3: return false
	var cost = joker.get_upgrade_cost()
	if RoundManager.game_coins < cost: return false
	RoundManager.game_coins -= cost
	joker.level += 1
	return true

func has_joker(id: String) -> bool:
	id = _canonical_item_id(id)
	for j in jokers:
		if _canonical_item_id(j.resource_data.get("id", "")) == id:
			return true
	return false

func _create_effect(item_data: Dictionary):
	item_data = normalize_item_data(item_data)
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

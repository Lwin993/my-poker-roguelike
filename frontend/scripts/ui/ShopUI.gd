# ShopUI.gd - 商店界面交互
extends Control

@onready var backdrop        = $Backdrop
@onready var purchase_toast  = $PurchaseToast

@onready var coins_label     = $VBox/HeaderRow/CoinsBadge/CoinsLabel
@onready var sub_title       = $VBox/SubTitle
@onready var shelf_frame     = $VBox/ShelfFrame
@onready var shop_grid       = $VBox/ShelfFrame/ShelfContents/ShopGrid
@onready var owned_dock      = $VBox/OwnedDock
@onready var owned_panel     = $VBox/OwnedDock/OwnedRow/OwnedPanel
@onready var owned_count_label = $VBox/OwnedDock/OwnedRow/OwnedTitleVBox/OwnedCountLabel
@onready var guide_area      = $VBox/GuideArea
@onready var guide_bubble    = $VBox/GuideArea/GuideRow/GuideBubble
@onready var guide_name      = $VBox/GuideArea/GuideRow/GuideBubble/GuideVBox/GuideName
@onready var guide_text      = $VBox/GuideArea/GuideRow/GuideBubble/GuideVBox/GuideText
@onready var guide_action_button = $VBox/GuideArea/GuideRow/GuideBubble/GuideVBox/GuideActionButton
@onready var guide_sell_button = $VBox/GuideArea/GuideRow/GuideBubble/GuideVBox/GuideSellButton
@onready var land_god_portrait = $VBox/GuideArea/GuideRow/LandGodPortrait
@onready var refresh_button  = $VBox/BottomRow/RefreshButton
@onready var continue_button = $VBox/BottomRow/ContinueButton

var _refresh_count: int = 0
var _has_free_refresh: bool = false
var _current_shop_node: int = 0
var _pending_shop_items: Array = []  # items from API, waiting to render
var _current_shop_items: Array = []  # v3.1: cached for re-render after buy
var _sold_item_ids: Array = []      # v3.1: 已售罄的商品ID
var _selected_shop_item: Dictionary = {}
var _selected_owned_joker = null
var _selected_owned_consumable = null
var _guide_action_mode := "none"

func _ready():
	_style_button(continue_button, GameTheme.COLOR_GOLD)
	_style_button(refresh_button,  GameTheme.COLOR_JOKER)
	$VBox/HeaderRow/CoinsBadge.add_theme_stylebox_override("panel",
		GameTheme.get_panel_style(Color("10274b"), GameTheme.COLOR_GOLD, 14))
	_style_shop_surfaces()
	refresh_button.pressed.connect(_on_refresh_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	guide_action_button.pressed.connect(_on_guide_action_pressed)
	guide_sell_button.pressed.connect(_on_sell_pressed)
	GameAPI.sell_completed.connect(_on_sell_completed)
	# Connect async signals from GameAPI
	GameAPI.shop_items_loaded.connect(_on_shop_items_loaded)
	GameAPI.buy_completed.connect(_on_buy_completed)
	_start_shopkeeper_idle()

func _style_button(btn: Button, color: Color):
	var s = GameTheme.get_button_style(color)
	var h = GameTheme.get_button_hover_style(color)
	var p = GameTheme.get_button_pressed_style(color)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _style_shop_surfaces():
	var shelf = StyleBoxFlat.new()
	shelf.bg_color = Color("35180b")
	shelf.border_color = Color("c47a32")
	shelf.set_border_width_all(4)
	shelf.border_width_bottom = 7
	shelf.set_corner_radius_all(14)
	shelf.shadow_color = Color(0.05, 0.01, 0.005, 0.78)
	shelf.shadow_size = 8
	shelf_frame.add_theme_stylebox_override("panel", shelf)

	var owned = StyleBoxFlat.new()
	owned.bg_color = Color(0.08, 0.045, 0.035, 0.90)
	owned.border_color = Color(0.62, 0.34, 0.15, 0.74)
	owned.set_border_width_all(2)
	owned.set_corner_radius_all(10)
	owned.content_margin_left = 6
	owned.content_margin_right = 6
	owned.content_margin_top = 4
	owned.content_margin_bottom = 4
	owned_dock.add_theme_stylebox_override("panel", owned)

	var guide_bg = StyleBoxFlat.new()
	guide_bg.bg_color = Color(0.07, 0.035, 0.025, 0.88)
	guide_bg.border_color = Color(0.76, 0.43, 0.18, 0.72)
	guide_bg.set_border_width_all(2)
	guide_bg.set_corner_radius_all(13)
	guide_bg.content_margin_left = 5
	guide_bg.content_margin_right = 2
	guide_bg.content_margin_top = 4
	guide_bg.content_margin_bottom = 3
	guide_area.add_theme_stylebox_override("panel", guide_bg)

	var parchment = StyleBoxFlat.new()
	parchment.bg_color = Color("f3dfb2")
	parchment.border_color = Color("ae6d2b")
	parchment.set_border_width_all(3)
	parchment.set_corner_radius_all(12)
	parchment.content_margin_left = 10
	parchment.content_margin_right = 10
	parchment.content_margin_top = 7
	parchment.content_margin_bottom = 7
	parchment.shadow_color = Color(0.05, 0.015, 0.005, 0.65)
	parchment.shadow_size = 5
	guide_bubble.add_theme_stylebox_override("panel", parchment)
	_style_button(guide_action_button, Color("b66a23"))
	_style_button(guide_sell_button, Color("9a3f2a"))

func _start_shopkeeper_idle():
	land_god_portrait.pivot_offset = land_god_portrait.size * Vector2(0.5, 0.88)
	var idle = create_tween().set_loops()
	idle.tween_property(land_god_portrait, "rotation", -0.025, 1.05).set_ease(Tween.EASE_IN_OUT)
	idle.tween_property(land_god_portrait, "rotation", 0.025, 1.05).set_ease(Tween.EASE_IN_OUT)

# ---- 入口 ----
func refresh_shop():
	_refresh_count    = 0
	_sold_item_ids.clear()  # v3.1: 新商店清空售罄记录
	_has_free_refresh = _check_free_refresh()
	_reset_shopkeeper_dialogue()
	_update_header()
	_load_shop_items()
	_rebuild_owned_panel()
	_update_refresh_button()

func _reset_shopkeeper_dialogue():
	_selected_shop_item = {}
	_selected_owned_joker = null
	_selected_owned_consumable = null
	_guide_action_mode = "none"
	guide_name.text = "土地公"
	guide_text.text = "小仙友，点点货架上的宝贝，老朽给你讲讲用途和使用时机。"
	_update_guide_action_button()

func _check_free_refresh() -> bool:
	for c in ItemManager.consumables:
		if c.resource_data.get("id","") == "refresh_ticket": return true
	return false

func _update_header():
	var r = maxi(0, RoundManager.last_cleared_round)
	var b = maxi(0, RoundManager.last_cleared_blind)
	var monster = RoundManager.MONSTER_NAMES[r][b]
	sub_title.text = "第%d轮 · %s 已降伏  +%d 灵石" % [r + 1, monster, RoundManager.last_cleared_reward]
	coins_label.text = "💎  %d" % RoundManager.game_coins
	continue_button.text = "查看本局结算  ▶" if RoundManager._pending_final_result else "带上宝贝继续降妖  ▶"

# ---- 商品列表 ----
func _load_shop_items():
	for c in shop_grid.get_children(): c.queue_free()

	_current_shop_node = clampi(RoundManager.last_cleared_round * 3 + RoundManager.last_cleared_blind, 0, 8)
	# Async: request from backend API
	GameAPI.get_shop_items(_current_shop_node, _refresh_count)

# Callback when shop items are loaded from API
func _on_shop_items_loaded(items: Array):
	var normalized_items: Array = items.map(func(item): return ItemManager.normalize_item_data(item))
	# 客户端再次执行局内规则，兼容旧服务端缓存或离线存档。
	var available_items: Array = normalized_items.filter(func(item):
		return ItemManager.is_shop_item_available(item, _current_shop_node))
	_current_shop_items = available_items  # 同时兼容仍返回旧金箍棒ID的服务端
	for c in shop_grid.get_children(): c.queue_free()
	for item in available_items:
		var card = _make_shop_card(item)
		shop_grid.add_child(card)
		card.modulate.a = 0.0
		card.scale = Vector2(0.86, 0.86)
		card.pivot_offset = card.custom_minimum_size * 0.5
		var delay = float(shop_grid.get_child_count() - 1) * 0.045
		var reveal = create_tween()
		reveal.tween_interval(delay)
		reveal.tween_property(card, "modulate:a", 1.0, 0.16)
		reveal.parallel().tween_property(card, "scale", Vector2.ONE, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _make_shop_card(item_data: Dictionary) -> Control:
	var rarity := int(item_data.get("rarity", 0))
	var item_type := int(item_data.get("item_type", 1))
	var price := int(item_data.get("price", 0))
	var name_str := str(item_data.get("display_name", "?"))
	var id := str(item_data.get("id", ""))
	var accent := GameTheme.COLOR_RARE if rarity == 1 else (GameTheme.COLOR_JOKER if item_type == 0 else GameTheme.COLOR_ACCENT)
	var item_button = Button.new()
	# 商品直接占满对应木格，三列边缘与货架立柱、隔板精确对齐。
	item_button.custom_minimum_size = Vector2(0, 112)
	item_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_button.text = ""
	item_button.focus_mode = Control.FOCUS_NONE
	item_button.tooltip_text = "点击后由土地公讲解【%s】" % name_str
	item_button.set_meta("shelf_item", true)
	item_button.set_meta("item_id", id)
	_style_shelf_item_button(item_button, accent)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 3; vbox.offset_top = 3; vbox.offset_right = -3; vbox.offset_bottom = -3
	vbox.add_theme_constant_override("separation", 1)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_button.add_child(vbox)

	var rarity_lbl = Label.new()
	rarity_lbl.text = "★ 稀有" if rarity == 1 else ("法宝" if item_type == 0 else "道具")
	rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_lbl.add_theme_font_size_override("font_size", 9)
	rarity_lbl.add_theme_color_override("font_color", accent)
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rarity_lbl)

	var art = TextureRect.new()
	art.custom_minimum_size = Vector2(0, 58)
	art.texture = ItemManager.get_artifact_texture(item_data) if item_type == 0 else ItemManager.get_consumable_texture(item_data)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(art)

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color("ffe2a0"))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.025, 0.01, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var status_lbl = Label.new()
	if _sold_item_ids.has(id):
		status_lbl.text = "已售罄"
	elif item_type == 0 and ItemManager.has_joker(id):
		status_lbl.text = "已拥有"
	else:
		status_lbl.text = "💎 %d" % price
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_size_override("font_size", 11)
	status_lbl.add_theme_color_override("font_color", GameTheme.COLOR_GOLD if status_lbl.text.begins_with("💎") else GameTheme.COLOR_TEXT_DIM)
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(status_lbl)

	item_button.pressed.connect(func(): _select_shop_item(item_data, item_button))
	return item_button

func _style_shelf_item_button(btn: Button, accent: Color):
	# 货架商品不是卡片：常态完全透明、无边框，悬停只亮起一层柔光。
	var normal = StyleBoxEmpty.new()
	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(accent.r, accent.g, accent.b, 0.13)
	hover.set_corner_radius_all(10)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.28)
	hover.shadow_size = 5
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.22)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _select_shop_item(item_data: Dictionary, shelf_button: Control = null):
	_selected_shop_item = item_data
	_selected_owned_joker = null
	_selected_owned_consumable = null
	_guide_action_mode = "buy"
	var name_str := str(item_data.get("display_name", "宝贝"))
	var desc_str := str(item_data.get("description", ""))
	var rarity := int(item_data.get("rarity", 0))
	var item_type := int(item_data.get("item_type", 1))
	var extra := "这是常驻法宝，买下后整局生效，还能在仙铺升级。" if item_type == 0 else ""
	if item_type != 0:
		var preview_effect = ItemManager.create_item_effect(item_data)
		extra = "使用时机：%s。" % preview_effect.get_use_timing_label()
	if rarity == 1:
		extra += " 稀有货色，每局只能购买一次。"
	match str(item_data.get("id", "")):
		"mirror_reveal": extra += " 它专门克制白骨精的幻术。"
		"wind_calmer": extra += " 它专门压住黄风怪的妖风。"
		"holy_dew": extra += " 它能熄灭红孩儿的三昧真火。"
		"seventy_two": extra += " 变化出的法宝只维持当前回合。"
	guide_name.text = "土地公 · %s" % name_str
	guide_text.text = "小仙友，这件【%s】的门道是：\n%s\n%s" % [name_str, desc_str, extra]
	_update_guide_action_button()
	backdrop.flash(GameTheme.COLOR_GOLD, 0.07)
	if shelf_button != null:
		var pulse = create_tween()
		pulse.tween_property(shelf_button, "modulate", Color(1.16, 1.08, 0.72, 1), 0.08)
		pulse.tween_property(shelf_button, "modulate", Color.WHITE, 0.13)

func _update_guide_action_button():
	guide_action_button.visible = true
	var selected_owned_item = _selected_owned_joker if _selected_owned_joker != null else _selected_owned_consumable
	guide_sell_button.visible = selected_owned_item != null
	guide_sell_button.disabled = selected_owned_item == null
	if selected_owned_item != null:
		guide_sell_button.text = "出售  +💎%d" % ItemManager.get_sell_price(selected_owned_item)
	if _guide_action_mode == "upgrade" and _selected_owned_joker != null:
		var cost = _selected_owned_joker.get_upgrade_cost()
		guide_action_button.text = "已经满级" if cost == -1 else "升级法宝  💎%d" % cost
		guide_action_button.disabled = cost == -1 or RoundManager.game_coins < cost
		return
	if _guide_action_mode != "buy" or _selected_shop_item.is_empty():
		guide_action_button.text = "已收入行囊" if _guide_action_mode == "purchased" else "先看看货架"
		guide_action_button.disabled = true
		return
	var id := str(_selected_shop_item.get("id", ""))
	var price := int(_selected_shop_item.get("price", 0))
	var item_type := int(_selected_shop_item.get("item_type", 1))
	if _sold_item_ids.has(id):
		guide_action_button.text = "这件已经售罄"
		guide_action_button.disabled = true
	elif item_type == 0 and ItemManager.has_joker(id):
		guide_action_button.text = "已经拥有这件法宝"
		guide_action_button.disabled = true
	elif item_type == 0 and not ItemManager.can_add_artifact():
		guide_action_button.text = "法宝已满（3/3）"
		guide_action_button.disabled = true
	elif item_type != 0 and not ItemManager.can_add_consumable():
		guide_action_button.text = "道具已满（3/3）"
		guide_action_button.disabled = true
	else:
		guide_action_button.text = "收下它  💎%d" % price
		guide_action_button.disabled = RoundManager.game_coins < price

func _on_guide_action_pressed():
	if _guide_action_mode == "buy" and not _selected_shop_item.is_empty():
		_on_buy_pressed(str(_selected_shop_item.get("id", "")), _selected_shop_item)
	elif _guide_action_mode == "upgrade" and _selected_owned_joker != null:
		_on_upgrade_pressed(_selected_owned_joker)

func _on_buy_pressed(item_id: String, item_data: Dictionary):
	# v3.1: 已售罄的商品不可再买
	if _sold_item_ids.has(item_id):
		return
	# Try local buy first (optimistic for immediate feedback)
	if not ItemManager.buy_item(item_data, _current_shop_node):
		return
	# 标记为售罄
	_sold_item_ids.append(item_id)
	_show_purchase_burst(item_data)
	guide_name.text = "土地公 · 成交"
	guide_text.text = "好眼力！【%s】已经替你放进行囊，下一战可要用在刀刃上。" % item_data.get("display_name", "宝贝")
	_guide_action_mode = "purchased"
	_selected_shop_item = {}
	_update_guide_action_button()
	# Then confirm with backend
	GameAPI.buy_item(item_id, _current_shop_node)
	# v3.1: 购买后刷新UI（更新已拥有状态 + 灵石余额）
	_on_shop_items_loaded(_current_shop_items)
	_rebuild_owned_panel()
	coins_label.text = "💎  %d" % RoundManager.game_coins

# ---- 已持有道具 ----
func _rebuild_owned_panel():
	for c in owned_panel.get_children(): c.queue_free()
	var owned_count := ItemManager.jokers.size() + ItemManager.consumables.size()
	owned_count_label.text = "法宝%d/3\n道具%d/3" % [ItemManager.jokers.size(), ItemManager.consumables.size()]

	if ItemManager.jokers.is_empty() and ItemManager.consumables.is_empty():
		var lbl = Label.new()
		lbl.text = "行囊还是空的，去货架挑一件吧"
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
		owned_panel.add_child(lbl)
		return

	for joker in ItemManager.jokers:
		owned_panel.add_child(_make_owned_joker_icon(joker))
	for cons in ItemManager.consumables:
		owned_panel.add_child(_make_owned_consumable_icon(cons))

func _make_owned_icon(texture: Texture2D, accent: Color, corner_text: String) -> Button:
	var btn = Button.new()
	# 三列两排刚好容纳 3 个法宝与 3 个道具，避免横向滚动漏看物品。
	btn.custom_minimum_size = Vector2(66, 66)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.text = ""
	_style_shelf_item_button(btn, accent)
	var art = TextureRect.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 4; art.offset_top = 4; art.offset_right = -4; art.offset_bottom = -4
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(art)
	var corner = Label.new()
	corner.anchor_left = 0.42; corner.anchor_top = 0.68; corner.anchor_right = 0.98; corner.anchor_bottom = 0.98
	corner.text = corner_text
	corner.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	corner.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	corner.add_theme_font_size_override("font_size", 11)
	corner.add_theme_color_override("font_color", accent)
	corner.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.01, 0.98))
	corner.add_theme_constant_override("outline_size", 3)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(corner)
	return btn

func _make_owned_joker_icon(joker) -> Button:
	var btn := _make_owned_icon(ItemManager.get_artifact_texture(joker), GameTheme.COLOR_JOKER, "Lv%d" % joker.level)
	btn.tooltip_text = "%s · Lv%d" % [joker.resource_data.get("display_name", "法宝"), joker.level]
	btn.pressed.connect(func(): _show_owned_joker_in_guide(joker))
	return btn

func _make_owned_consumable_icon(cons) -> Button:
	var color := GameTheme.COLOR_RARE if cons.resource_data.get("rarity", 0) == 1 else GameTheme.COLOR_ACCENT
	var btn := _make_owned_icon(ItemManager.get_consumable_texture(cons), color, "道具")
	btn.tooltip_text = cons.resource_data.get("display_name", "道具")
	btn.pressed.connect(func(): _show_owned_consumable_in_guide(cons))
	return btn

func _show_owned_joker_in_guide(joker):
	_selected_shop_item = {}
	_selected_owned_joker = joker
	_selected_owned_consumable = null
	_guide_action_mode = "upgrade"
	var cost = joker.get_upgrade_cost()
	var upgrade_line := "已经修炼到满级。" if cost == -1 else "再花%d灵石，老朽可替你升到下一阶。" % cost
	guide_name.text = "土地公 · %s" % joker.resource_data.get("display_name", "法宝")
	guide_text.text = "这件法宝现在是 Lv%d：%s\n%s" % [joker.level, joker.resource_data.get("description", ""), upgrade_line]
	_update_guide_action_button()

func _show_owned_consumable_in_guide(cons):
	_selected_shop_item = {}
	_selected_owned_joker = null
	_selected_owned_consumable = cons
	_guide_action_mode = "owned"
	guide_name.text = "土地公 · %s" % cons.resource_data.get("display_name", "道具")
	guide_text.text = "这件已经在你的行囊里：%s\n到了战斗中再点它使用，时机是【%s】。" % [cons.resource_data.get("description", ""), cons.get_use_timing_label()]
	_update_guide_action_button()

func _on_sell_pressed():
	var item = _selected_owned_joker if _selected_owned_joker != null else _selected_owned_consumable
	if item == null:
		return
	var item_data: Dictionary = item.resource_data
	var item_id := str(item_data.get("id", ""))
	var sell_price := ItemManager.sell_item(item)
	if sell_price <= 0:
		return
	GameAPI.sell_item(item_id)
	_show_purchase_burst(item_data, "【%s】已出售  +💎%d" % [item_data.get("display_name", "宝物"), sell_price])
	_reset_shopkeeper_dialogue()
	guide_text.text = "买卖随缘，这件宝物已替你换成%d灵石。行囊也腾出了位置。" % sell_price
	coins_label.text = "💎  %d" % RoundManager.game_coins
	_rebuild_owned_panel()
	_on_shop_items_loaded(_current_shop_items)
	GameState.save_state()

func _on_sell_completed(data: Dictionary):
	var coins := int(data.get("remaining_coins", -1))
	if coins >= 0:
		RoundManager.game_coins = coins
		coins_label.text = "💎  %d" % coins
		GameState.save_state()

func _on_upgrade_pressed(joker):
	var cost = joker.get_upgrade_cost()
	if cost == -1: return
	if RoundManager.game_coins >= cost:
		ItemManager.upgrade_joker(joker)
		coins_label.text = "💎  %d" % RoundManager.game_coins
		_rebuild_owned_panel()
		_show_purchase_burst(joker.resource_data, "法宝升级！Lv%d" % joker.level)
		_show_owned_joker_in_guide(joker)
		GameState.save_state()

func _update_refresh_button():
	var cost = _get_refresh_cost()
	refresh_button.text = "🔄  刷新（免费）" if _has_free_refresh else "🔄  刷新（💎%d）" % cost
	refresh_button.disabled = (not _has_free_refresh) and RoundManager.game_coins < cost

func _get_refresh_cost() -> int:
	return 5 + _refresh_count * 5

func _on_refresh_pressed():
	var cost = _get_refresh_cost()
	if _has_free_refresh:
		ItemManager.consume_item("refresh_ticket"); _has_free_refresh = false
	elif RoundManager.game_coins >= cost:
		RoundManager.game_coins -= cost
	else:
		return
	_refresh_count += 1
	_reset_shopkeeper_dialogue()
	# Async: reload shop from backend with updated refresh_count
	GameAPI.get_shop_items(_current_shop_node, _refresh_count)
	_update_refresh_button()
	coins_label.text = "💎  %d" % RoundManager.game_coins

# Callback when backend buy completes
func _on_buy_completed(data: Dictionary):
	# Check for backend error — sync coins from backend regardless
	var coins = data.get("remaining_coins", -1)
	if coins >= 0:
		RoundManager.game_coins = coins
	coins_label.text = "💎  %d" % RoundManager.game_coins
	_rebuild_owned_panel()
	_load_shop_items()
	_update_refresh_button()
	GameState.save_state()

func _on_continue_pressed():
	if RoundManager._pending_final_result:
		RoundManager._pending_final_result = false
		GameAPI.submit_result()
		RoundManager._set_phase(RoundManager.Phase.FINAL_RESULT)
		return
	# v3.1: 大妖通关后，商店关闭时推进到下一轮
	if RoundManager._pending_next_round:
		RoundManager._pending_next_round = false
		RoundManager.current_round += 1
		RoundManager.current_blind  = 0
		RoundManager._reset_blind()
		RoundManager._set_phase(RoundManager.Phase.ROUND_START)
	else:
		RoundManager._set_phase(RoundManager.Phase.PLAYING)

func _show_purchase_burst(item_data: Dictionary, custom_text: String = ""):
	var name = item_data.get("display_name", "天命宝物")
	purchase_toast.text = custom_text if custom_text != "" else "✨【%s】入手！战力暴涨！" % name
	purchase_toast.visible = true
	purchase_toast.modulate.a = 1.0
	purchase_toast.pivot_offset = purchase_toast.size * 0.5
	purchase_toast.scale = Vector2(0.25, 0.25)
	backdrop.flash(GameTheme.COLOR_GOLD, 0.20)
	backdrop.burst(Vector2(size.x * 0.5, size.y * 0.48), GameTheme.COLOR_GOLD, 38)
	var tw = create_tween()
	tw.tween_property(purchase_toast, "scale", Vector2(1.18, 1.18), 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(purchase_toast, "scale", Vector2.ONE, 0.10)
	tw.tween_interval(0.55)
	tw.tween_property(purchase_toast, "modulate:a", 0.0, 0.20)
	tw.tween_callback(func(): purchase_toast.visible = false)

# ShopUI.gd - 商店界面交互
extends Control

@onready var coins_label     = $VBox/HeaderRow/CoinsBadge/CoinsLabel
@onready var sub_title       = $VBox/SubTitle
@onready var shop_grid       = $VBox/ShopScroll/ShopGrid
@onready var owned_panel     = $VBox/OwnedScroll/OwnedPanel
@onready var refresh_button  = $VBox/BottomRow/RefreshButton
@onready var continue_button = $VBox/BottomRow/ContinueButton

var _refresh_count: int = 0
var _has_free_refresh: bool = false
var _current_shop_node: int = 0
var _pending_shop_items: Array = []  # items from API, waiting to render
var _current_shop_items: Array = []  # v3.1: cached for re-render after buy
var _sold_item_ids: Array = []      # v3.1: 已售罄的商品ID

func _ready():
	_style_button(continue_button, GameTheme.COLOR_ACCENT)
	_style_button(refresh_button,  GameTheme.COLOR_BLUE_CHIP)
	refresh_button.pressed.connect(_on_refresh_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	# Connect async signals from GameAPI
	GameAPI.shop_items_loaded.connect(_on_shop_items_loaded)
	GameAPI.buy_completed.connect(_on_buy_completed)

func _style_button(btn: Button, color: Color):
	var s = GameTheme.get_button_style(color)
	var h = GameTheme.get_button_hover_style(color)
	var p = GameTheme.get_button_pressed_style(color)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

# ---- 入口 ----
func refresh_shop():
	_refresh_count    = 0
	_sold_item_ids.clear()  # v3.1: 新商店清空售罄记录
	_has_free_refresh = _check_free_refresh()
	_update_header()
	_load_shop_items()
	_rebuild_owned_panel()
	_update_refresh_button()

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
	continue_button.text = "领取战果  ▶" if RoundManager._pending_final_result else "继续降妖  ▶"

# ---- 商品列表 ----
func _load_shop_items():
	for c in shop_grid.get_children(): c.queue_free()

	_current_shop_node = clampi(RoundManager.last_cleared_round * 3 + RoundManager.last_cleared_blind, 0, 8)
	# Async: request from backend API
	GameAPI.get_shop_items(_current_shop_node, _refresh_count)

# Callback when shop items are loaded from API
func _on_shop_items_loaded(items: Array):
	_current_shop_items = items  # v3.1: 缓存商品数据
	for c in shop_grid.get_children(): c.queue_free()
	for item in items:
		shop_grid.add_child(_make_shop_card(item))

func _make_shop_card(item_data: Dictionary) -> Control:
	var rarity    = item_data.get("rarity", 0)
	var item_type = item_data.get("item_type", 1)
	var price     = item_data.get("price", 0)
	var name_str  = item_data.get("display_name", "?")
	var desc_str  = item_data.get("description", "")
	var id        = item_data.get("id", "")

	var border_color: Color
	if   rarity == 1:    border_color = GameTheme.COLOR_RARE
	elif item_type == 0: border_color = GameTheme.COLOR_JOKER
	else:                border_color = GameTheme.COLOR_ACCENT

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(148, 188)
	card.tooltip_text = "%s\n%s" % [name_str, desc_str]
	var cs = StyleBoxFlat.new()
	cs.bg_color = GameTheme.COLOR_BG_PANEL.lerp(border_color, 0.16); cs.border_color = border_color
	cs.set_border_width_all(2); cs.set_corner_radius_all(6)
	cs.shadow_color = Color(0.03, 0.01, 0.02, 0.42); cs.shadow_size = 4
	cs.content_margin_left = 8; cs.content_margin_right = 8
	cs.content_margin_top  = 8; cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var icon_lbl = Label.new()
	icon_lbl.text = ItemManager.get_item_icon(item_data)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.tooltip_text = card.tooltip_text
	vbox.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", border_color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.tooltip_text = card.tooltip_text
	vbox.add_child(name_lbl)

	var type_lbl = Label.new()
	type_lbl.text = ItemManager.get_item_type_label(item_data)
	if item_type != 0:
		var preview_effect = ItemManager.create_item_effect(item_data)
		type_lbl.text += " · %s" % preview_effect.get_use_timing_label()
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 10)
	type_lbl.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
	vbox.add_child(type_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc_str
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.tooltip_text = card.tooltip_text
	vbox.add_child(desc_lbl)

	var already_owned = (item_type == 0 and ItemManager.has_joker(id))
	var is_sold = _sold_item_ids.has(id)
	var can_afford    = (RoundManager.game_coins >= price)
	var consumable_full = item_type != 0 and not ItemManager.can_add_consumable()
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(0, 34)
	if is_sold:
		buy_btn.text = "已售罄"; buy_btn.disabled = true
		buy_btn.tooltip_text = "已购买"
	elif already_owned:
		buy_btn.text = "✓ 已拥有"; buy_btn.disabled = true
		buy_btn.tooltip_text = "已经拥有该法宝"
	elif consumable_full:
		buy_btn.text = "道具已满"; buy_btn.disabled = true
		buy_btn.tooltip_text = "道具携带数量已达上限"
	else:
		buy_btn.text = "💎%d 购买" % price; buy_btn.disabled = not can_afford
		buy_btn.tooltip_text = card.tooltip_text if can_afford else "灵石不足"

	var bc = border_color if (can_afford and not already_owned and not consumable_full and not is_sold) else Color(0.4,0.4,0.4,1)
	var bs = StyleBoxFlat.new()
	bs.bg_color = GameTheme.COLOR_BG_PANEL.lerp(bc, 0.24); bs.border_color = bc
	bs.set_border_width_all(2); bs.set_corner_radius_all(5)
	var bh = bs.duplicate(); bh.bg_color = GameTheme.COLOR_BG_PANEL.lerp(bc, 0.40)
	buy_btn.add_theme_stylebox_override("normal", bs)
	buy_btn.add_theme_stylebox_override("hover",  bh)
	buy_btn.add_theme_color_override("font_color", bc)
	buy_btn.add_theme_font_size_override("font_size", 13)
	buy_btn.pressed.connect(func(): _on_buy_pressed(id, item_data))
	vbox.add_child(buy_btn)

	return card

func _on_buy_pressed(item_id: String, item_data: Dictionary):
	# v3.1: 已售罄的商品不可再买
	if _sold_item_ids.has(item_id):
		return
	# Try local buy first (optimistic for immediate feedback)
	if not ItemManager.buy_item(item_data):
		return
	# 标记为售罄
	_sold_item_ids.append(item_id)
	# Then confirm with backend
	GameAPI.buy_item(item_id, _current_shop_node)
	# v3.1: 购买后刷新UI（更新已拥有状态 + 灵石余额）
	_on_shop_items_loaded(_current_shop_items)
	_rebuild_owned_panel()
	coins_label.text = "💎  %d" % RoundManager.game_coins

# ---- 已持有道具 ----
func _rebuild_owned_panel():
	for c in owned_panel.get_children(): c.queue_free()

	if ItemManager.jokers.is_empty() and ItemManager.consumables.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无道具"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1))
		owned_panel.add_child(lbl)
		return

	# 小丑牌 — 带升级按钮的竖向卡片
	for joker in ItemManager.jokers:
		owned_panel.add_child(_make_joker_card(joker))

	# 冲分道具 — 静态标签（战斗时使用）
	if not ItemManager.consumables.is_empty():
		var cap_lbl = Label.new()
		cap_lbl.text = "道具 %d" % ItemManager.consumables.size()
		cap_lbl.add_theme_font_size_override("font_size", 13)
		cap_lbl.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
		cap_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		owned_panel.add_child(cap_lbl)
	for cons in ItemManager.consumables:
		var color = GameTheme.COLOR_RARE if cons.resource_data.get("rarity",0)==1 else GameTheme.COLOR_ACCENT
		owned_panel.add_child(_make_cons_badge(cons, color))

func _make_joker_card(joker) -> Control:
	var color     = GameTheme.COLOR_JOKER
	var name_str  = joker.resource_data.get("display_name", "?")
	var cost      = joker.get_upgrade_cost()
	var max_level = (cost == -1)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(96, 86)
	var cs = StyleBoxFlat.new()
	cs.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.18); cs.border_color = color
	cs.set_border_width_all(2); cs.set_corner_radius_all(6)
	cs.shadow_color = Color(0.03, 0.01, 0.02, 0.36); cs.shadow_size = 4
	cs.content_margin_left = 5; cs.content_margin_right = 5
	cs.content_margin_top  = 5; cs.content_margin_bottom = 5
	card.add_theme_stylebox_override("panel", cs)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	card.add_child(vb)

	# 图标 + 等级
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	vb.add_child(row)

	var icon = Label.new()
	icon.text = ItemManager.get_item_icon(joker); icon.add_theme_font_size_override("font_size", 18)
	row.add_child(icon)

	var lv_lbl = Label.new()
	lv_lbl.text = "Lv%d" % joker.level
	lv_lbl.add_theme_font_size_override("font_size", 12)
	lv_lbl.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	row.add_child(lv_lbl)

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_lbl)

	# 升级按钮
	var upg_btn = Button.new()
	upg_btn.custom_minimum_size = Vector2(0, 30)
	if max_level:
		upg_btn.text = "★ 满级"
		upg_btn.disabled = true
		upg_btn.add_theme_font_size_override("font_size", 11)
		upg_btn.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	else:
		var can_upg = RoundManager.game_coins >= cost
		upg_btn.text = "升级 💎%d" % cost
		upg_btn.disabled = not can_upg
		upg_btn.add_theme_font_size_override("font_size", 11)
		var uc = color if can_upg else Color(0.4, 0.4, 0.4, 1)
		var us = StyleBoxFlat.new()
		us.bg_color = GameTheme.COLOR_BG_PANEL.lerp(uc, 0.24); us.border_color = uc
		us.set_border_width_all(2); us.set_corner_radius_all(5)
		var uh = us.duplicate(); uh.bg_color = GameTheme.COLOR_BG_PANEL.lerp(uc, 0.42)
		upg_btn.add_theme_stylebox_override("normal", us)
		upg_btn.add_theme_stylebox_override("hover",  uh)
		upg_btn.add_theme_color_override("font_color", uc)
		var j = joker
		upg_btn.pressed.connect(func(): _on_upgrade_pressed(j))
	vb.add_child(upg_btn)

	return card

func _make_cons_badge(cons, color: Color) -> Control:
	var lbl = Label.new()
	lbl.custom_minimum_size = Vector2(86, 76)
	lbl.text = "%s\n%s\n%s" % [ItemManager.get_item_icon(cons), cons.resource_data.get("display_name","?"), cons.get_use_timing_label()]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", color * 0.85)
	lbl.tooltip_text = cons.resource_data.get("description","")

	var bg = StyleBoxFlat.new()
	bg.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.16); bg.border_color = color.darkened(0.05)
	bg.set_border_width_all(2); bg.set_corner_radius_all(6)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(86, 76)
	panel.tooltip_text = lbl.tooltip_text
	panel.add_theme_stylebox_override("panel", bg)
	panel.add_child(lbl)
	return panel

func _on_upgrade_pressed(joker):
	var cost = joker.get_upgrade_cost()
	if cost == -1: return
	if RoundManager.game_coins >= cost:
		ItemManager.upgrade_joker(joker)
		coins_label.text = "💎  %d" % RoundManager.game_coins
		_rebuild_owned_panel()
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

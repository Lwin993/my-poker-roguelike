# ShopUI.gd - 商店界面交互
extends Control

@onready var coins_label     = $VBox/HeaderRow/CoinsBadge/CoinsLabel
@onready var sub_title       = $VBox/SubTitle
@onready var shop_grid       = $VBox/ShopGrid
@onready var owned_panel     = $VBox/OwnedPanel
@onready var refresh_button  = $VBox/BottomRow/RefreshButton
@onready var continue_button = $VBox/BottomRow/ContinueButton

var _refresh_count: int = 0
var _has_free_refresh: bool = false
var _rare_boost: bool = false

func _ready():
	_style_button(continue_button, Color(0.20, 0.80, 0.60, 1))
	_style_button(refresh_button,  Color(0.30, 0.65, 1.00, 1))
	refresh_button.pressed.connect(_on_refresh_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

func _style_button(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.22; s.border_color = color
	s.set_border_width_all(2); s.set_corner_radius_all(10)
	var h = s.duplicate(); h.bg_color = color * 0.38
	var p = s.duplicate(); p.bg_color = color * 0.55
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

# ---- 入口 ----
func refresh_shop():
	_refresh_count    = 0
	_has_free_refresh = _check_free_refresh()
	_rare_boost       = _check_rare_boost()
	_update_header()
	_load_shop_items()
	_rebuild_owned_panel()
	_update_refresh_button()

func _check_free_refresh() -> bool:
	for c in ItemManager.consumables:
		if c.resource_data.get("id","") == "refresh_ticket": return true
	return false

func _check_rare_boost() -> bool:
	for c in ItemManager.consumables:
		if c.resource_data.get("id","") == "lucky_compass": return true
	return false

func _update_header():
	var r = RoundManager.current_round + 1
	var b = RoundManager.current_blind
	var bn = ["小盲","大盲","Boss"][clamp(b-1,0,2)] if b > 0 else "小盲"
	sub_title.text = "第 %d 轮 · %s 通关！ 获得 💰%d" % [
		r, bn, RoundManager.coin_rewards[RoundManager.current_round][clamp(b-1,0,2)]
	]
	coins_label.text = "💰  %d" % RoundManager.game_coins

# ---- 商品列表 ----
func _load_shop_items():
	for c in shop_grid.get_children(): c.queue_free()

	var node = clamp(
		RoundManager.current_round * 2 + (RoundManager.current_blind - 1 if RoundManager.current_blind > 0 else 0),
		0, 5
	)
	for item in GameAPI.get_shop_items(node, _rare_boost):
		shop_grid.add_child(_make_shop_card(item))

func _make_shop_card(item_data: Dictionary) -> Control:
	var rarity    = item_data.get("rarity", 0)
	var item_type = item_data.get("item_type", 1)
	var price     = item_data.get("price", 0)
	var name_str  = item_data.get("display_name", "?")
	var desc_str  = item_data.get("description", "")
	var id        = item_data.get("id", "")

	var border_color: Color
	if   rarity == 1:    border_color = Color(1.00, 0.72, 0.10, 1)
	elif item_type == 0: border_color = Color(0.75, 0.45, 1.00, 1)
	else:                border_color = Color(0.30, 0.85, 0.70, 1)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(84, 0)
	var cs = StyleBoxFlat.new()
	cs.bg_color = border_color * 0.12; cs.border_color = border_color * 0.6
	cs.set_border_width_all(1); cs.set_corner_radius_all(8)
	cs.content_margin_left = 6; cs.content_margin_right = 6
	cs.content_margin_top  = 6; cs.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", cs)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var icon_lbl = Label.new()
	icon_lbl.text = "🎭" if item_type == 0 else ("✨" if rarity == 1 else "🧪")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(icon_lbl)

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", border_color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc_str
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var already_owned = (item_type == 0 and ItemManager.has_joker(id))
	var can_afford    = (RoundManager.game_coins >= price)
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(0, 30)
	if already_owned:
		buy_btn.text = "✓ 已拥有"; buy_btn.disabled = true
	else:
		buy_btn.text = "💰%d 购买" % price; buy_btn.disabled = not can_afford

	var bc = border_color if (can_afford and not already_owned) else Color(0.4,0.4,0.4,1)
	var bs = StyleBoxFlat.new()
	bs.bg_color = bc*0.20; bs.border_color = bc
	bs.set_border_width_all(1); bs.set_corner_radius_all(5)
	var bh = bs.duplicate(); bh.bg_color = bc * 0.38
	buy_btn.add_theme_stylebox_override("normal", bs)
	buy_btn.add_theme_stylebox_override("hover",  bh)
	buy_btn.add_theme_color_override("font_color", bc)
	buy_btn.add_theme_font_size_override("font_size", 12)
	buy_btn.pressed.connect(func(): _on_buy_pressed(id, item_data))
	vbox.add_child(buy_btn)

	return card

func _on_buy_pressed(item_id: String, item_data: Dictionary):
	if ItemManager.buy_item(item_data):
		coins_label.text = "💰  %d" % RoundManager.game_coins
		_rebuild_owned_panel()
		_load_shop_items()
		_update_refresh_button()
		GameState.save_state()

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
	for cons in ItemManager.consumables:
		var color = Color(1.0, 0.72, 0.10, 1) if cons.resource_data.get("rarity",0)==1 else Color(0.30, 0.85, 0.70, 1)
		owned_panel.add_child(_make_cons_badge(cons, color))

func _make_joker_card(joker) -> Control:
	var color     = Color(0.75, 0.45, 1.0, 1)
	var name_str  = joker.resource_data.get("display_name", "?")
	var cost      = joker.get_upgrade_cost()
	var max_level = (cost == -1)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(76, 0)
	var cs = StyleBoxFlat.new()
	cs.bg_color = color * 0.12; cs.border_color = color * 0.55
	cs.set_border_width_all(1); cs.set_corner_radius_all(7)
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
	icon.text = "🎭"; icon.add_theme_font_size_override("font_size", 16)
	row.add_child(icon)

	var lv_lbl = Label.new()
	lv_lbl.text = "Lv%d" % joker.level
	lv_lbl.add_theme_font_size_override("font_size", 12)
	lv_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
	row.add_child(lv_lbl)

	var name_lbl = Label.new()
	name_lbl.text = name_str
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(name_lbl)

	# 升级按钮
	var upg_btn = Button.new()
	upg_btn.custom_minimum_size = Vector2(0, 28)
	if max_level:
		upg_btn.text = "★ 满级"
		upg_btn.disabled = true
		upg_btn.add_theme_font_size_override("font_size", 11)
		upg_btn.add_theme_color_override("font_color", Color(1.0, 0.72, 0.10, 1))
	else:
		var can_upg = RoundManager.game_coins >= cost
		upg_btn.text = "升级 💰%d" % cost
		upg_btn.disabled = not can_upg
		upg_btn.add_theme_font_size_override("font_size", 11)
		var uc = color if can_upg else Color(0.4, 0.4, 0.4, 1)
		var us = StyleBoxFlat.new()
		us.bg_color = uc * 0.20; us.border_color = uc
		us.set_border_width_all(1); us.set_corner_radius_all(5)
		var uh = us.duplicate(); uh.bg_color = uc * 0.40
		upg_btn.add_theme_stylebox_override("normal", us)
		upg_btn.add_theme_stylebox_override("hover",  uh)
		upg_btn.add_theme_color_override("font_color", uc)
		var j = joker
		upg_btn.pressed.connect(func(): _on_upgrade_pressed(j))
	vb.add_child(upg_btn)

	return card

func _make_cons_badge(cons, color: Color) -> Control:
	var lbl = Label.new()
	lbl.custom_minimum_size = Vector2(64, 52)
	lbl.text = "🧪\n%s\n(战斗用)" % cons.resource_data.get("display_name","?")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", color * 0.85)
	lbl.tooltip_text = cons.resource_data.get("description","")

	var bg = StyleBoxFlat.new()
	bg.bg_color = color * 0.10; bg.border_color = color * 0.45
	bg.set_border_width_all(1); bg.set_corner_radius_all(6)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 52)
	panel.add_theme_stylebox_override("panel", bg)
	panel.add_child(lbl)
	return panel

func _on_upgrade_pressed(joker):
	var cost = joker.get_upgrade_cost()
	if cost == -1: return
	if RoundManager.game_coins >= cost:
		ItemManager.upgrade_joker(joker)
		coins_label.text = "💰  %d" % RoundManager.game_coins
		_rebuild_owned_panel()
		GameState.save_state()

func _update_refresh_button():
	var cost = _get_refresh_cost()
	refresh_button.text = "🔄  刷新（免费）" if _has_free_refresh else "🔄  刷新（💰%d）" % cost
	refresh_button.disabled = (not _has_free_refresh) and RoundManager.game_coins < cost

func _get_refresh_cost() -> int:
	if _refresh_count == 0: return 0
	return 5 + (_refresh_count - 1) * 5

func _on_refresh_pressed():
	var cost = _get_refresh_cost()
	if _has_free_refresh:
		ItemManager.consume_item("refresh_ticket"); _has_free_refresh = false
	elif RoundManager.game_coins >= cost:
		RoundManager.game_coins -= cost
	else:
		return
	_refresh_count += 1
	_rare_boost = _check_rare_boost()
	_load_shop_items()
	_update_refresh_button()
	coins_label.text = "💰  %d" % RoundManager.game_coins

func _on_continue_pressed():
	RoundManager._set_phase(RoundManager.Phase.PLAYING)

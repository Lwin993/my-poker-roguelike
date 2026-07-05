# GameBoardUI.gd - 主战斗界面交互逻辑
extends Control

@onready var round_label      = $MainVBox/TopBar/RoundBadge/RoundLabel
@onready var coins_label      = $MainVBox/TopBar/CoinsBadge/CoinsLabel
@onready var score_label      = $MainVBox/ScoreContainer/ScoreVBox/ScoreRow/ScoreLabel
@onready var threshold_label  = $MainVBox/ScoreContainer/ScoreVBox/ScoreRow/ThresholdLabel
@onready var progress_bar     = $MainVBox/ScoreContainer/ScoreVBox/ProgressBar
@onready var hand_name_label  = $MainVBox/InfoRow/HandNameLabel
@onready var plays_label      = $MainVBox/InfoRow/PlaysLabel
@onready var discards_label   = $MainVBox/InfoRow/DiscardsLabel
@onready var total_score_label = $MainVBox/TotalScoreLabel
@onready var joker_slots      = $MainVBox/JokerSection/JokerSlots
@onready var cons_slots       = $MainVBox/ConsSection/ConsSlots
@onready var hand_area        = $MainVBox/HandArea
@onready var play_button      = $MainVBox/ButtonRow/PlayButton
@onready var discard_button   = $MainVBox/ButtonRow/DiscardButton
@onready var score_popup      = $ScorePopup
@onready var revive_dialog    = $ReviveDialog

var _selected_indices: Array = []
var _active_consumable_ids: Array = []
var _card_nodes: Array = []

const SUIT_SYMBOLS = ["♠", "♥", "♦", "♣"]
const SUIT_COLORS = {
	0: Color(0.45, 0.75, 1.00, 1),
	1: Color(0.95, 0.30, 0.30, 1),
	2: Color(1.00, 0.55, 0.20, 1),
	3: Color(0.35, 0.85, 0.45, 1),
}

func _ready():
	RoundManager.score_updated.connect(_on_score_updated)
	RoundManager.round_failed.connect(_on_round_failed)
	RoundManager.phase_changed.connect(_on_phase_changed)

	# 出牌按钮：绿色主题
	_style_main_button(play_button, Color(0.20, 0.80, 0.60, 1))
	# 换牌按钮：橙色主题
	_style_main_button(discard_button, Color(0.95, 0.55, 0.10, 1))

	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	revive_dialog.confirmed.connect(_on_revive_ad)
	revive_dialog.canceled.connect(_on_give_up)

	_update_ui()

func _style_main_button(btn: Button, color: Color):
	var normal = StyleBoxFlat.new()
	normal.bg_color = color * 0.22
	normal.border_color = color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover = normal.duplicate()
	hover.bg_color = color * 0.38
	hover.border_color = color * 1.15

	var pressed = normal.duplicate()
	pressed.bg_color = color * 0.55

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _on_phase_changed(phase: int):
	if phase == RoundManager.Phase.PLAYING or phase == RoundManager.Phase.ROUND_START:
		_refresh_all()

func _refresh_all():
	_update_ui()
	_rebuild_hand()
	_rebuild_jokers()
	_rebuild_consumables()

func _update_ui():
	var r = RoundManager.current_round + 1
	var blind_name = RoundManager.get_current_blind_name()
	round_label.text = "第 %d 轮 · %s" % [r, blind_name]
	coins_label.text = "💰 %d" % RoundManager.game_coins

	var plays = RoundManager.plays_left
	var discards = RoundManager.discards_left
	plays_label.text = "出牌 × %d" % plays
	discards_label.text = "换牌 × %d" % discards
	plays_label.add_theme_color_override("font_color",
		Color(0.45, 0.85, 1.0, 1) if plays > 0 else Color(0.5, 0.3, 0.3, 1))
	discards_label.add_theme_color_override("font_color",
		Color(0.95, 0.65, 0.25, 1) if discards > 0 else Color(0.5, 0.3, 0.3, 1))

	total_score_label.text = "累计总分: %d" % RoundManager.total_score

	var threshold = RoundManager.get_current_threshold()
	score_label.text = "本回合: %d" % RoundManager.round_score
	threshold_label.text = "/ %d" % threshold
	progress_bar.max_value = threshold
	progress_bar.value = min(RoundManager.round_score, threshold)

	play_button.disabled = plays <= 0
	discard_button.disabled = discards <= 0

func _on_score_updated(_rs: int, _ts: int):
	_update_ui()

# ========== 手牌重建 ==========
func _rebuild_hand():
	for node in _card_nodes:
		node.queue_free()
	_card_nodes.clear()
	_selected_indices.clear()

	for i in range(DeckManager.hand.size()):
		var card = DeckManager.hand[i]
		var btn = _make_card_button(card, i)
		hand_area.add_child(btn)
		_card_nodes.append(btn)

	_update_hand_name_label()

func _make_card_button(card, idx: int) -> Button:
	var suit_color = SUIT_COLORS[card.suit]
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(50, 78)

	# 点数大字 + 花色小字
	btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", suit_color)

	_apply_card_style(btn, suit_color, false)

	var i = idx
	btn.pressed.connect(func(): _on_card_pressed(i))
	return btn

func _apply_card_style(btn: Button, suit_color: Color, selected: bool):
	var normal = StyleBoxFlat.new()
	var hover  = StyleBoxFlat.new()

	if selected:
		normal.bg_color = suit_color * 0.28
		normal.border_color = Color(1.0, 0.85, 0.15, 1)
		normal.set_border_width_all(2)
		normal.shadow_color = Color(1.0, 0.85, 0.15, 0.35)
		normal.shadow_size = 5
		hover.bg_color = suit_color * 0.38
		hover.border_color = Color(1.0, 0.95, 0.50, 1)
		hover.set_border_width_all(2)
		hover.shadow_color = Color(1.0, 0.85, 0.15, 0.5)
		hover.shadow_size = 6
	else:
		normal.bg_color = Color(0.10, 0.15, 0.22, 1)
		normal.border_color = suit_color * 0.6
		normal.set_border_width_all(1)
		hover.bg_color = Color(0.14, 0.20, 0.30, 1)
		hover.border_color = suit_color
		hover.set_border_width_all(1)

	normal.set_corner_radius_all(8)
	hover.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _on_card_pressed(idx: int):
	if _selected_indices.has(idx):
		_selected_indices.erase(idx)
	else:
		if _selected_indices.size() < 5:
			_selected_indices.append(idx)
	_update_card_visuals()
	_update_hand_name_label()

func _update_card_visuals():
	for i in range(_card_nodes.size()):
		var btn = _card_nodes[i]
		var card = DeckManager.hand[i]
		var suit_color = SUIT_COLORS[card.suit]
		var sel = _selected_indices.has(i)
		_apply_card_style(btn, suit_color, sel)
		# 选中时卡牌颜色更亮
		if sel:
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_color_override("font_color", suit_color)

func _update_hand_name_label():
	if _selected_indices.size() == 5:
		var sel_cards = []
		for idx in _selected_indices:
			sel_cards.append(DeckManager.hand[idx])
		var result = HandEvaluator.evaluate(sel_cards)
		hand_name_label.text = "✨ %s   基础分 %d" % [result.hand_name, result.base_score]
		hand_name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
	elif _selected_indices.size() > 0:
		hand_name_label.text = "已选 %d 张（还需选 %d 张）" % [_selected_indices.size(), 5 - _selected_indices.size()]
		hand_name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.5, 1))
	else:
		hand_name_label.text = "← 点击手牌选择，选满5张出牌"
		hand_name_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 1))

# ========== 道具重建 ==========
func _rebuild_jokers():
	for child in joker_slots.get_children():
		child.queue_free()

	if ItemManager.jokers.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无小丑牌"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1))
		joker_slots.add_child(lbl)
		return

	for joker in ItemManager.jokers:
		joker_slots.add_child(_make_joker_badge(joker))

func _make_joker_badge(joker) -> Control:
	var color    = Color(0.75, 0.45, 1.0, 1)
	var name_str = joker.resource_data.get("display_name", "?")
	var desc_str = joker.resource_data.get("description", "")

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(68, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color = color * 0.12; ps.border_color = color * 0.55
	ps.set_border_width_all(1); ps.set_corner_radius_all(7)
	ps.content_margin_left = 4; ps.content_margin_right = 4
	ps.content_margin_top  = 4; ps.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", ps)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var top_row = HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 2)
	vb.add_child(top_row)

	var icon = Label.new()
	icon.text = "🎭"; icon.add_theme_font_size_override("font_size", 14)
	top_row.add_child(icon)

	var lv = Label.new()
	lv.text = "Lv%d" % joker.level
	lv.add_theme_font_size_override("font_size", 11)
	lv.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
	top_row.add_child(lv)

	var nm = Label.new()
	nm.text = name_str
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 10)
	nm.add_theme_color_override("font_color", color)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.tooltip_text = desc_str
	vb.add_child(nm)

	return panel

# ---------- 冲分道具 ----------
func _rebuild_consumables():
	for child in cons_slots.get_children():
		child.queue_free()
	_active_consumable_ids.clear()

	if ItemManager.consumables.is_empty():
		var lbl = Label.new()
		lbl.text = "暂无冲分道具"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1))
		cons_slots.add_child(lbl)
		return

	for cons in ItemManager.consumables:
		cons_slots.add_child(_make_consumable_card(cons))

func _make_consumable_card(cons) -> Control:
	var id       = cons.resource_data.get("id", "")
	var name_str = cons.resource_data.get("display_name", "?")
	var rarity   = cons.resource_data.get("rarity", 0)
	var desc_str = cons.resource_data.get("description", "")
	var color    = Color(1.0, 0.72, 0.10, 1) if rarity == 1 else Color(0.30, 0.85, 0.70, 1)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(68, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color = color * 0.11; ps.border_color = color * 0.50
	ps.set_border_width_all(1); ps.set_corner_radius_all(7)
	ps.content_margin_left = 4; ps.content_margin_right = 4
	ps.content_margin_top  = 4; ps.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", ps)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var icon = Label.new()
	icon.text = "✨" if rarity == 1 else "🧪"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 14)
	vb.add_child(icon)

	var nm = Label.new()
	nm.text = name_str
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 10)
	nm.add_theme_color_override("font_color", color)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.tooltip_text = desc_str
	vb.add_child(nm)

	# 激活/取消按钮
	var use_btn = Button.new()
	use_btn.custom_minimum_size = Vector2(0, 24)
	use_btn.text = "激活"
	use_btn.toggle_mode = true
	use_btn.add_theme_font_size_override("font_size", 11)

	var bs_off = StyleBoxFlat.new()
	bs_off.bg_color = color * 0.18; bs_off.border_color = color * 0.65
	bs_off.set_border_width_all(1); bs_off.set_corner_radius_all(5)
	var bs_on = StyleBoxFlat.new()
	bs_on.bg_color = color * 0.50; bs_on.border_color = Color.WHITE
	bs_on.set_border_width_all(2); bs_on.set_corner_radius_all(5)
	var bs_hover = bs_off.duplicate()
	bs_hover.bg_color = color * 0.32; bs_hover.border_color = color

	use_btn.add_theme_stylebox_override("normal",  bs_off)
	use_btn.add_theme_stylebox_override("hover",   bs_hover)
	use_btn.add_theme_stylebox_override("pressed", bs_on)
	use_btn.add_theme_color_override("font_color",         color)
	use_btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	use_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	vb.add_child(use_btn)

	var cap_id   = id
	var cap_btn  = use_btn
	var cap_ps   = ps
	var cap_col  = color
	use_btn.toggled.connect(func(on): _on_consumable_toggled(cap_id, on, cap_btn, cap_ps, cap_col))

	return panel

func _on_consumable_toggled(item_id: String, is_on: bool, btn: Button, panel_style: StyleBoxFlat, color: Color):
	if is_on:
		if not _active_consumable_ids.has(item_id):
			_active_consumable_ids.append(item_id)
		btn.text = "✓ 已激活"
		panel_style.border_color = Color.WHITE
		panel_style.bg_color     = color * 0.26
	else:
		_active_consumable_ids.erase(item_id)
		btn.text = "激活"
		panel_style.border_color = color * 0.50
		panel_style.bg_color     = color * 0.11

# ========== 出牌 / 换牌 ==========
func _on_play_pressed():
	if _selected_indices.size() != 5:
		_show_tip("请选择 5 张牌！", Color(0.95, 0.35, 0.35, 1))
		return
	if RoundManager.plays_left <= 0:
		return

	play_button.disabled = true
	discard_button.disabled = true

	var result = await RoundManager.play_hand(
		_selected_indices.duplicate(), _active_consumable_ids.duplicate()
	)
	_show_score_popup(result)
	_rebuild_hand()
	_rebuild_consumables()
	_update_ui()

	play_button.disabled = RoundManager.plays_left <= 0
	discard_button.disabled = RoundManager.discards_left <= 0

func _on_discard_pressed():
	if _selected_indices.is_empty():
		_show_tip("请选择要换掉的牌！", Color(0.95, 0.60, 0.15, 1))
		return
	if RoundManager.discards_left <= 0:
		return

	RoundManager.discard_cards(_selected_indices.duplicate())
	_rebuild_hand()
	_update_ui()
	GameState.save_state()

# ========== 动画 ==========
func _show_score_popup(result: Dictionary):
	var score = result.get("score", 0)
	var is_crit = result.get("is_crit", false)

	if is_crit:
		score_popup.text = "💥 CRIT!\n+%d" % score
		score_popup.add_theme_color_override("font_color", Color(1.0, 0.45, 0.10, 1))
		score_popup.add_theme_font_size_override("font_size", 34)
	else:
		score_popup.text = "+%d" % score
		score_popup.add_theme_color_override("font_color", Color(1.0, 0.92, 0.20, 1))
		score_popup.add_theme_font_size_override("font_size", 38)

	score_popup.visible = true
	score_popup.modulate.a = 1.0
	var start_y = score_popup.position.y

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(score_popup, "position:y", start_y - 70, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_popup, "modulate:a", 0.0, 1.0).set_delay(0.3)
	await tween.finished
	score_popup.visible = false
	score_popup.position.y = start_y

func _show_tip(msg: String, color: Color):
	score_popup.text = msg
	score_popup.add_theme_color_override("font_color", color)
	score_popup.add_theme_font_size_override("font_size", 20)
	score_popup.modulate.a = 1.0
	score_popup.visible = true
	await get_tree().create_timer(1.2).timeout
	score_popup.visible = false
	score_popup.add_theme_font_size_override("font_size", 38)

# ========== 复活 ==========
func _on_round_failed(_round_idx: int, _blind_idx: int):
	if RoundManager.can_revive():
		revive_dialog.dialog_text = (
			"出牌次数耗尽，未达到门槛分！\n" +
			"已使用复活 %d / %d 次\n\n选择复活方式继续：" % [
				RoundManager.revive_count, RoundManager.max_revives
			]
		)
		revive_dialog.popup_centered()
	else:
		GameAPI.submit_result()
		RoundManager.phase_changed.emit(RoundManager.Phase.FINAL_RESULT)

func _on_revive_ad():
	RoundManager.revive()
	_refresh_all()
	GameState.save_state()

func _on_give_up():
	GameAPI.submit_result()
	RoundManager.phase_changed.emit(RoundManager.Phase.FINAL_RESULT)

# GameBoardUI.gd - 主战斗界面交互逻辑
extends Control

# ── 左侧状态栏 ──
@onready var round_label       = $MainHBox/Sidebar/RoundBadge/RoundLabel
@onready var coins_label       = $MainHBox/Sidebar/EconomyPanel/EconomyVBox/CoinsLabel
# ── 分数 ──
@onready var score_label       = $MainHBox/Sidebar/ScoreContainer/ScoreVBox/ScoreLabel
@onready var threshold_label   = $MainHBox/Sidebar/ScoreContainer/ScoreVBox/ThresholdLabel
@onready var progress_bar      = $MainHBox/Sidebar/ScoreContainer/ScoreVBox/ProgressBar
@onready var round_score_detail = $MainHBox/Sidebar/ScoreContainer/ScoreVBox/RoundScoreLabel
# ── 信息行 ──
@onready var hand_name_label   = $MainHBox/TableVBox/HandRow/HandHintLabel
@onready var boss_skill_label  = $MainHBox/TableVBox/HandRow/BossSkillLabel
@onready var plays_label       = $MainHBox/Sidebar/ActionCounts/PlaysLabel
@onready var discards_label    = $MainHBox/Sidebar/ActionCounts/DiscardsLabel
@onready var total_score_label = $MainHBox/Sidebar/EconomyPanel/EconomyVBox/TotalScoreLabel
# ── 参数面板 ──
@onready var mult_label        = $MainHBox/Sidebar/ParamsPanel/ParamsVBox/MultLabel
@onready var crit_rate_label   = $MainHBox/Sidebar/ParamsPanel/ParamsVBox/CritRateLabel
@onready var crit_mult_label   = $MainHBox/Sidebar/ParamsPanel/ParamsVBox/CritMultLabel
# ── 道具区 ──
@onready var joker_slots       = $MainHBox/TableVBox/JokerSection/JokerSlots
@onready var cons_slots        = $MainHBox/TableVBox/JokerSection/ConsSlots
# ── 手牌 / 按钮 ──
@onready var hand_area         = $MainHBox/TableVBox/HandRow/HandArea
@onready var play_button       = $MainHBox/Sidebar/ButtonRow/PlayButton
@onready var discard_button    = $MainHBox/Sidebar/ButtonRow/DiscardButton
@onready var sort_by_rank_btn  = $MainHBox/TableVBox/BottomTools/SortRow/SortByRankButton
@onready var sort_by_suit_btn  = $MainHBox/TableVBox/BottomTools/SortRow/SortBySuitButton
# ── 弹出层 ──
@onready var score_popup       = $ScorePopup
@onready var revive_dialog     = $ReviveDialog
# ── 牌桌内联计分区 ──
@onready var calc_title        = $MainHBox/TableVBox/PlaySurface/CalcTitle
@onready var formula_label     = $MainHBox/TableVBox/PlaySurface/FormulaLabel
@onready var played_area       = $MainHBox/TableVBox/PlaySurface/PlayedCenter/PlayedArea
@onready var score_burst_label = $MainHBox/TableVBox/PlaySurface/ScoreBurstLabel
@onready var calc_steps_list   = $MainHBox/TableVBox/PlaySurface/CalcStepsList
@onready var final_score_label = $MainHBox/TableVBox/PlaySurface/FinalScoreLabel
@onready var crit_banner       = $MainHBox/TableVBox/PlaySurface/CritBanner
@onready var calc_close_hint   = $MainHBox/TableVBox/PlaySurface/CalcCloseHint
# ── 法宝详情浮层 ──
@onready var joker_detail_overlay = $JokerDetailOverlay
@onready var joker_detail_bg      = $JokerDetailOverlay/JokerDetailBG
@onready var joker_detail_title   = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailTitle
@onready var joker_detail_level   = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailLevel
@onready var joker_detail_desc    = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailDesc
@onready var joker_detail_params  = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailParams
@onready var joker_detail_close   = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailClose

# ── 状态 ──
var _used_consumable_ids:   Array = []
var _used_consumable_items: Array = []
var _selected_indices:      Array = []
var _card_nodes:            Array = []
var _base_score_preview:    int   = 0
var _joker_badge_nodes:     Array = []

const SUIT_SYMBOLS = ["♠", "♥", "♦", "♣"]
const SUIT_COLORS  = {
	0: Color(0.11, 0.12, 0.20, 1),
	1: Color(0.92, 0.12, 0.15, 1),
	2: Color(0.96, 0.38, 0.08, 1),
	3: Color(0.04, 0.46, 0.27, 1),
}

# ════════════════════════════════════════════════════════════════
func _ready():
	RoundManager.score_updated.connect(_on_score_updated)
	RoundManager.round_failed.connect(_on_round_failed)
	RoundManager.phase_changed.connect(_on_phase_changed)

	_style_main_button(play_button,    GameTheme.COLOR_ACCENT)
	_style_main_button(discard_button, GameTheme.COLOR_GOLD)

	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	revive_dialog.confirmed.connect(_on_revive_ad)
	revive_dialog.canceled.connect(_on_give_up)

	# Connect revive API signals
	GameAPI.revive_prepared.connect(_on_revive_prepared)
	GameAPI.revive_completed.connect(_on_revive_completed)

	# 排序按钮
	_style_sort_button(sort_by_rank_btn, Color(0.45, 0.75, 1.00, 1))
	_style_sort_button(sort_by_suit_btn, Color(0.55, 0.85, 0.55, 1))
	sort_by_rank_btn.pressed.connect(_on_sort_by_rank)
	sort_by_suit_btn.pressed.connect(_on_sort_by_suit)

	# 法宝详情关闭按钮
	joker_detail_close.pressed.connect(func(): joker_detail_overlay.visible = false)
	joker_detail_bg.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			joker_detail_overlay.visible = false
	)

	_style_button(joker_detail_close, GameTheme.COLOR_BLUE_CHIP)
	crit_rate_label.visible = true
	crit_mult_label.visible = false
	_reset_inline_calc()
	_update_ui()

func _style_main_button(btn: Button, color: Color):
	var s = GameTheme.get_button_style(color)
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top  = 8;  s.content_margin_bottom = 8
	var h = GameTheme.get_button_hover_style(color)
	var p = GameTheme.get_button_pressed_style(color)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color",       GameTheme.COLOR_TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _style_button(btn: Button, color: Color):
	var s = GameTheme.get_button_style(color)
	var h = GameTheme.get_button_hover_style(color)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)
	btn.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_MAIN)

func _style_sort_button(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.16); s.border_color = color.darkened(0.18)
	s.set_border_width_all(2); s.set_corner_radius_all(5)
	s.content_margin_left = 6; s.content_margin_right = 6
	s.content_margin_top  = 2; s.content_margin_bottom = 2
	var h = s.duplicate(); h.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.30); h.border_color = color
	var p = s.duplicate(); p.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.45)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color",       GameTheme.COLOR_TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

# ── 排序 ────────────────────────────────────────────────────────
# 排序只改 DeckManager.hand 的顺序（A 视为最大），选中状态随之重映射
func _on_sort_by_rank():
	_sort_hand(func(a, b):
		var ra = 14 if a.rank == 1 else a.rank
		var rb = 14 if b.rank == 1 else b.rank
		return ra > rb  # 大 → 小
	)

func _on_sort_by_suit():
	_sort_hand(func(a, b):
		if a.suit != b.suit: return a.suit < b.suit  # ♠♥♦♣ 顺序
		var ra = 14 if a.rank == 1 else a.rank
		var rb = 14 if b.rank == 1 else b.rank
		return ra > rb  # 同花色内大 → 小
	)

func _sort_hand(comparator: Callable):
	# 记住当前选中的牌对象，排序后重新映射索引
	var selected_cards = []
	for idx in _selected_indices:
		selected_cards.append(DeckManager.hand[idx])

	DeckManager.hand.sort_custom(comparator)

	# 重新映射选中索引
	_selected_indices.clear()
	for card in selected_cards:
		var new_idx = DeckManager.hand.find(card)
		if new_idx != -1 and not _selected_indices.has(new_idx):
			_selected_indices.append(new_idx)

	_rebuild_hand_keep_selection()

func _on_phase_changed(phase: int):
	if phase == RoundManager.Phase.PLAYING or phase == RoundManager.Phase.ROUND_START:
		_refresh_all()

func _refresh_all():
	_clear_used_consumables()
	_update_ui()
	_rebuild_hand()
	_rebuild_jokers()
	_rebuild_consumables()
	_update_params_panel()

# ════════════════════════════════════════════════════════════════
# 基础 UI
# ════════════════════════════════════════════════════════════════
func _update_ui():
	round_label.text  = RoundManager.get_current_blind_name()
	coins_label.text  = "💎 %d" % RoundManager.game_coins
	total_score_label.text = "累计总分: %d" % RoundManager.total_score

	# v3.1: 怪物名+技能提示
	var monster_name = RoundManager.get_current_monster_name()
	var skill_text = RoundManager.get_current_enemy_skill_text()
	if skill_text != "":
		boss_skill_label.text = skill_text
		if skill_text.find("已克制") != -1:
			boss_skill_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1))
		elif skill_text.find("👹") != -1:
			boss_skill_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1))
		else:
			boss_skill_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 1))
	else:
		boss_skill_label.text = ""

	var plays    = RoundManager.plays_left
	var discards = RoundManager.discards_left
	plays_label.text    = "出牌\n%d" % plays
	discards_label.text = "换牌\n%d" % discards
	plays_label.add_theme_color_override("font_color",
		GameTheme.COLOR_BLUE_CHIP if plays > 0 else Color(0.42, 0.26, 0.28, 1))
	discards_label.add_theme_color_override("font_color",
		GameTheme.COLOR_GOLD if discards > 0 else Color(0.42, 0.26, 0.28, 1))

	var threshold = RoundManager.get_current_threshold()
	score_label.text     = "%d" % RoundManager.round_score
	threshold_label.text = "❤️ 血量: %d / %d" % [RoundManager.round_score, threshold]
	round_score_detail.text = "已造成伤害: %d" % RoundManager.round_score
	progress_bar.max_value = threshold
	progress_bar.value     = min(RoundManager.round_score, threshold)

	play_button.disabled    = plays <= 0
	discard_button.disabled = discards <= 0

func _on_score_updated(_rs: int, _ts: int):
	_update_ui()

# ════════════════════════════════════════════════════════════════
# 参数面板（实时预览）
# ════════════════════════════════════════════════════════════════
func _update_params_panel(hand_result: Dictionary = {}):
	_base_score_preview = hand_result.get("base_chips", 0) + hand_result.get("card_chips", 0)
	var params = ScoreCalculator.preview_params(
		hand_result,
		[],
		_used_consumable_items,
		DeckManager.hand
	)
	_apply_params_to_labels(
		params.get("mult",      1.0),
		params.get("crit_rate", 0.0),
		params.get("crit_mult", 2.0)
	)

func _apply_params_to_labels(mult: float, cr: float, cm: float):
	mult_label.text      = "基础伤害 %d\n倍率 ×%.2f" % [_base_score_preview, mult]
	crit_rate_label.text = "暴击率 %d%%" % int(cr * 100)
	crit_mult_label.text = "暴击倍数 ×%.1f" % cm

	mult_label.add_theme_color_override("font_color",
		GameTheme.COLOR_GOLD if mult > 1.01 else GameTheme.COLOR_BLUE_CHIP)
	crit_rate_label.add_theme_color_override("font_color",
		GameTheme.COLOR_RARE if cr > 0.001 else GameTheme.COLOR_TEXT_DIM)
	crit_mult_label.add_theme_color_override("font_color",
		GameTheme.COLOR_CRIT if cm > 2.01 else GameTheme.COLOR_TEXT_DIM)

# ════════════════════════════════════════════════════════════════
# 手牌
# ════════════════════════════════════════════════════════════════
func _rebuild_hand():
	for node in _card_nodes: node.queue_free()
	_card_nodes.clear()
	_selected_indices.clear()
	_update_played_preview()
	_sort_deck_by_rank()
	for i in range(DeckManager.hand.size()):
		var btn = _make_card_button(DeckManager.hand[i], i)
		hand_area.add_child(btn)
		_card_nodes.append(btn)
	_update_hand_name_label()
	# Don't call _update_params_panel() here — _update_hand_name_label already handles it

# 排序后重建手牌，保留选中状态
func _rebuild_hand_keep_selection():
	for node in _card_nodes: node.queue_free()
	_card_nodes.clear()
	for i in range(DeckManager.hand.size()):
		var btn = _make_card_button(DeckManager.hand[i], i)
		hand_area.add_child(btn)
		_card_nodes.append(btn)
	_update_card_visuals()
	_update_hand_name_label()

func _sort_deck_by_rank():
	DeckManager.hand.sort_custom(func(a, b):
		var ra = 14 if a.rank == 1 else a.rank
		var rb = 14 if b.rank == 1 else b.rank
		return ra > rb
	)

func _make_card_button(card, idx: int) -> Button:
	var sc  = SUIT_COLORS[card.suit]
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(74, 112)

	# v3.1: 精英怪/大妖技能视觉特效
	var is_locked = not BossSkillManager.is_card_selectable(idx, DeckManager.hand)
	var is_hidden = not BossSkillManager.is_card_visible(idx)

	if is_hidden:
		# 背面朝上（小旋风/风沙走石）
		btn.text = "?\n?"
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
		_apply_card_style(btn, Color(0.3, 0.3, 0.3, 1), false)
		btn.tooltip_text = "此牌被遮挡，无法查看"
	elif is_locked:
		# 幻影牌/锁定牌（骷髅将/白骨幻术）
		btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.5))
		_apply_card_style(btn, Color(0.5, 0.5, 0.5, 0.6), false)
		btn.tooltip_text = "此牌被锁定，不可选中"
	else:
		btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", sc)
		_apply_card_style(btn, sc, false)

	var i = idx
	btn.pressed.connect(func(): _on_card_pressed(i))
	return btn

func _apply_card_style(btn: Button, sc: Color, selected: bool):
	var normal = GameTheme.get_card_style(sc, selected)
	var hover  = GameTheme.get_card_style(sc, selected)
	hover.bg_color = Color(1.0, 0.95, 0.78, 1) if not selected else Color(1.0, 0.86, 0.36, 1)
	hover.border_color = sc if not selected else Color(1.0, 0.96, 0.52, 1)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 14
	normal.content_margin_bottom = 14
	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 14
	hover.content_margin_bottom = 14
	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _on_card_pressed(idx: int):
	# v3.1: 被锁定的牌不可选中（骷髅将/白骨幻术）
	if not BossSkillManager.is_card_selectable(idx, DeckManager.hand):
		return
	if _selected_indices.has(idx): _selected_indices.erase(idx)
	elif _selected_indices.size() < 5: _selected_indices.append(idx)
	_update_card_visuals()
	_update_hand_name_label()

func _update_card_visuals():
	for i in range(_card_nodes.size()):
		var btn = _card_nodes[i]
		var card = DeckManager.hand[i]
		var sc = SUIT_COLORS[card.suit]

		# v3.1: 被锁定/遮挡的牌保持特殊视觉
		var is_locked = not BossSkillManager.is_card_selectable(i, DeckManager.hand)
		var is_hidden = not BossSkillManager.is_card_visible(i)

		if is_hidden:
			btn.text = "?\n?"
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
			_apply_card_style(btn, Color(0.3, 0.3, 0.3, 1), false)
			btn.position.y = 0
			continue
		elif is_locked:
			btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
			_apply_card_style(btn, Color(0.5, 0.5, 0.5, 0.6), false)
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.5))
			btn.position.y = 0
			continue

		var sel = _selected_indices.has(i)
		_apply_card_style(btn, sc, sel)
		btn.add_theme_color_override("font_color", GameTheme.COLOR_CARD_INK if sel else sc)
		btn.position.y = -12 if sel else 0
	_update_played_preview()

func _update_hand_name_label():
	if _selected_indices.size() == 5:
		var sel_cards = []; for idx in _selected_indices: sel_cards.append(DeckManager.hand[idx])
		var result = HandEvaluator.evaluate(sel_cards)
		hand_name_label.text = "%s\n伤害 %d  ×%d" % [result.hand_name, result.base_chips + result.card_chips, result.base_mult]
		hand_name_label.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
		_base_score_preview = result.base_chips + result.card_chips
		_update_params_panel(result)
	elif _selected_indices.size() > 0:
		# v3.1: 实时预览 — 即使不足5张也计算当前选中牌的伤害值
		var sel_cards = []; for idx in _selected_indices: sel_cards.append(DeckManager.hand[idx])
		var card_chips = 0
		for c in sel_cards:
			card_chips += c.get_chip_value()
		var preview_damage = card_chips
		hand_name_label.text = "已选 %d 张\n预览伤害 ~%d" % [_selected_indices.size(), preview_damage]
		hand_name_label.add_theme_color_override("font_color", Color(0.98, 0.76, 0.34, 1))
		# 预览参数面板用部分牌的chips
		_base_score_preview = card_chips
		_apply_params_to_labels(1.0, 0.05, 2.0)
	else:
		hand_name_label.text = "选择 5 张牌"
		hand_name_label.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
		_update_params_panel()

func _update_played_preview():
	for child in played_area.get_children():
		child.queue_free()
	if _selected_indices.is_empty():
		return
	for idx in _selected_indices:
		if idx >= 0 and idx < DeckManager.hand.size():
			played_area.add_child(_make_table_card(DeckManager.hand[idx]))

func _make_table_card(card) -> Button:
	var sc = SUIT_COLORS[card.suit]
	var btn = Button.new()
	btn.disabled = true
	btn.custom_minimum_size = Vector2(58, 86)
	btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
	btn.add_theme_font_size_override("font_size", 19)
	btn.add_theme_color_override("font_color", sc)
	var style = GameTheme.get_card_style(sc, false)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_color_override("font_disabled_color", sc)
	return btn

# ════════════════════════════════════════════════════════════════
# 法宝
# ════════════════════════════════════════════════════════════════
func _rebuild_jokers():
	for child in joker_slots.get_children(): child.queue_free()
	_joker_badge_nodes.clear()
	if ItemManager.jokers.is_empty():
		var lbl = Label.new(); lbl.text = "暂无法宝"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1))
		joker_slots.add_child(lbl); return
	for joker in ItemManager.jokers:
		var badge = _make_joker_badge(joker)
		joker_slots.add_child(badge)
		_joker_badge_nodes.append(badge)

func _make_joker_badge(joker) -> Control:
	var color = GameTheme.COLOR_JOKER

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(74, 58)
	btn.tooltip_text = joker.resource_data.get("description", "")

	var s = StyleBoxFlat.new()
	s.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.20); s.border_color = color
	s.set_border_width_all(2); s.set_corner_radius_all(6)
	s.content_margin_left = 4; s.content_margin_right = 4
	s.content_margin_top = 4; s.content_margin_bottom = 4
	var h = s.duplicate(); h.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.36); h.border_color = color.lightened(0.16)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)

	# 内部用 RichTextLabel 排版
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 1)
	btn.add_child(vb)

	var row = HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2); vb.add_child(row)

	var icon = Label.new(); icon.text = "🎭"; icon.add_theme_font_size_override("font_size", 15)
	row.add_child(icon)
	var lv = Label.new(); lv.text = "Lv%d" % joker.level
	lv.add_theme_font_size_override("font_size", 10)
	lv.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	row.add_child(lv)

	var nm = Label.new()
	nm.text = joker.resource_data.get("display_name", "?")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_size_override("font_size", 10)
	nm.add_theme_color_override("font_color", color)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nm)

	var j = joker
	btn.pressed.connect(func(): _show_joker_detail(j))
	return btn

# ── 法宝详情弹窗 ──────────────────────────────────────────
func _show_joker_detail(joker):
	var color    = GameTheme.COLOR_JOKER
	var name_str = joker.resource_data.get("display_name", "?")
	var desc_str = joker.resource_data.get("description", "")

	joker_detail_title.text = "🎭  %s" % name_str
	joker_detail_level.text = "等级：Lv%d / 3" % joker.level
	joker_detail_desc.text  = desc_str

	# 清空旧参数
	for child in joker_detail_params.get_children(): child.queue_free()

	if joker.has_method("get_chain_info"):
		var info = joker.get_chain_info()
		_add_param_row("第一手牌型", info.get("hand_name", "尚未触发"), GameTheme.COLOR_GOLD, info.get("has_chain", false))
		_add_param_row("连锁次数", "%d 次" % info.get("consecutive", 0), GameTheme.COLOR_TEXT_DIM, info.get("consecutive", 0) > 0)
		_add_param_row("提升倍率", "+%.2f" % info.get("current_bonus", 0.0), GameTheme.COLOR_BLUE_CHIP, info.get("current_bonus", 0.0) != 0.0)
		_add_param_row("每次提升", "+%.2f" % info.get("per_stack", 0.0), GameTheme.COLOR_JOKER, true)
	else:
		# 获取当前等级下的参数贡献
		var delta = joker.get_passive_modifiers({})
		var dm    = delta.get("mult_add",      0.0)
		var dcr   = delta.get("crit_rate_add", 0.0)
		var dcm   = delta.get("crit_mult_add", 0.0)
		var dsm   = delta.get("special_mult",  1.0)

		_add_param_row("倍率加成",      "+%.2f" % dm,            GameTheme.COLOR_BLUE_CHIP, dm != 0.0)
		_add_param_row("暴击率加成",    "+%d%%" % int(dcr*100),  Color(1.0, 0.72, 0.10, 1), dcr != 0.0)
		_add_param_row("暴击倍数加成",  "+%.1f" % dcm,           Color(1.0, 0.40, 0.10, 1), dcm != 0.0)
		if dsm != 1.0:
			_add_param_row("特殊倍率", "×%.2f" % dsm, GameTheme.COLOR_JOKER, true)

	# 升级后预览（若未满级）
	var cost = joker.get_upgrade_cost()
	if cost != -1 and joker.level < 3:
		var sep = HSeparator.new(); joker_detail_params.add_child(sep)
		var hint = Label.new()
		hint.text = "升级 Lv%d → Lv%d 需要 💰%d（在商店升级）" % [joker.level, joker.level + 1, cost]
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		joker_detail_params.add_child(hint)

	joker_detail_overlay.visible = true

func _add_param_row(param_name: String, value_str: String, color: Color, active: bool):
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 6)
	joker_detail_params.add_child(row)

	var nm = Label.new(); nm.text = param_name; nm.custom_minimum_size = Vector2(110, 0)
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
	row.add_child(nm)

	var vl = Label.new(); vl.text = value_str
	vl.add_theme_font_size_override("font_size", 14)
	vl.add_theme_color_override("font_color", color if active else Color(0.4, 0.4, 0.4, 1))
	row.add_child(vl)

# ════════════════════════════════════════════════════════════════
# 冲分道具
# ════════════════════════════════════════════════════════════════
func _rebuild_consumables():
	for child in cons_slots.get_children(): child.queue_free()
	if ItemManager.consumables.is_empty():
		var lbl = Label.new(); lbl.text = "暂无冲分道具"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1))
		cons_slots.add_child(lbl); return
	for cons in ItemManager.consumables:
		cons_slots.add_child(_make_consumable_card(cons))

func _make_consumable_card(cons) -> Control:
	var id      = cons.resource_data.get("id", "")
	var name_s  = cons.resource_data.get("display_name", "?")
	var rarity  = cons.resource_data.get("rarity", 0)
	var desc_s  = cons.resource_data.get("description", "")
	var color   = GameTheme.COLOR_RARE if rarity == 1 else GameTheme.COLOR_ACCENT

	var panel = PanelContainer.new(); panel.custom_minimum_size = Vector2(74, 54)
	panel.tooltip_text = "%s\n%s" % [name_s, desc_s]
	var ps = StyleBoxFlat.new()
	ps.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.16); ps.border_color = color.darkened(0.05)
	ps.set_border_width_all(2); ps.set_corner_radius_all(6)
	ps.content_margin_left = 4; ps.content_margin_right = 4
	ps.content_margin_top  = 4; ps.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", ps)

	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 2); panel.add_child(vb)

	var icon = Label.new(); icon.text = "✨" if rarity == 1 else "🧪"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; icon.add_theme_font_size_override("font_size", 13)
	icon.tooltip_text = panel.tooltip_text
	vb.add_child(icon)

	var nm = Label.new(); nm.text = name_s
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; nm.add_theme_font_size_override("font_size", 10)
	nm.add_theme_color_override("font_color", color)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; nm.tooltip_text = panel.tooltip_text; vb.add_child(nm)

	var use_btn = Button.new(); use_btn.custom_minimum_size = Vector2(0, 18); use_btn.text = "使用"
	use_btn.tooltip_text = panel.tooltip_text
	use_btn.add_theme_font_size_override("font_size", 10)
	var bs = StyleBoxFlat.new()
	bs.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.24); bs.border_color = color; bs.set_border_width_all(2); bs.set_corner_radius_all(5)
	var bh = bs.duplicate(); bh.bg_color = GameTheme.COLOR_BG_PANEL.lerp(color, 0.42)
	use_btn.add_theme_stylebox_override("normal", bs); use_btn.add_theme_stylebox_override("hover", bh)
	use_btn.add_theme_color_override("font_color", color)
	use_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	vb.add_child(use_btn)

	var cap_id = id; var cap_cons = cons; var cap_panel = panel
	use_btn.pressed.connect(func(): _on_consumable_used(cap_id, cap_cons, cap_panel))
	return panel

func _on_consumable_used(item_id: String, cons, panel: Control):
	if _used_consumable_ids.has(item_id): return
	_used_consumable_ids.append(item_id)
	_used_consumable_items.append(cons)
	# Apply special effects immediately on use (e.g., ExtraPlayTicket adds plays)
	if cons.has_method("apply_special_effect"):
		cons.apply_special_effect()
	panel.queue_free()
	_update_params_panel()
	if _selected_indices.size() == 5:
		var sel_cards = []; for idx in _selected_indices: sel_cards.append(DeckManager.hand[idx])
		_update_params_panel(HandEvaluator.evaluate(sel_cards))

func _clear_used_consumables():
	_used_consumable_ids.clear()
	_used_consumable_items.clear()

# ════════════════════════════════════════════════════════════════
# 出牌 / 换牌
# ════════════════════════════════════════════════════════════════
func _on_play_pressed():
	if _selected_indices.size() != 5:
		_show_tip("请选择 5 张牌！", Color(0.95, 0.35, 0.35, 1)); return
	if RoundManager.plays_left <= 0: return

	play_button.disabled = true; discard_button.disabled = true
	var played_cards = []
	for idx in _selected_indices:
		played_cards.append(DeckManager.hand[idx])

	var result = await RoundManager.play_hand(
		_selected_indices.duplicate(), _used_consumable_ids.duplicate()
	)

	# ── 先播完计算过程动画，再推进阶段 ──
	await _show_calc_animation(result, played_cards)

	_clear_used_consumables()
	# v3.1: 出牌后重新执行敌方技能（重新随机锁定/遮挡）
	BossSkillManager.execute_skill_on_hand(DeckManager.hand)
	_rebuild_hand(); _rebuild_consumables(); _update_ui(); _reset_inline_calc()
	play_button.disabled    = RoundManager.plays_left <= 0
	discard_button.disabled = RoundManager.discards_left <= 0

	# 动画结束后由此处推进阶段（blind_cleared / out_of_plays）
	RoundManager.advance_after_play(result)

func _on_discard_pressed():
	if _selected_indices.is_empty():
		_show_tip("请选择要换掉的牌！", Color(0.95, 0.60, 0.15, 1)); return
	if RoundManager.discards_left <= 0: return
	RoundManager.discard_cards(_selected_indices.duplicate())
	# v3.1: 换牌后重新执行敌方技能（重新随机锁定/遮挡）
	BossSkillManager.execute_skill_on_hand(DeckManager.hand)
	_rebuild_hand(); _update_ui(); GameState.save_state()

# ════════════════════════════════════════════════════════════════
# 计算过程动画
# ════════════════════════════════════════════════════════════════
func _show_calc_animation(result: Dictionary, played_cards: Array = []):
	# 直接在牌桌中间展示计算过程，不再打开独立弹窗。
	for child in calc_steps_list.get_children(): child.queue_free()
	for child in played_area.get_children(): child.queue_free()
	for card in played_cards:
		played_area.add_child(_make_table_card(card))
	calc_title.text = ""
	formula_label.text = ""
	final_score_label.text = ""
	score_burst_label.text = ""
	crit_banner.visible    = false
	calc_close_hint.visible = false

	var steps    = result.get("steps", [])
	var base_s   = result.get("snapshot", {}).get("chips", 0)
	var is_crit  = result.get("is_crit", false)
	var cm       = result.get("crit_mult", 2.0)
	var final_sc = result.get("score", 0)
	var joker_step_index = 0
	_base_score_preview = base_s
	_apply_params_to_labels(1.0, 0.0, 2.0)

	# 逐步展示
	for i in range(steps.size()):
		var step = steps[i]
		await get_tree().create_timer(0.28).timeout
		var step_type = step.get("type", "")
		if step_type == "consumable" or step_type == "remain_boost":
			_apply_params_to_labels(
				step.get("mult", 1.0),
				step.get("crit_rate", 0.0),
				step.get("crit_mult", 2.0)
			)
		elif step_type == "joker":
			await _bounce_joker_badge(joker_step_index)
			joker_step_index += 1
			_apply_params_to_labels(
				step.get("mult", 1.0),
				step.get("crit_rate", 0.0),
				step.get("crit_mult", 2.0)
			)

	# 显示公式结果
	await get_tree().create_timer(0.3).timeout
	var mult = result.get("mult", 1.0)
	var pre_crit = int(float(base_s) * mult)
	score_burst_label.text = "+%d" % final_sc
	score_burst_label.modulate.a = 1.0
	score_burst_label.scale = Vector2.ONE
	if is_crit:
		await get_tree().create_timer(0.4).timeout
		# 暴击膨胀
		crit_banner.text    = "💥 CRIT!  ×%.1f 暴击膨胀！" % cm
		crit_banner.visible = true
		var tween = create_tween()
		tween.tween_property(crit_banner, "scale", Vector2(1.35, 1.35), 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(crit_banner, "scale", Vector2(1.0,  1.0),  0.14).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.38).timeout
	else:
		await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(0.45).timeout
	calc_close_hint.visible = false
	await _fade_score_burst()

func _bounce_joker_badge(index: int):
	if index < 0 or index >= _joker_badge_nodes.size():
		return
	var node = _joker_badge_nodes[index]
	if not is_instance_valid(node):
		return
	var original_pos = node.position
	var original_scale = node.scale
	var tw = create_tween()
	tw.tween_property(node, "position:y", original_pos.y - 14, 0.10).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "scale", original_scale * 1.12, 0.10).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position:y", original_pos.y, 0.12).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node, "scale", original_scale, 0.12).set_ease(Tween.EASE_IN)
	await tw.finished

func _reset_inline_calc():
	for child in calc_steps_list.get_children():
		child.queue_free()
	for child in played_area.get_children():
		child.queue_free()
	calc_title.text = ""
	formula_label.text = ""
	final_score_label.text = ""
	score_burst_label.text = ""
	score_burst_label.modulate.a = 1.0
	score_burst_label.scale = Vector2.ONE
	crit_banner.visible = false
	crit_banner.modulate.a = 1.0
	calc_close_hint.visible = false

func _fade_score_burst():
	if score_burst_label.text == "":
		return
	var tw = create_tween()
	tw.tween_property(score_burst_label, "scale", Vector2(1.12, 1.12), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(score_burst_label, "modulate:a", 0.0, 0.28).set_ease(Tween.EASE_IN)
	if crit_banner.visible:
		tw.parallel().tween_property(crit_banner, "modulate:a", 0.0, 0.20)
	await tw.finished
	score_burst_label.text = ""
	score_burst_label.modulate.a = 1.0
	score_burst_label.scale = Vector2.ONE
	crit_banner.visible = false
	crit_banner.modulate.a = 1.0

func _add_calc_step_row(step: Dictionary, base_chips: int):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	calc_steps_list.add_child(row)

	var type = step.get("type", "")
	var icon_lbl = Label.new(); icon_lbl.add_theme_font_size_override("font_size", 13)
	var name_lbl = Label.new(); name_lbl.add_theme_font_size_override("font_size", 12); name_lbl.size_flags_horizontal = 3
	var delta_lbl = Label.new(); delta_lbl.add_theme_font_size_override("font_size", 12)
	var result_lbl = Label.new(); result_lbl.add_theme_font_size_override("font_size", 12)

	match type:
		"base":
			icon_lbl.text  = "🃏"
			name_lbl.text  = step.get("label", "牌型")
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
			delta_lbl.text = "伤害 %d" % base_chips
			delta_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1))
			result_lbl.text = "×1.00"
			result_lbl.add_theme_color_override("font_color", GameTheme.COLOR_BLUE_CHIP)
		"joker":
			icon_lbl.text = "🎭"
			var lv = step.get("level", 1)
			name_lbl.text = "%s (Lv%d)" % [step.get("label", "法宝"), lv]
			name_lbl.add_theme_color_override("font_color", GameTheme.COLOR_JOKER)
			var d = step.get("delta", {})
			var parts = []
			if d.get("mult_add",0.0) != 0.0:      parts.append("倍率+%.2f" % d.get("mult_add",0.0))
			if d.get("chip_add",0.0) != 0.0:      parts.append("伤害+%.0f" % d.get("chip_add",0.0))
			if d.get("crit_rate_add",0.0) != 0.0: parts.append("暴击率+%d%%" % int(d.get("crit_rate_add",0.0)*100))
			if d.get("crit_mult_add",0.0) != 0.0: parts.append("暴击倍×+%.1f" % d.get("crit_mult_add",0.0))
			delta_lbl.text = "  ".join(parts) if parts else "无效果"
			delta_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55, 1))
			result_lbl.text = "→ ×%.2f" % step.get("mult", 1.0)
			result_lbl.add_theme_color_override("font_color", Color(0.90, 1.00, 0.40, 1))
		"consumable":
			row.queue_free()
			return
		"remain_boost":
			row.queue_free()
			return

	row.add_child(icon_lbl)
	row.add_child(name_lbl)
	row.add_child(delta_lbl)
	row.add_child(result_lbl)

	# 入场小动画
	row.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(row, "modulate:a", 1.0, 0.20)

# ════════════════════════════════════════════════════════════════
# 提示 / 复活
# ════════════════════════════════════════════════════════════════
func _show_tip(msg: String, color: Color):
	score_popup.text = msg
	score_popup.add_theme_color_override("font_color", color)
	score_popup.add_theme_font_size_override("font_size", 18)
	score_popup.modulate.a = 1.0; score_popup.visible = true
	await get_tree().create_timer(1.2).timeout
	score_popup.visible = false

func _on_round_failed(_round_idx: int, _blind_idx: int):
	if RoundManager.can_revive():
		revive_dialog.dialog_text = "出牌次数耗尽，未达到门槛分！\n已使用复活 %d / %d 次\n\n选择复活方式继续：" % [
			RoundManager.revive_count, RoundManager.max_revives]
		revive_dialog.popup_centered()
	else:
		GameAPI.submit_result()
		RoundManager.phase_changed.emit(RoundManager.Phase.FINAL_RESULT)

func _on_revive_ad():
	# Call backend to prepare revive (get ad token)
	GameAPI.revive_prepare()

# Backend returned ad_callback_token
func _on_revive_prepared(data: Dictionary):
	var ad_token = data.get("ad_callback_token", "")
	if ad_token == "":
		push_warning("revive_prepare returned no ad_token")
		return
	# Simulate ad watching locally, then confirm revive with backend
	if OS.has_feature("web"):
		# On web: JSBridge handles ad display, then dispatch("ad_complete", ...)
		JSBridge.request_revive_ad()
		# The JSBridge will emit revive_ad_completed when ad finishes
		# We use a one-shot connection to proceed
		JSBridge.revive_ad_completed.connect(func():
			GameAPI.revive(ad_token)
		, CONNECT_ONE_SHOT)
	else:
		# Local: simulate ad watch delay, then confirm revive
		get_tree().create_timer(0.5).timeout.connect(func():
			GameAPI.revive(ad_token)
		)

# Backend confirmed revive
func _on_revive_completed(data: Dictionary):
	var count = int(data.get("revive_count", 0))
	RoundManager.revive_count = count
	RoundManager._reset_blind()
	RoundManager._set_phase(RoundManager.Phase.PLAYING)
	_refresh_all()
	GameState.save_state()

func _on_give_up():
	GameAPI.submit_result()
	RoundManager.phase_changed.emit(RoundManager.Phase.FINAL_RESULT)

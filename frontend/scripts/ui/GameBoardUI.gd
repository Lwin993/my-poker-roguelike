# GameBoardUI.gd - 主战斗界面交互逻辑
extends Control

# ── 顶部信息 ──
@onready var round_label       = $MainVBox/TopBar/RoundBadge/RoundLabel
@onready var coins_label       = $MainVBox/TopBar/CoinsBadge/CoinsLabel
# ── 分数 ──
@onready var score_label       = $MainVBox/ScoreContainer/ScoreVBox/ScoreRow/ScoreLabel
@onready var threshold_label   = $MainVBox/ScoreContainer/ScoreVBox/ScoreRow/ThresholdLabel
@onready var progress_bar      = $MainVBox/ScoreContainer/ScoreVBox/ProgressBar
# ── 信息行 ──
@onready var hand_name_label   = $MainVBox/InfoRow/HandNameLabel
@onready var plays_label       = $MainVBox/InfoRow/PlaysLabel
@onready var discards_label    = $MainVBox/InfoRow/DiscardsLabel
@onready var total_score_label = $MainVBox/TotalScoreLabel
# ── 参数面板 ──
@onready var mult_label        = $MainVBox/ParamsPanel/ParamsRow/MultLabel
@onready var crit_rate_label   = $MainVBox/ParamsPanel/ParamsRow/CritRateLabel
@onready var crit_mult_label   = $MainVBox/ParamsPanel/ParamsRow/CritMultLabel
# ── 道具区 ──
@onready var joker_slots       = $MainVBox/JokerSection/JokerSlots
@onready var cons_slots        = $MainVBox/ConsSection/ConsSlots
# ── 手牌 / 按钮 ──
@onready var hand_area         = $MainVBox/HandArea
@onready var play_button       = $MainVBox/ButtonRow/PlayButton
@onready var discard_button    = $MainVBox/ButtonRow/DiscardButton
@onready var sort_by_rank_btn  = $MainVBox/SortRow/SortByRankButton
@onready var sort_by_suit_btn  = $MainVBox/SortRow/SortBySuitButton
# ── 弹出层 ──
@onready var score_popup       = $ScorePopup
@onready var revive_dialog     = $ReviveDialog
# ── 计算过程浮层 ──
@onready var calc_overlay      = $CalcOverlay
@onready var calc_steps_list   = $CalcOverlay/CalcPanel/CalcVBox/CalcStepsList
@onready var final_score_label = $CalcOverlay/CalcPanel/CalcVBox/FinalScoreLabel
@onready var crit_banner       = $CalcOverlay/CalcPanel/CalcVBox/CritBanner
@onready var calc_close_hint   = $CalcOverlay/CalcPanel/CalcVBox/CalcCloseHint
@onready var calc_bg           = $CalcOverlay/CalcBG
# ── 小丑牌详情浮层 ──
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
var _calc_waiting:          bool  = false   # 计算动画进行中，等待点击

const SUIT_SYMBOLS = ["♠", "♥", "♦", "♣"]
const SUIT_COLORS  = {
	0: Color(0.45, 0.75, 1.00, 1),
	1: Color(0.95, 0.30, 0.30, 1),
	2: Color(1.00, 0.55, 0.20, 1),
	3: Color(0.35, 0.85, 0.45, 1),
}

# ════════════════════════════════════════════════════════════════
func _ready():
	RoundManager.score_updated.connect(_on_score_updated)
	RoundManager.round_failed.connect(_on_round_failed)
	RoundManager.phase_changed.connect(_on_phase_changed)

	_style_main_button(play_button,    Color(0.20, 0.80, 0.60, 1))
	_style_main_button(discard_button, Color(0.95, 0.55, 0.10, 1))

	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	revive_dialog.confirmed.connect(_on_revive_ad)
	revive_dialog.canceled.connect(_on_give_up)

	# 排序按钮
	_style_sort_button(sort_by_rank_btn, Color(0.45, 0.75, 1.00, 1))
	_style_sort_button(sort_by_suit_btn, Color(0.55, 0.85, 0.55, 1))
	sort_by_rank_btn.pressed.connect(_on_sort_by_rank)
	sort_by_suit_btn.pressed.connect(_on_sort_by_suit)

	# 点击计算浮层背景 → 关闭
	calc_bg.gui_input.connect(_on_calc_bg_input)
	# 小丑牌详情关闭按钮
	joker_detail_close.pressed.connect(func(): joker_detail_overlay.visible = false)
	joker_detail_bg.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			joker_detail_overlay.visible = false
	)

	_style_button(joker_detail_close, Color(0.55, 0.65, 0.75, 1))
	_update_ui()

func _style_main_button(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.22; s.border_color = color
	s.set_border_width_all(2); s.set_corner_radius_all(10)
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top  = 8;  s.content_margin_bottom = 8
	var h = s.duplicate(); h.bg_color = color * 0.38; h.border_color = color * 1.15
	var p = s.duplicate(); p.bg_color = color * 0.55
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color",       color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _style_button(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.20; s.border_color = color
	s.set_border_width_all(1); s.set_corner_radius_all(8)
	var h = s.duplicate(); h.bg_color = color * 0.36
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)
	btn.add_theme_color_override("font_color", color)

func _style_sort_button(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.12; s.border_color = color * 0.55
	s.set_border_width_all(1); s.set_corner_radius_all(6)
	s.content_margin_left = 6; s.content_margin_right = 6
	s.content_margin_top  = 2; s.content_margin_bottom = 2
	var h = s.duplicate(); h.bg_color = color * 0.28; h.border_color = color
	var p = s.duplicate(); p.bg_color = color * 0.42
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color",       color)
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
	round_label.text  = "第 %d 轮 · %s" % [RoundManager.current_round + 1, RoundManager.get_current_blind_name()]
	coins_label.text  = "💰 %d" % RoundManager.game_coins
	total_score_label.text = "累计总分: %d" % RoundManager.total_score

	var plays    = RoundManager.plays_left
	var discards = RoundManager.discards_left
	plays_label.text    = "出牌 × %d" % plays
	discards_label.text = "换牌 × %d" % discards
	plays_label.add_theme_color_override("font_color",
		Color(0.45, 0.85, 1.0, 1) if plays > 0 else Color(0.5, 0.3, 0.3, 1))
	discards_label.add_theme_color_override("font_color",
		Color(0.95, 0.65, 0.25, 1) if discards > 0 else Color(0.5, 0.3, 0.3, 1))

	var threshold = RoundManager.get_current_threshold()
	score_label.text     = "本回合: %d" % RoundManager.round_score
	threshold_label.text = "/ %d" % threshold
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
	var params = ScoreCalculator.preview_params(
		hand_result,
		ItemManager.get_active_joker_states(),
		_used_consumable_items,
		DeckManager.hand
	)
	_apply_params_to_labels(
		params.get("mult",      1.0),
		params.get("crit_rate", 0.0),
		params.get("crit_mult", 2.0)
	)

func _apply_params_to_labels(mult: float, cr: float, cm: float):
	mult_label.text      = "倍率 ×%.2f" % mult
	crit_rate_label.text = "暴击率 %d%%" % int(cr * 100)
	crit_mult_label.text = "暴击倍数 ×%.1f" % cm

	mult_label.add_theme_color_override("font_color",
		Color(0.90, 1.00, 0.40, 1) if mult > 1.01 else Color(0.45, 0.85, 1.0, 1))
	crit_rate_label.add_theme_color_override("font_color",
		Color(1.0, 0.75, 0.10, 1) if cr > 0.001 else Color(0.55, 0.55, 0.60, 1))
	crit_mult_label.add_theme_color_override("font_color",
		Color(1.0, 0.40, 0.10, 1) if cm > 2.01 else Color(0.65, 0.55, 0.50, 1))

# ════════════════════════════════════════════════════════════════
# 手牌
# ════════════════════════════════════════════════════════════════
func _rebuild_hand():
	for node in _card_nodes: node.queue_free()
	_card_nodes.clear()
	_selected_indices.clear()
	for i in range(DeckManager.hand.size()):
		var btn = _make_card_button(DeckManager.hand[i], i)
		hand_area.add_child(btn)
		_card_nodes.append(btn)
	_update_hand_name_label()
	_update_params_panel()

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

func _make_card_button(card, idx: int) -> Button:
	var sc  = SUIT_COLORS[card.suit]
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(50, 78)
	btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", sc)
	_apply_card_style(btn, sc, false)
	var i = idx
	btn.pressed.connect(func(): _on_card_pressed(i))
	return btn

func _apply_card_style(btn: Button, sc: Color, selected: bool):
	var normal = StyleBoxFlat.new()
	var hover  = StyleBoxFlat.new()
	if selected:
		normal.bg_color     = sc * 0.28; normal.border_color = Color(1.0, 0.85, 0.15, 1)
		normal.set_border_width_all(2);  normal.shadow_color  = Color(1.0, 0.85, 0.15, 0.35); normal.shadow_size = 5
		hover.bg_color      = sc * 0.38; hover.border_color   = Color(1.0, 0.95, 0.50, 1)
		hover.set_border_width_all(2);   hover.shadow_color   = Color(1.0, 0.85, 0.15, 0.5);  hover.shadow_size  = 6
	else:
		normal.bg_color = Color(0.10, 0.15, 0.22, 1); normal.border_color = sc * 0.6; normal.set_border_width_all(1)
		hover.bg_color  = Color(0.14, 0.20, 0.30, 1); hover.border_color  = sc;       hover.set_border_width_all(1)
	normal.set_corner_radius_all(8); hover.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", normal)

func _on_card_pressed(idx: int):
	if _selected_indices.has(idx): _selected_indices.erase(idx)
	elif _selected_indices.size() < 5: _selected_indices.append(idx)
	_update_card_visuals()
	_update_hand_name_label()

func _update_card_visuals():
	for i in range(_card_nodes.size()):
		var btn = _card_nodes[i]; var sc = SUIT_COLORS[DeckManager.hand[i].suit]
		var sel = _selected_indices.has(i)
		_apply_card_style(btn, sc, sel)
		btn.add_theme_color_override("font_color", Color.WHITE if sel else sc)

func _update_hand_name_label():
	if _selected_indices.size() == 5:
		var sel_cards = []; for idx in _selected_indices: sel_cards.append(DeckManager.hand[idx])
		var result = HandEvaluator.evaluate(sel_cards)
		hand_name_label.text = "✨ %s   基础分 %d" % [result.hand_name, result.base_score]
		hand_name_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
		_update_params_panel(result)
	elif _selected_indices.size() > 0:
		hand_name_label.text = "已选 %d 张（还需 %d 张）" % [_selected_indices.size(), 5 - _selected_indices.size()]
		hand_name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.5, 1))
		_update_params_panel()
	else:
		hand_name_label.text = "← 点击手牌选择，选满5张出牌"
		hand_name_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 1))
		_update_params_panel()

# ════════════════════════════════════════════════════════════════
# 小丑牌
# ════════════════════════════════════════════════════════════════
func _rebuild_jokers():
	for child in joker_slots.get_children(): child.queue_free()
	if ItemManager.jokers.is_empty():
		var lbl = Label.new(); lbl.text = "暂无小丑牌"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5, 1))
		joker_slots.add_child(lbl); return
	for joker in ItemManager.jokers:
		joker_slots.add_child(_make_joker_badge(joker))

func _make_joker_badge(joker) -> Control:
	var color = Color(0.75, 0.45, 1.0, 1)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(68, 52)
	btn.tooltip_text = joker.resource_data.get("description", "")

	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.12; s.border_color = color * 0.55
	s.set_border_width_all(1); s.set_corner_radius_all(7)
	s.content_margin_left = 4; s.content_margin_right = 4
	s.content_margin_top = 4; s.content_margin_bottom = 4
	var h = s.duplicate(); h.bg_color = color * 0.26; h.border_color = color
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)

	# 内部用 RichTextLabel 排版
	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 1)
	btn.add_child(vb)

	var row = HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2); vb.add_child(row)

	var icon = Label.new(); icon.text = "🎭"; icon.add_theme_font_size_override("font_size", 14)
	row.add_child(icon)
	var lv = Label.new(); lv.text = "Lv%d" % joker.level
	lv.add_theme_font_size_override("font_size", 11)
	lv.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
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

# ── 小丑牌详情弹窗 ──────────────────────────────────────────
func _show_joker_detail(joker):
	var color    = Color(0.75, 0.45, 1.0, 1)
	var name_str = joker.resource_data.get("display_name", "?")
	var desc_str = joker.resource_data.get("description", "")

	joker_detail_title.text = "🎭  %s" % name_str
	joker_detail_level.text = "等级：Lv%d / 3" % joker.level
	joker_detail_desc.text  = desc_str

	# 清空旧参数
	for child in joker_detail_params.get_children(): child.queue_free()

	# 获取当前等级下的参数贡献
	var delta = joker.get_passive_modifiers({})
	var dm    = delta.get("mult_add",      0.0)
	var dcr   = delta.get("crit_rate_add", 0.0)
	var dcm   = delta.get("crit_mult_add", 0.0)
	var dsm   = delta.get("special_mult",  1.0)

	_add_param_row("倍率加成",      "+%.2f" % dm,            Color(0.45, 0.85, 1.0, 1), dm != 0.0)
	_add_param_row("暴击率加成",    "+%d%%" % int(dcr*100),  Color(1.0, 0.72, 0.10, 1), dcr != 0.0)
	_add_param_row("暴击倍数加成",  "+%.1f" % dcm,           Color(1.0, 0.40, 0.10, 1), dcm != 0.0)
	if dsm != 1.0:
		_add_param_row("特殊倍率", "×%.2f" % dsm, Color(0.90, 0.45, 1.0, 1), true)

	# 升级后预览（若未满级）
	var cost = joker.get_upgrade_cost()
	if cost != -1 and joker.level < 3:
		var sep = HSeparator.new(); joker_detail_params.add_child(sep)
		var hint = Label.new()
		hint.text = "升级 Lv%d → Lv%d 需要 💰%d（在商店升级）" % [joker.level, joker.level + 1, cost]
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75, 1))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		joker_detail_params.add_child(hint)

	joker_detail_overlay.visible = true

func _add_param_row(param_name: String, value_str: String, color: Color, active: bool):
	var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 6)
	joker_detail_params.add_child(row)

	var nm = Label.new(); nm.text = param_name; nm.custom_minimum_size = Vector2(110, 0)
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1))
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
	var color   = Color(1.0, 0.72, 0.10, 1) if rarity == 1 else Color(0.30, 0.85, 0.70, 1)

	var panel = PanelContainer.new(); panel.custom_minimum_size = Vector2(70, 0)
	var ps = StyleBoxFlat.new()
	ps.bg_color = color * 0.11; ps.border_color = color * 0.50
	ps.set_border_width_all(1); ps.set_corner_radius_all(7)
	ps.content_margin_left = 4; ps.content_margin_right = 4
	ps.content_margin_top  = 4; ps.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", ps)

	var vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 2); panel.add_child(vb)

	var icon = Label.new(); icon.text = "✨" if rarity == 1 else "🧪"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; icon.add_theme_font_size_override("font_size", 14)
	vb.add_child(icon)

	var nm = Label.new(); nm.text = name_s
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; nm.add_theme_font_size_override("font_size", 10)
	nm.add_theme_color_override("font_color", color)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; nm.tooltip_text = desc_s; vb.add_child(nm)

	var use_btn = Button.new(); use_btn.custom_minimum_size = Vector2(0, 22); use_btn.text = "使用"
	use_btn.add_theme_font_size_override("font_size", 11)
	var bs = StyleBoxFlat.new()
	bs.bg_color = color * 0.20; bs.border_color = color; bs.set_border_width_all(1); bs.set_corner_radius_all(5)
	var bh = bs.duplicate(); bh.bg_color = color * 0.40
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

	var result = await RoundManager.play_hand(
		_selected_indices.duplicate(), _used_consumable_ids.duplicate()
	)

	# ── 先播完计算过程动画，再推进阶段 ──
	await _show_calc_animation(result)

	_clear_used_consumables()
	_rebuild_hand(); _rebuild_consumables(); _update_ui()
	play_button.disabled    = RoundManager.plays_left <= 0
	discard_button.disabled = RoundManager.discards_left <= 0

	# 动画结束后由此处推进阶段（blind_cleared / out_of_plays）
	RoundManager.advance_after_play(result)

func _on_discard_pressed():
	if _selected_indices.is_empty():
		_show_tip("请选择要换掉的牌！", Color(0.95, 0.60, 0.15, 1)); return
	if RoundManager.discards_left <= 0: return
	RoundManager.discard_cards(_selected_indices.duplicate())
	_rebuild_hand(); _update_ui(); GameState.save_state()

# ════════════════════════════════════════════════════════════════
# 计算过程动画
# ════════════════════════════════════════════════════════════════
func _show_calc_animation(result: Dictionary):
	# 准备浮层
	for child in calc_steps_list.get_children(): child.queue_free()
	final_score_label.text = ""
	crit_banner.visible    = false
	calc_close_hint.visible = false
	calc_overlay.visible   = true
	_calc_waiting          = false

	var steps    = result.get("steps", [])
	var base_s   = result.get("snapshot", {}).get("base_score", 0)
	var is_crit  = result.get("is_crit", false)
	var cm       = result.get("crit_mult", 2.0)
	var final_sc = result.get("score", 0)

	# 逐步展示
	for i in range(steps.size()):
		var step = steps[i]
		await get_tree().create_timer(0.28).timeout
		_add_calc_step_row(step, base_s)

	# 显示公式结果
	await get_tree().create_timer(0.3).timeout
	var mult = result.get("mult", 1.0)
	var pre_crit = int(float(base_s) * mult)
	if is_crit:
		final_score_label.text = "%d × %.2f = %d" % [base_s, mult, pre_crit]
		final_score_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55, 1))
		await get_tree().create_timer(0.4).timeout
		# 暴击膨胀
		crit_banner.text    = "💥 CRIT!  ×%.1f 暴击膨胀！" % cm
		crit_banner.visible = true
		var tween = create_tween()
		tween.tween_property(crit_banner, "scale", Vector2(1.35, 1.35), 0.18).set_ease(Tween.EASE_OUT)
		tween.tween_property(crit_banner, "scale", Vector2(1.0,  1.0),  0.14).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(0.38).timeout
		final_score_label.text = "🏆  最终得分：%d" % final_sc
		final_score_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.10, 1))
		final_score_label.add_theme_font_size_override("font_size", 32)
	else:
		final_score_label.text = "%d × %.2f = %d" % [base_s, mult, final_sc]
		final_score_label.add_theme_font_size_override("font_size", 28)

	await get_tree().create_timer(0.5).timeout
	calc_close_hint.visible = true
	_calc_waiting           = true

	# 等待玩家点击关闭
	await _wait_for_calc_close()
	calc_overlay.visible  = false
	calc_close_hint.visible = false
	_calc_waiting         = false

func _add_calc_step_row(step: Dictionary, base_score: int):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	calc_steps_list.add_child(row)

	var type = step.get("type", "")
	var icon_lbl = Label.new(); icon_lbl.add_theme_font_size_override("font_size", 15)
	var name_lbl = Label.new(); name_lbl.add_theme_font_size_override("font_size", 13); name_lbl.size_flags_horizontal = 3
	var delta_lbl = Label.new(); delta_lbl.add_theme_font_size_override("font_size", 13)
	var result_lbl = Label.new(); result_lbl.add_theme_font_size_override("font_size", 13)

	match type:
		"base":
			icon_lbl.text  = "🃏"
			name_lbl.text  = step.get("label", "牌型")
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1))
			delta_lbl.text = "基础分 %d" % base_score
			delta_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 1))
			result_lbl.text = "×1.00"
			result_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0, 1))
		"joker":
			icon_lbl.text = "🎭"
			var lv = step.get("level", 1)
			name_lbl.text = "%s (Lv%d)" % [step.get("label", "小丑"), lv]
			name_lbl.add_theme_color_override("font_color", Color(0.75, 0.45, 1.0, 1))
			var d = step.get("delta", {})
			var parts = []
			if d.get("mult_add",0.0) != 0.0:      parts.append("倍率+%.2f" % d.get("mult_add",0.0))
			if d.get("crit_rate_add",0.0) != 0.0: parts.append("暴击率+%d%%" % int(d.get("crit_rate_add",0.0)*100))
			if d.get("crit_mult_add",0.0) != 0.0: parts.append("暴击倍×+%.1f" % d.get("crit_mult_add",0.0))
			delta_lbl.text = "  ".join(parts) if parts else "无效果"
			delta_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55, 1))
			result_lbl.text = "→ ×%.2f" % step.get("mult", 1.0)
			result_lbl.add_theme_color_override("font_color", Color(0.90, 1.00, 0.40, 1))
		"consumable":
			icon_lbl.text = "✨"
			name_lbl.text = step.get("label", "道具")
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.10, 1))
			var d = step.get("delta", {})
			var parts = []
			if d.get("mult_factor",1.0) != 1.0:   parts.append("倍率×%.1f" % d.get("mult_factor",1.0))
			if d.get("mult_add",0.0) != 0.0:       parts.append("倍率+%.2f" % d.get("mult_add",0.0))
			if d.get("crit_rate_add",0.0) != 0.0:  parts.append("暴击率+%d%%" % int(d.get("crit_rate_add",0.0)*100))
			if d.get("crit_mult_add",0.0) != 0.0:  parts.append("暴击倍+%.1f" % d.get("crit_mult_add",0.0))
			delta_lbl.text = "  ".join(parts) if parts else "无效果"
			delta_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55, 1))
			result_lbl.text = "→ ×%.2f" % step.get("mult", 1.0)
			result_lbl.add_theme_color_override("font_color", Color(0.90, 1.00, 0.40, 1))
		"remain_boost":
			icon_lbl.text = "🃏"
			name_lbl.text = step.get("label", "余牌加持")
			name_lbl.add_theme_color_override("font_color", Color(0.50, 1.00, 0.80, 1))
			delta_lbl.text = ""
			result_lbl.text = "→ ×%.2f" % step.get("mult", 1.0)
			result_lbl.add_theme_color_override("font_color", Color(0.90, 1.00, 0.40, 1))

	row.add_child(icon_lbl)
	row.add_child(name_lbl)
	row.add_child(delta_lbl)
	row.add_child(result_lbl)

	# 入场小动画
	row.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(row, "modulate:a", 1.0, 0.20)

var _calc_close_signal = false

func _wait_for_calc_close():
	await _calc_close_event

signal _calc_close_event()

func _on_calc_bg_input(event: InputEvent):
	if _calc_waiting and event is InputEventMouseButton and event.pressed:
		_calc_close_event.emit()

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
	RoundManager.revive(); _refresh_all(); GameState.save_state()

func _on_give_up():
	GameAPI.submit_result()
	RoundManager.phase_changed.emit(RoundManager.Phase.FINAL_RESULT)

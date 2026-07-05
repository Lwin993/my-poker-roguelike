# Theme.gd - 全局主题配置（通过代码创建并应用）
# 在 project.godot 中设置为 Autoload
extends Node

# 调色板
const COLOR_BG_DEEP     = Color(0.05, 0.08, 0.12, 1)      # 深蓝黑背景
const COLOR_BG_PANEL    = Color(0.10, 0.14, 0.20, 1)      # 面板背景
const COLOR_BG_CARD     = Color(0.12, 0.18, 0.26, 1)      # 卡牌背景
const COLOR_BORDER      = Color(0.25, 0.35, 0.50, 1)      # 边框
const COLOR_ACCENT      = Color(0.20, 0.80, 0.60, 1)      # 主色调（翠绿）
const COLOR_GOLD        = Color(1.00, 0.85, 0.20, 1)      # 金色
const COLOR_RED         = Color(0.95, 0.25, 0.25, 1)      # 红色（红心/方块）
const COLOR_TEXT_MAIN   = Color(0.92, 0.95, 1.00, 1)      # 主文字
const COLOR_TEXT_DIM    = Color(0.55, 0.65, 0.75, 1)      # 次要文字
const COLOR_CRIT        = Color(1.00, 0.45, 0.10, 1)      # 暴击橙
const COLOR_RARE        = Color(1.00, 0.72, 0.10, 1)      # 稀有金

# 套花色配色
const SUIT_COLORS = {
	0: Color(0.45, 0.75, 1.00, 1),   # ♠ 黑桃 - 蓝
	1: Color(0.95, 0.30, 0.30, 1),   # ♥ 红心 - 红
	2: Color(1.00, 0.55, 0.20, 1),   # ♦ 方块 - 橙
	3: Color(0.35, 0.85, 0.45, 1),   # ♣ 梅花 - 绿
}

var _theme: Theme

func _ready():
	_theme = _build_theme()
	get_tree().root.theme = _theme

func get_panel_style(bg: Color = COLOR_BG_PANEL, border: Color = COLOR_BORDER, radius: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left   = 8
	s.content_margin_right  = 8
	s.content_margin_top    = 6
	s.content_margin_bottom = 6
	return s

func get_card_style(suit_color: Color, selected: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	if selected:
		s.bg_color = suit_color * 0.35
		s.border_color = COLOR_GOLD
		s.set_border_width_all(2)
		s.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.4)
		s.shadow_size = 4
	else:
		s.bg_color = COLOR_BG_CARD
		s.border_color = suit_color * 0.7
		s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	return s

func get_button_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.25
	s.border_color = color
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left   = 12
	s.content_margin_right  = 12
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s

func get_button_hover_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = get_button_style(color)
	s.bg_color = color * 0.40
	return s

func get_button_pressed_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = get_button_style(color)
	s.bg_color = color * 0.55
	s.border_color = color * 1.2
	return s

func _build_theme() -> Theme:
	var t = Theme.new()

	# --- Button ---
	var btn_normal  = get_button_style(COLOR_ACCENT)
	var btn_hover   = get_button_hover_style(COLOR_ACCENT)
	var btn_pressed = get_button_pressed_style(COLOR_ACCENT)
	var btn_disabled = get_button_style(Color(0.3, 0.3, 0.3, 1))
	btn_disabled.bg_color = Color(0.15, 0.15, 0.15, 1)

	t.set_stylebox("normal",   "Button", btn_normal)
	t.set_stylebox("hover",    "Button", btn_hover)
	t.set_stylebox("pressed",  "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_color("font_color",          "Button", COLOR_TEXT_MAIN)
	t.set_color("font_hover_color",    "Button", COLOR_ACCENT)
	t.set_color("font_pressed_color",  "Button", COLOR_GOLD)
	t.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
	t.set_font_size("font_size", "Button", 15)

	# --- Label ---
	t.set_color("font_color", "Label", COLOR_TEXT_MAIN)
	t.set_font_size("font_size", "Label", 14)

	# --- ProgressBar ---
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.12, 0.18, 0.24, 1)
	pb_bg.set_border_width_all(1)
	pb_bg.border_color = COLOR_BORDER
	pb_bg.set_corner_radius_all(4)
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_ACCENT
	pb_fill.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill",       "ProgressBar", pb_fill)

	# --- Panel ---
	var panel_style = get_panel_style()
	t.set_stylebox("panel", "Panel", panel_style)

	# --- PanelContainer ---
	t.set_stylebox("panel", "PanelContainer", panel_style)

	return t

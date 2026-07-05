# Theme.gd - 全局主题配置（通过代码创建并应用）
# 在 project.godot 中设置为 Autoload
extends Node

# 复古牌桌调色板：暖红背景、奶油牌面、金色描边和高饱和功能色
const COLOR_BG_DEEP     = Color(0.18, 0.035, 0.055, 1)
const COLOR_BG_PANEL    = Color(0.12, 0.08, 0.14, 1)
const COLOR_BG_CARD     = Color(0.98, 0.91, 0.72, 1)
const COLOR_BORDER      = Color(0.72, 0.47, 0.20, 1)
const COLOR_ACCENT      = Color(0.00, 0.86, 0.72, 1)
const COLOR_GOLD        = Color(1.00, 0.78, 0.18, 1)
const COLOR_RED         = Color(0.92, 0.12, 0.15, 1)
const COLOR_TEXT_MAIN   = Color(1.00, 0.94, 0.76, 1)
const COLOR_TEXT_DIM    = Color(0.72, 0.64, 0.58, 1)
const COLOR_CRIT        = Color(1.00, 0.32, 0.08, 1)
const COLOR_RARE        = Color(1.00, 0.70, 0.05, 1)
const COLOR_JOKER       = Color(0.73, 0.31, 1.00, 1)
const COLOR_BLUE_CHIP   = Color(0.23, 0.58, 1.00, 1)
const COLOR_CARD_INK    = Color(0.16, 0.10, 0.12, 1)

# 套花色配色
const SUIT_COLORS = {
	0: Color(0.11, 0.12, 0.20, 1),   # ♠ 黑桃
	1: Color(0.92, 0.12, 0.15, 1),   # ♥ 红心
	2: Color(0.96, 0.38, 0.08, 1),   # ♦ 方块
	3: Color(0.04, 0.46, 0.27, 1),   # ♣ 梅花
}

var _theme: Theme

func _ready():
	_theme = _build_theme()
	get_tree().root.theme = _theme

func get_panel_style(bg: Color = COLOR_BG_PANEL, border: Color = COLOR_BORDER, radius: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0.03, 0.01, 0.02, 0.55)
	s.shadow_size = 5
	s.content_margin_left   = 6
	s.content_margin_right  = 6
	s.content_margin_top    = 5
	s.content_margin_bottom = 5
	return s

func get_card_style(suit_color: Color, selected: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	if selected:
		s.bg_color = Color(1.00, 0.80, 0.28, 1)
		s.border_color = COLOR_GOLD
		s.set_border_width_all(3)
		s.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.42)
		s.shadow_size = 8
	else:
		s.bg_color = COLOR_BG_CARD
		s.border_color = suit_color.darkened(0.2)
		s.set_border_width_all(2)
		s.shadow_color = Color(0.03, 0.01, 0.02, 0.36)
		s.shadow_size = 4
	s.set_corner_radius_all(6)
	return s

func get_button_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.10, 0.06, 0.12, 1).lerp(color, 0.22)
	s.border_color = color
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.shadow_color = Color(0.03, 0.01, 0.02, 0.5)
	s.shadow_size = 4
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 6
	s.content_margin_bottom = 6
	return s

func get_button_hover_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = get_button_style(color)
	s.bg_color = Color(0.10, 0.06, 0.12, 1).lerp(color, 0.38)
	return s

func get_button_pressed_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = get_button_style(color)
	s.bg_color = Color(0.10, 0.06, 0.12, 1).lerp(color, 0.55)
	s.border_color = color.lightened(0.18)
	return s

func _build_theme() -> Theme:
	var t = Theme.new()

	# --- Button ---
	var btn_normal  = get_button_style(COLOR_ACCENT)
	var btn_hover   = get_button_hover_style(COLOR_ACCENT)
	var btn_pressed = get_button_pressed_style(COLOR_ACCENT)
	var btn_disabled = get_button_style(Color(0.3, 0.3, 0.3, 1))
	btn_disabled.bg_color = Color(0.13, 0.10, 0.12, 1)

	t.set_stylebox("normal",   "Button", btn_normal)
	t.set_stylebox("hover",    "Button", btn_hover)
	t.set_stylebox("pressed",  "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_color("font_color",          "Button", COLOR_TEXT_MAIN)
	t.set_color("font_hover_color",    "Button", Color.WHITE)
	t.set_color("font_pressed_color",  "Button", COLOR_GOLD)
	t.set_color("font_disabled_color", "Button", COLOR_TEXT_DIM)
	t.set_font_size("font_size", "Button", 16)

	# --- Label ---
	t.set_color("font_color", "Label", COLOR_TEXT_MAIN)
	t.set_font_size("font_size", "Label", 14)

	# --- ProgressBar ---
	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.07, 0.04, 0.08, 1)
	pb_bg.set_border_width_all(2)
	pb_bg.border_color = COLOR_BORDER
	pb_bg.set_corner_radius_all(4)
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_GOLD
	pb_fill.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill",       "ProgressBar", pb_fill)

	# --- Panel ---
	var panel_style = get_panel_style()
	t.set_stylebox("panel", "Panel", panel_style)

	# --- PanelContainer ---
	t.set_stylebox("panel", "PanelContainer", panel_style)

	return t

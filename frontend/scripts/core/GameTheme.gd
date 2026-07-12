# Theme.gd - 全局主题配置（通过代码创建并应用）
# 在 project.godot 中设置为 Autoload
extends Node

# 扑克 roguelike 调色板：暗青牌桌 + 酒红按钮 + 奶油纸牌 + 黄铜高光。
const COLOR_BG_DEEP     = Color("06191b")
const COLOR_BG_PANEL    = Color("102c30")
const COLOR_BG_CARD     = Color("f6edcf")
const COLOR_BORDER      = Color("286064")
const COLOR_ACCENT      = Color("35c6aa")
const COLOR_GOLD        = Color("f3c45b")
const COLOR_RED         = Color("e4473d")
const COLOR_TEXT_MAIN   = Color("fff3d3")
const COLOR_TEXT_DIM    = Color("9db7b2")
const COLOR_CRIT        = Color("f2573f")
const COLOR_RARE        = Color("ffcc33")
const COLOR_JOKER       = Color("b48ae8")
const COLOR_BLUE_CHIP   = Color("4a9ee8")
const COLOR_CARD_INK    = Color("211a1a")
const COLOR_HOT_PINK    = Color("dc557f")

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
	s.bg_color = Color(bg.r, bg.g, bg.b, 0.94)
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(border.r, border.g, border.b, 0.32)
	s.shadow_size = 5
	s.content_margin_left   = 9
	s.content_margin_right  = 9
	s.content_margin_top    = 7
	s.content_margin_bottom = 7
	return s

func get_card_style(suit_color: Color, selected: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	if selected:
		s.bg_color = Color("ffd968")
		s.border_color = COLOR_GOLD
		s.set_border_width_all(4)
		s.shadow_color = Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.72)
		s.shadow_size = 9
	else:
		s.bg_color = COLOR_BG_CARD
		s.border_color = suit_color.darkened(0.2)
		s.set_border_width_all(2)
		s.shadow_color = Color(0.03, 0.01, 0.02, 0.36)
		s.shadow_size = 4
	s.set_corner_radius_all(7)
	return s

func get_button_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color("122b2e").lerp(color, 0.38)
	s.border_color = color
	s.set_border_width_all(3)
	s.set_corner_radius_all(8)
	s.shadow_color = Color(color.r, color.g, color.b, 0.48)
	s.shadow_size = 6
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s

func get_button_hover_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = get_button_style(color)
	s.bg_color = Color("163638").lerp(color, 0.58)
	s.shadow_size = 9
	return s

func get_button_pressed_style(color: Color = COLOR_ACCENT) -> StyleBoxFlat:
	var s = get_button_style(color)
	s.bg_color = Color("071d20").lerp(color, 0.70)
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
	pb_bg.bg_color = Color("061416")
	pb_bg.set_border_width_all(3)
	pb_bg.border_color = Color("31595a")
	pb_bg.set_corner_radius_all(8)
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_CRIT
	pb_fill.border_color = COLOR_GOLD
	pb_fill.set_border_width_all(2)
	pb_fill.set_corner_radius_all(8)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill",       "ProgressBar", pb_fill)

	# --- Panel ---
	var panel_style = get_panel_style()
	t.set_stylebox("panel", "Panel", panel_style)

	# --- PanelContainer ---
	t.set_stylebox("panel", "PanelContainer", panel_style)

	return t

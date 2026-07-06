# RankUI.gd - 排行榜面板
extends Control

@onready var rank_list = $Center/VBox/RankList
@onready var close_button = $Center/VBox/CloseButton
@onready var title_label = $Center/VBox/Title

func _ready():
	close_button.pressed.connect(_on_close)
	GameAPI.rank_loaded.connect(_on_rank_loaded)
	_style_button(close_button, GameTheme.COLOR_BLUE_CHIP)

func show_rank():
	# 请求排行榜数据
	GameAPI.get_global_rank()
	# 清空旧列表
	for child in rank_list.get_children():
		child.queue_free()
	# 显示加载提示
	var loading = Label.new()
	loading.text = "加载中..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	rank_list.add_child(loading)

func _on_rank_loaded(entries: Array):
	# 清空旧列表
	for child in rank_list.get_children():
		child.queue_free()

	if entries.is_empty():
		var empty = Label.new()
		empty.text = "暂无排行数据"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		rank_list.add_child(empty)
		return

	for entry in entries:
		var rank_num = int(entry.get("rank", 0))
		var user_id = str(entry.get("user_id", "---"))
		var score = int(entry.get("score", 0))

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		# 排名
		var rank_lbl = Label.new()
		rank_lbl.custom_minimum_size = Vector2(48, 0)
		rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_lbl.add_theme_font_size_override("font_size", 18)
		match rank_num:
			1:
				rank_lbl.text = "🥇"
				rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1))
			2:
				rank_lbl.text = "🥈"
				rank_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
			3:
				rank_lbl.text = "🥉"
				rank_lbl.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2, 1))
			_:
				rank_lbl.text = "#%d" % rank_num
				rank_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

		# 用户名
		var name_lbl = Label.new()
		name_lbl.custom_minimum_size = Vector2(140, 0)
		name_lbl.text = user_id
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_MAIN)

		# 分数
		var score_lbl = Label.new()
		score_lbl.custom_minimum_size = Vector2(100, 0)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_lbl.text = "%d" % score
		score_lbl.add_theme_font_size_override("font_size", 15)
		score_lbl.add_theme_color_override("font_color", GameTheme.COLOR_ACCENT)

		row.add_child(rank_lbl)
		row.add_child(name_lbl)
		row.add_child(score_lbl)
		rank_list.add_child(row)

func _on_close():
	visible = false

func _style_button(btn: Button, color: Color):
	var s = GameTheme.get_button_style(color)
	var h = GameTheme.get_button_hover_style(color)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

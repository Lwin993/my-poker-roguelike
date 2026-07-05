# ResultUI.gd - 结算界面
extends Control

@onready var total_score_label = $Center/VBox/ScoreContainer/ScoreVBox/TotalScoreLabel
@onready var global_rank_label = $Center/VBox/ScoreContainer/ScoreVBox/RankRow/GlobalRankLabel
@onready var friend_rank_label = $Center/VBox/ScoreContainer/ScoreVBox/RankRow/FriendRankLabel
@onready var reward_name       = $Center/VBox/RewardContainer/RewardVBox/RewardName
@onready var tier_items        = $Center/VBox/TierList/TierItems
@onready var play_again_button = $Center/VBox/ButtonRow/PlayAgainButton
@onready var menu_button       = $Center/VBox/ButtonRow/MenuButton

func _ready():
	_style_button(play_again_button, Color(0.20, 0.80, 0.60, 1))
	_style_button(menu_button, Color(0.55, 0.65, 0.75, 1))

	play_again_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_menu)
	GameAPI.result_submitted.connect(_on_result_received)
	_build_tier_list()

func _style_button(btn: Button, color: Color):
	var s = StyleBoxFlat.new()
	s.bg_color = color * 0.22
	s.border_color = color
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	var h = s.duplicate(); h.bg_color = color * 0.38
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func show_result():
	total_score_label.text = "最终总分: %d" % RoundManager.total_score
	var tier = ConfigLoader.get_reward_tier(RoundManager.total_score)
	if tier.is_empty():
		reward_name.text = "无奖品"
		reward_name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	else:
		reward_name.text = tier.get("reward_name", "参与奖")
		_set_reward_color(tier.get("reward_type", "digital"))

func _on_result_received(data: Dictionary):
	total_score_label.text = "最终总分: %d" % data.get("total_score", 0)
	global_rank_label.text = "🌍 全服 #%d" % data.get("global_rank", 0)
	friend_rank_label.text = "👥 好友 #%d" % data.get("friend_rank", 0)
	var tier = data.get("reward_tier", {})
	if tier.is_empty():
		reward_name.text = "参与奖"
		_set_reward_color("digital")
	else:
		reward_name.text = tier.get("reward_name", "参与奖")
		_set_reward_color(tier.get("reward_type", "digital"))

func _set_reward_color(reward_type: String):
	match reward_type:
		"rare":    reward_name.add_theme_color_override("font_color", Color(1.0, 0.40, 0.10, 1))
		"coupon":  reward_name.add_theme_color_override("font_color", Color(0.95, 0.75, 0.10, 1))
		"drink":   reward_name.add_theme_color_override("font_color", Color(0.30, 0.85, 0.70, 1))
		_:         reward_name.add_theme_color_override("font_color", Color(0.65, 0.70, 0.80, 1))

func _build_tier_list():
	for child in tier_items.get_children():
		child.queue_free()

	const TIER_COLORS = {
		"rare": Color(1.0, 0.40, 0.10, 1),
		"coupon": Color(0.95, 0.75, 0.10, 1),
		"drink": Color(0.30, 0.85, 0.70, 1),
		"digital": Color(0.65, 0.70, 0.80, 1),
	}

	for tier in ConfigLoader.reward_tiers:
		var min_s = tier.get("min_score", 0)
		var max_s = tier.get("max_score", -1)
		var range_str = "%d ~ %s 分" % [min_s, str(max_s) if max_s != -1 else "∞"]
		var reward = tier.get("reward_name", "")
		var r_type = tier.get("reward_type", "digital")
		var color = TIER_COLORS.get(r_type, Color(0.7, 0.7, 0.7, 1))

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var range_lbl = Label.new()
		range_lbl.text = range_str
		range_lbl.custom_minimum_size = Vector2(160, 0)
		range_lbl.add_theme_font_size_override("font_size", 12)
		range_lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 1))

		var arrow_lbl = Label.new()
		arrow_lbl.text = "→"
		arrow_lbl.add_theme_font_size_override("font_size", 12)
		arrow_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6, 1))

		var reward_lbl = Label.new()
		reward_lbl.text = reward
		reward_lbl.add_theme_font_size_override("font_size", 13)
		reward_lbl.add_theme_color_override("font_color", color)

		row.add_child(range_lbl)
		row.add_child(arrow_lbl)
		row.add_child(reward_lbl)
		tier_items.add_child(row)

func _on_play_again():
	GameState.clear_save()
	GameAPI.start_game()
	RoundManager.start_new_game()

func _on_menu():
	GameState.clear_save()
	RoundManager.go_to_main_menu()

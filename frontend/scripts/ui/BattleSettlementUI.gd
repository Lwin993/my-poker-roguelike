# BattleSettlementUI.gd - 每场战斗结束后的独立战果结算
extends Control

@onready var background: TextureRect = $Background
@onready var chapter_label: Label = $Margin/Content/ChapterLabel
@onready var title_label: Label = $Margin/Content/TitleLabel
@onready var progress_label: Label = $Margin/Content/ProgressLabel
@onready var victory_card: PanelContainer = $Margin/Content/VictoryCard
@onready var stage_badge: Label = $Margin/Content/VictoryCard/CardMargin/CardVBox/StageRow/StageBadge
@onready var clear_badge: Label = $Margin/Content/VictoryCard/CardMargin/CardVBox/StageRow/ClearBadge
@onready var monster_portrait: TextureRect = $Margin/Content/VictoryCard/CardMargin/CardVBox/PortraitArea/MonsterPortrait
@onready var victory_seal: Label = $Margin/Content/VictoryCard/CardMargin/CardVBox/PortraitArea/VictorySeal
@onready var monster_name: Label = $Margin/Content/VictoryCard/CardMargin/CardVBox/MonsterName
@onready var victory_line: Label = $Margin/Content/VictoryCard/CardMargin/CardVBox/VictoryLine
@onready var stats_panel: PanelContainer = $Margin/Content/StatsPanel
@onready var damage_value: Label = $Margin/Content/StatsPanel/StatsMargin/StatsVBox/StatsRow/DamageStat/Value
@onready var play_value: Label = $Margin/Content/StatsPanel/StatsMargin/StatsVBox/StatsRow/PlayStat/Value
@onready var highest_value: Label = $Margin/Content/StatsPanel/StatsMargin/StatsVBox/StatsRow/HighestStat/Value
@onready var best_hand_label: Label = $Margin/Content/StatsPanel/StatsMargin/StatsVBox/BestHandLabel
@onready var reward_label: Label = $Margin/Content/RewardLabel
@onready var continue_button: Button = $Margin/Content/ContinueButton

var _entry_tween: Tween

func _ready():
	set_meta("battle_settlement", true)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.add_theme_stylebox_override("normal", GameTheme.get_button_style(GameTheme.COLOR_GOLD))
	continue_button.add_theme_stylebox_override("hover", GameTheme.get_button_hover_style(GameTheme.COLOR_GOLD))
	continue_button.add_theme_stylebox_override("pressed", GameTheme.get_button_pressed_style(GameTheme.COLOR_GOLD))
	continue_button.add_theme_color_override("font_color", Color("fff2c2"))
	continue_button.add_theme_color_override("font_hover_color", Color.WHITE)

	var victory_style := GameTheme.get_panel_style(Color("171510"), Color("e4ad3f"), 20)
	victory_style.bg_color.a = 0.91
	victory_style.set_border_width_all(2)
	victory_style.shadow_size = 12
	victory_card.add_theme_stylebox_override("panel", victory_style)

	var stats_style := GameTheme.get_panel_style(Color("101b21"), Color("4b8b84"), 15)
	stats_style.bg_color.a = 0.94
	stats_style.set_border_width_all(1)
	stats_panel.add_theme_stylebox_override("panel", stats_style)

func show_settlement():
	var round_idx := clampi(RoundManager.last_cleared_round, 0, 2)
	var blind_idx := clampi(RoundManager.last_cleared_blind, 0, 2)
	var stage_names := ["小兵", "精英", "大妖"]
	var clear_names := ["击破", "镇伏", "降伏"]
	var stage_number := round_idx * 3 + blind_idx + 1
	var is_final_boss := round_idx == 2 and blind_idx == 2

	background.texture = load(RoundManager.BATTLE_BACKGROUND_PATHS[round_idx])
	var portrait_path: String = RoundManager.MONSTER_TEXTURE_PATHS[round_idx][blind_idx]
	if blind_idx == 2:
		portrait_path = RoundManager.BOSS_ENRAGED_TEXTURE_PATHS[round_idx]
	monster_portrait.texture = load(portrait_path)

	chapter_label.text = ["白骨岭", "黄风岭", "火云洞"][round_idx]
	title_label.text = "战 斗 结 算"
	progress_label.text = "取经路 · 第 %d / 9 战" % stage_number
	stage_badge.text = "第%d轮 · %s" % [round_idx + 1, stage_names[blind_idx]]
	clear_badge.text = clear_names[blind_idx]
	monster_name.text = RoundManager.MONSTER_NAMES[round_idx][blind_idx]
	victory_line.text = "火云洞破 · 取经路通" if is_final_boss else "妖气已散 · 前路已开"

	var battle_logs := _get_battle_logs(round_idx, blind_idx)
	var highest_hit := 0
	var best_hand := "尚无记录"
	for entry in battle_logs:
		var claimed := int(entry.get("claimed", 0))
		if claimed >= highest_hit:
			highest_hit = claimed
			best_hand = str(entry.get("hand_name", "未知牌型"))

	damage_value.text = _format_number(RoundManager.round_score)
	play_value.text = "%d 次" % battle_logs.size()
	highest_value.text = _format_number(highest_hit)
	best_hand_label.text = "最强牌型  ·  %s" % best_hand
	reward_label.text = "灵石奖励   +%s" % _format_number(RoundManager.last_cleared_reward)
	continue_button.text = "通过 · 查看最终结算  ▶" if is_final_boss else "通过 · 前往仙铺  ▶"
	continue_button.set_meta("final_boss_skips_shop", is_final_boss)
	continue_button.disabled = false

	_animate_entry(is_final_boss)

func _get_battle_logs(round_idx: int, blind_idx: int) -> Array:
	return RoundManager.play_log.filter(func(entry):
		return int(entry.get("round", -1)) == round_idx and int(entry.get("blind", -1)) == blind_idx)

func _animate_entry(is_final_boss: bool):
	if _entry_tween and _entry_tween.is_valid():
		_entry_tween.kill()
	background.scale = Vector2(1.08, 1.08)
	background.pivot_offset = size * 0.5
	title_label.modulate.a = 0.0
	title_label.position.y -= 12.0
	victory_card.modulate.a = 0.0
	victory_card.scale = Vector2(0.88, 0.88)
	victory_card.pivot_offset = victory_card.size * 0.5
	monster_portrait.modulate.a = 0.0
	monster_portrait.scale = Vector2(0.70, 0.70)
	monster_portrait.pivot_offset = monster_portrait.size * 0.5
	victory_seal.modulate.a = 0.0
	victory_seal.scale = Vector2(1.75, 1.75)
	victory_seal.pivot_offset = victory_seal.size * 0.5
	stats_panel.modulate.a = 0.0
	reward_label.modulate.a = 0.0
	continue_button.modulate.a = 0.0

	_entry_tween = create_tween()
	_entry_tween.set_parallel(true)
	_entry_tween.tween_property(background, "scale", Vector2.ONE, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_entry_tween.tween_property(title_label, "modulate:a", 1.0, 0.24)
	_entry_tween.tween_property(title_label, "position:y", title_label.position.y + 12.0, 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_entry_tween.tween_property(victory_card, "modulate:a", 1.0, 0.30).set_delay(0.10)
	_entry_tween.tween_property(victory_card, "scale", Vector2.ONE, 0.42).set_delay(0.10).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_entry_tween.tween_property(monster_portrait, "modulate:a", 1.0, 0.28).set_delay(0.18)
	_entry_tween.tween_property(monster_portrait, "scale", Vector2.ONE, 0.42).set_delay(0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_entry_tween.tween_property(victory_seal, "modulate:a", 1.0, 0.12).set_delay(0.42)
	_entry_tween.tween_property(victory_seal, "scale", Vector2.ONE, 0.28).set_delay(0.42).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_entry_tween.tween_property(stats_panel, "modulate:a", 1.0, 0.28).set_delay(0.46)
	_entry_tween.tween_property(reward_label, "modulate:a", 1.0, 0.22).set_delay(0.58)
	_entry_tween.tween_property(continue_button, "modulate:a", 1.0, 0.22).set_delay(0.68)
	if is_final_boss:
		_entry_tween.tween_callback(_final_boss_flash).set_delay(0.52)

func _final_boss_flash():
	var original := victory_seal.get_theme_color("font_color")
	victory_seal.add_theme_color_override("font_color", Color("fff5a8"))
	var flash := create_tween()
	flash.tween_interval(0.16)
	flash.tween_callback(func(): victory_seal.add_theme_color_override("font_color", original))

func _on_continue_pressed():
	if RoundManager.current_phase != RoundManager.Phase.ROUND_END:
		return
	continue_button.disabled = true
	RoundManager.continue_after_battle_settlement()

func _format_number(value: int) -> String:
	var text := str(value)
	var output := ""
	while text.length() > 3:
		output = "," + text.right(3) + output
		text = text.left(text.length() - 3)
	return text + output

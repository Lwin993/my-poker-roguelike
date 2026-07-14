# GameBoardUI.gd - 主战斗界面交互逻辑
extends Control

signal damage_animation_stage(stage: String)
signal encounter_intro_stage(stage: String)

@onready var backdrop          = $Backdrop
@onready var battle_background = $BattleBackground
@onready var operation_area_bg = $OperationAreaBG
@onready var main_vbox         = $MainVBox
@onready var play_surface      = $MainVBox/PlaySurface
@onready var combo_banner      = $ComboBanner
@onready var hit_flash         = $HitFlash

# ── 顶部状态栏 ──
@onready var round_label       = $MainVBox/TopBar/RoundBadge/RoundLabel
@onready var coins_label       = $MainVBox/TopBar/EconomyPanel/EconomyVBox/CoinsLabel
# ── 分数 ──
@onready var monster_health_panel = $MainVBox/PlaySurface/MonsterHealthPanel
@onready var round_turn_badge = $MainVBox/PlaySurface/RoundTurnBadge
@onready var round_turn_label = $MainVBox/PlaySurface/RoundTurnBadge/RoundTurnLabel
@onready var score_label       = $MainVBox/PlaySurface/MonsterHealthPanel/HealthValueLabel
@onready var threshold_label   = $MainVBox/PlaySurface/MonsterHealthPanel/HealthTitleLabel
@onready var progress_bar      = $MainVBox/PlaySurface/MonsterHealthPanel/HealthProgressBar
@onready var round_score_detail = $MainVBox/PlaySurface/MonsterHealthPanel/HealthDetailLabel
# ── 信息行 ──
@onready var hand_tray         = $MainVBox/HandRow
@onready var boss_skill_label  = $MainVBox/BottomTools/BossSkillLabel
@onready var plays_label       = $MainVBox/TopBar/ActionCounts/PlaysLabel
@onready var discards_label    = $MainVBox/TopBar/ActionCounts/DiscardsLabel
@onready var total_score_label = $MainVBox/TopBar/EconomyPanel/EconomyVBox/TotalScoreLabel
# ── 参数面板 ──
@onready var mult_label        = $MainVBox/ParamsPanel/ParamsHBox/MultLabel
@onready var crit_rate_label   = $MainVBox/ParamsPanel/ParamsHBox/CritRateLabel
@onready var crit_mult_label   = $MainVBox/ParamsPanel/ParamsHBox/CritMultLabel
# ── 道具区 ──
@onready var artifact_bar_label = $MainVBox/ArtifactDock/ArtifactDockLabel
@onready var consumable_bar_label = $MainVBox/HandRow/HandContent/ConsumableDock/ConsumableDockLabel
@onready var joker_slots       = $MainVBox/ArtifactDock/ArtifactScroll/ArtifactSlots
@onready var cons_slots        = $MainVBox/HandRow/HandContent/ConsumableDock/ConsumableScroll/ConsumableSlots
# ── 手牌 / 按钮 ──
@onready var hand_area         = $MainVBox/HandRow/HandContent/HandArea
@onready var play_button       = $MainVBox/ButtonRow/PlayButton
@onready var discard_button    = $MainVBox/ButtonRow/DiscardButton
@onready var play_count_label  = $MainVBox/ButtonRow/PlayButton/ActionContent/CountLabel
@onready var play_action_label = $MainVBox/ButtonRow/PlayButton/ActionContent/HintLabel
@onready var discard_count_label = $MainVBox/ButtonRow/DiscardButton/ActionContent/CountLabel
@onready var discard_action_label = $MainVBox/ButtonRow/DiscardButton/ActionContent/HintLabel
@onready var sort_dock         = $MainVBox/BottomTools/SortDock
@onready var sort_by_rank_btn  = $MainVBox/BottomTools/SortDock/SortRow/SortByRankButton
@onready var sort_by_suit_btn  = $MainVBox/BottomTools/SortDock/SortRow/SortBySuitButton
# ── 弹出层 ──
@onready var score_popup       = $ScorePopup
@onready var revive_dialog     = $ReviveDialog
# ── 牌桌内联计分区 ──
@onready var calc_title        = $MainVBox/PlaySurface/CalcTitle
@onready var monster_shake_root = $MainVBox/PlaySurface/MonsterShakeRoot
@onready var monster_avatar    = $MainVBox/PlaySurface/MonsterShakeRoot/MonsterAvatar
@onready var monster_glow      = $MainVBox/PlaySurface/MonsterShakeRoot/MonsterGlow
@onready var monster_title     = $MainVBox/PlaySurface/MonsterTitle
@onready var boss_phase_badge  = $MainVBox/PlaySurface/BossPhaseBadge
@onready var formula_label     = $MainVBox/PlaySurface/FormulaLabel
@onready var played_area       = $MainVBox/PlaySurface/PlayedCenter/PlayedArea
@onready var played_center     = $MainVBox/PlaySurface/PlayedCenter
@onready var table_hint_label  = $MainVBox/PlaySurface/TableHintLabel
@onready var damage_zone       = $MainVBox/PlaySurface/DamageZone
@onready var damage_zone_title = $MainVBox/PlaySurface/DamageZoneTitle
@onready var damage_chips_label = $MainVBox/PlaySurface/DamageChipsLabel
@onready var damage_mult_label = $MainVBox/PlaySurface/DamageMultLabel
@onready var attack_stick_button = $MainVBox/ArtifactDock/AttackStickButton
@onready var attack_stick_art  = $MainVBox/ArtifactDock/AttackStickButton/StickArt
@onready var strike_stick      = $MainVBox/PlaySurface/StrikeStick
@onready var score_burst_label = $MainVBox/PlaySurface/ScoreBurstLabel
@onready var calc_steps_list   = $MainVBox/PlaySurface/CalcStepsList
@onready var final_score_label = $MainVBox/PlaySurface/FinalScoreLabel
@onready var crit_banner       = $MainVBox/PlaySurface/CritBanner
@onready var monster_damage_label = $MainVBox/PlaySurface/MonsterDamageLabel
@onready var calc_close_hint   = $MainVBox/PlaySurface/CalcCloseHint
# ── 法宝详情浮层 ──
@onready var joker_detail_overlay = $JokerDetailOverlay
@onready var joker_detail_bg      = $JokerDetailOverlay/JokerDetailBG
@onready var joker_detail_panel   = $JokerDetailOverlay/JokerDetailPanel
@onready var joker_detail_title   = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailTitle
@onready var joker_detail_level   = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailLevel
@onready var joker_detail_desc    = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailDesc
@onready var joker_detail_params  = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailParamsScroll/JokerDetailParams
@onready var joker_detail_use     = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailUse
@onready var joker_detail_close   = $JokerDetailOverlay/JokerDetailPanel/JokerDetailVBox/JokerDetailClose
# ── 精英 / 大妖登场浮层 ──
@onready var encounter_intro       = $EncounterIntro
@onready var encounter_shade       = $EncounterIntro/Shade
@onready var encounter_theme_tint  = $EncounterIntro/ThemeTint
@onready var encounter_effect_layer = $EncounterIntro/EffectLayer
@onready var encounter_portrait    = $EncounterIntro/Portrait
@onready var encounter_card        = $EncounterIntro/IntroCard
@onready var encounter_type_label  = $EncounterIntro/IntroCard/IntroVBox/TypeLabel
@onready var encounter_name_label  = $EncounterIntro/IntroCard/IntroVBox/NameLabel
@onready var encounter_dialogue_label = $EncounterIntro/IntroCard/IntroVBox/DialogueLabel
@onready var encounter_skill_panel = $EncounterIntro/IntroCard/IntroVBox/SkillPanel
@onready var encounter_skill_name  = $EncounterIntro/IntroCard/IntroVBox/SkillPanel/SkillVBox/SkillName
@onready var encounter_skill_desc  = $EncounterIntro/IntroCard/IntroVBox/SkillPanel/SkillVBox/SkillDesc
@onready var encounter_effect_preview = $EncounterIntro/IntroCard/IntroVBox/EffectPreview
@onready var encounter_continue_button = $EncounterIntro/IntroCard/IntroVBox/ContinueButton

# ── 状态 ──
var _used_consumable_items: Array = [] # 已加入“下一次出牌”的具体道具实例，允许同名叠加
var _selected_indices:      Array = []
var _card_nodes:            Array = []
var _base_score_preview:    int   = 0
var _joker_badge_nodes:     Array = []
var _last_monster_texture_path := ""
var _was_boss_enraged := false
var _enrage_transition_pending := false
var _detail_consumable = null
var _detail_consumable_active := false
var _last_battle_background_path := ""
var _active_sort_mode := "rank"
var _damage_visual_transaction := false
var _pending_health_refresh := false
var _strike_damage_target_scale := 1.0
var _strike_reference_damage := 1.0
var _damage_spike_nodes: Array[Polygon2D] = []
var _monster_aura_tween: Tween
var _monster_hit_tween: Tween
var _monster_shake_origin_position := Vector2.ZERO
var _monster_idle_origin_position := Vector2.ZERO
var _monster_glow_idle_origin_position := Vector2.ZERO
var _monster_idle_initialized := false
var _monster_hit_generation := 0
var _shown_encounter_intros: Dictionary = {}
var _encounter_intro_active := false
var _encounter_intro_kind := ""
var _encounter_dialogue_lines: Array[String] = []
var _encounter_dialogue_index := 0
var _encounter_intro_run_id := 0

const HAND_CARD_SIZE := Vector2(76, 112)
const TABLE_CARD_SIZE := Vector2(36, 62)
const ARTIFACT_SLOT_COUNT := 3
const CONSUMABLE_SLOT_COUNT := 3
const ARTIFACT_SLOT_SIZE := Vector2(64, 64)
const CONSUMABLE_SLOT_SIZE := Vector2(50, 50)
const ATTACK_STICK_TEXTURE_PATH := "res://assets/artifacts/jingubang-straight.png"
const STICK_BATTLE_BASE_SCALE := 1.32
const STICK_BATTLE_WIDTH_RATIO := 1.90
const MONSTER_HEAD_IMPACT_POINT := Vector2(0.50, 0.29)
const WHITE_BONE_DISGUISE_TEXTURE_PATHS = [
	"res://assets/monsters/baigujing-disguise-young.png",
	"res://assets/monsters/baigujing-disguise-old-woman.png",
	"res://assets/monsters/baigujing-disguise-old-man.png",
]
const YELLOW_WIND_ACTION_TEXTURE_PATHS = [
	"res://assets/monsters/huangfengguai-charge.png",
	"res://assets/monsters/huangfengguai-breath.png",
]
const HOLY_FIRE_ACTION_TEXTURE_PATHS = [
	"res://assets/monsters/honghaier-spear-sweep.png",
	"res://assets/monsters/honghaier-true-fire.png",
]

# 战斗 HUD 使用同一套“墨色漆木 + 暖金结构线”语言，章节色只作为很轻的环境提示。
const BATTLE_INK := Color("09111d")
const BATTLE_INK_RAISED := Color("111a26")
const BATTLE_LACQUER := Color("21130f")
const BATTLE_GOLD := Color("d7ad62")
const BATTLE_GOLD_BRIGHT := Color("f0c66f")
const BATTLE_PRIMARY := Color("c84b2f")
const BATTLE_SECONDARY := Color("687783")

# 精英是为三处原著关隘补充的拦路部将，台词只借用场景气氛，不冒充原著具名角色。
const ELITE_ENCOUNTERS = [
	{
		"title": "白骨岭 · 枯骨拦路",
		"skill": "枯骨锁魂",
		"description": "随机封锁 1 张手牌，本回合无法选中",
		"lines": [
			"白骨岭阴风贴地而来，散落的枯骨忽然披甲起身。",
			"骷髅将：夫人有令——先锁你一张牌，再慢慢取你性命！",
		]
	},
	{
		"title": "黄风岭 · 怪风先锋",
		"skill": "风沙遮面",
		"description": "随机将 1 张手牌翻至背面，牌面暂不可见",
		"lines": [
			"黄风岭尘沙蔽日，一股小旋风贴着山道疾驰而来。",
			"小旋风：睁大眼也没用！先把你一张牌埋进风沙里！",
		]
	},
	{
		"title": "火云洞 · 烈焰门童",
		"skill": "火种压制",
		"description": "本回合第 1 次出牌伤害降低 25%",
		"lines": [
			"火云洞前热浪翻滚，守门童子踩着火星跃到阵前。",
			"火灵童：大王的真火还没烧到，先接我这一团火种！",
		]
	},
]

const BOSS_ENCOUNTERS = [
	{
		"chapter": "白骨岭 · 尸魔三变",
		"skill": "白骨幻术",
		"description": "少女、老妇、老翁三重幻身散去——2 张手牌化为不可选中的幻影牌",
		"line": "白骨夫人三番变化，皮相散尽，真身自岭中现形。",
		"variant": "white_bone",
	},
	{
		"chapter": "黄风岭 · 神风蔽日",
		"skill": "风沙走石",
		"description": "三昧神风席卷牌桌——3 张手牌被风沙盖住牌面",
		"line": "黄风怪执三股钢叉出洞，张口一吹，昏天暗地、走石飞沙。",
		"variant": "yellow_wind",
	},
	{
		"chapter": "火云洞 · 圣婴真火",
		"skill": "三昧真火",
		"description": "真火封住其余牌路——本回合仅 2 种指定牌型可造成伤害",
		"line": "圣婴大王红孩儿踏火登场，火云洞前顷刻化作一片火海。",
		"variant": "holy_fire",
	},
]

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

	_style_main_button(play_button, BATTLE_PRIMARY, true)
	_style_main_button(discard_button, BATTLE_SECONDARY, false)
	# 草图中“出牌”位于左侧、“换牌”位于右侧；保留节点路径，只调整视觉顺序。
	play_button.get_parent().move_child(play_button, 0)
	_style_panel($MainVBox/TopBar/RoundBadge, GameTheme.COLOR_GOLD, 0.12)
	_style_panel($MainVBox/TopBar/EconomyPanel, GameTheme.COLOR_ACCENT, 0.10)
	_style_compact_monster_health()
	_style_round_turn_badge()
	_style_weapon_artifact_dock($MainVBox/ArtifactDock)
	_style_utility_dock($MainVBox/HandRow/HandContent/ConsumableDock)
	_style_panel($MainVBox/ParamsPanel, GameTheme.COLOR_BLUE_CHIP, 0.08)
	_style_panel($JokerDetailOverlay/JokerDetailPanel, GameTheme.COLOR_JOKER, 0.12)
	_style_encounter_intro()
	# 伤害结算不再展开大面板；只显示攻击数值和成长中的金箍棒。
	damage_zone.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_style_wood_slot_button(attack_stick_button)
	_style_weapon_slot_button(attack_stick_button)
	attack_stick_button.set_meta("attack_stick_slot", true)
	attack_stick_button.set_meta("weapon_slot", true)
	attack_stick_button.tooltip_text = "如意金箍棒 · 查看本场攻击战报"
	attack_stick_button.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	# 金箍棒只作为伤害结算的攻击载体；法宝装备已替换为芭蕉扇。
	attack_stick_art.texture = load(ATTACK_STICK_TEXTURE_PATH)
	attack_stick_art.pivot_offset = attack_stick_art.size * 0.5
	attack_stick_art.scale = Vector2(1.65, 1.0)
	strike_stick.texture = attack_stick_art.texture
	# Boss 第二形态只通过立绘、气场和转场表现，不显示阶段文字。
	boss_phase_badge.visible = false
	boss_phase_badge.text = ""
	for label in [score_label, calc_title, score_burst_label, crit_banner, monster_title, damage_chips_label, damage_mult_label]:
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.02, 0.12, 0.95))
		label.add_theme_constant_override("outline_size", 6)

	play_button.pressed.connect(_on_play_pressed)
	discard_button.pressed.connect(_on_discard_pressed)
	attack_stick_button.pressed.connect(_show_attack_info)
	hand_area.resized.connect(func(): _layout_hand_cards(false))
	revive_dialog.confirmed.connect(_on_revive_ad)
	revive_dialog.canceled.connect(_on_give_up)

	# Connect revive API signals
	GameAPI.revive_prepared.connect(_on_revive_prepared)
	GameAPI.revive_completed.connect(_on_revive_completed)

	# 排序按钮
	_update_sort_button_styles()
	sort_by_rank_btn.pressed.connect(_on_sort_by_rank)
	sort_by_suit_btn.pressed.connect(_on_sort_by_suit)

	# 法宝详情关闭按钮
	joker_detail_close.pressed.connect(func(): joker_detail_overlay.visible = false)
	joker_detail_use.pressed.connect(_on_detail_consumable_use)
	encounter_continue_button.pressed.connect(_on_encounter_continue_pressed)
	joker_detail_bg.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			joker_detail_overlay.visible = false
	)

	_style_button(joker_detail_close, GameTheme.COLOR_BLUE_CHIP)
	_style_button(joker_detail_use, GameTheme.COLOR_ACCENT)
	crit_rate_label.visible = true
	crit_mult_label.visible = true
	_reset_inline_calc()
	_update_ui()
	_start_idle_juice()
	encounter_intro.visible = false

func _style_main_button(btn: Button, color: Color, is_primary: bool):
	btn.set_meta("action_button_v2", true)
	var s = StyleBoxFlat.new()
	s.bg_color = Color("6d2117") if is_primary else Color("18222c")
	s.border_color = BATTLE_GOLD_BRIGHT if is_primary else Color(0.55, 0.59, 0.59, 0.72)
	s.set_border_width_all(2)
	s.border_width_bottom = 5 if is_primary else 3
	s.set_corner_radius_all(11)
	s.shadow_color = Color(0.90, 0.42, 0.16, 0.34) if is_primary else Color(0.0, 0.0, 0.0, 0.42)
	s.shadow_size = 7 if is_primary else 3
	var h: StyleBoxFlat = s.duplicate()
	h.bg_color = s.bg_color.lightened(0.09)
	h.border_color = BATTLE_GOLD_BRIGHT if is_primary else BATTLE_GOLD
	h.shadow_size += 3
	var p: StyleBoxFlat = s.duplicate()
	p.bg_color = s.bg_color.darkened(0.13)
	p.border_width_top = 4
	p.border_width_bottom = 2
	var disabled: StyleBoxFlat = s.duplicate()
	disabled.bg_color = Color("20242a")
	disabled.border_color = Color("4b4d4e")
	disabled.shadow_size = 0
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("disabled", disabled)

func _style_panel(panel: PanelContainer, color: Color, mix: float):
	panel.add_theme_stylebox_override("panel", GameTheme.get_panel_style(
		GameTheme.COLOR_BG_PANEL.lerp(color, mix), color.darkened(0.20), 9))

func _style_button(btn: Button, color: Color):
	var s = GameTheme.get_button_style(color)
	var h = GameTheme.get_button_hover_style(color)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  h)
	btn.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_MAIN)

func _style_encounter_intro():
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.055, 0.025, 0.02, 0.96)
	card_style.border_color = Color("d99238")
	card_style.border_width_left = 3
	card_style.border_width_right = 3
	card_style.border_width_top = 4
	card_style.border_width_bottom = 6
	card_style.set_corner_radius_all(17)
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.78)
	card_style.shadow_size = 14
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 11
	encounter_card.add_theme_stylebox_override("panel", card_style)
	var skill_style := StyleBoxFlat.new()
	skill_style.bg_color = Color(0.22, 0.055, 0.025, 0.88)
	skill_style.border_color = Color(1.0, 0.40, 0.16, 0.62)
	skill_style.set_border_width_all(1)
	skill_style.set_corner_radius_all(9)
	skill_style.content_margin_left = 8
	skill_style.content_margin_right = 8
	skill_style.content_margin_top = 5
	skill_style.content_margin_bottom = 5
	encounter_skill_panel.add_theme_stylebox_override("panel", skill_style)
	_style_main_button(encounter_continue_button, Color("ff7b24"), true)

func _style_sort_button(btn: Button, color: Color, active: bool):
	btn.set_meta("active_sort", active)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(color.r, color.g, color.b, 0.26 if active else 0.055)
	s.border_color = color if active else Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.22)
	s.set_border_width_all(2 if active else 1); s.set_corner_radius_all(8)
	s.content_margin_left = 6; s.content_margin_right = 6
	s.content_margin_top = 3; s.content_margin_bottom = 3
	var h: StyleBoxFlat = s.duplicate(); h.bg_color = Color(color.r, color.g, color.b, 0.32); h.border_color = color
	var p: StyleBoxFlat = s.duplicate(); p.bg_color = Color(color.r, color.g, color.b, 0.55)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color.WHITE if active else GameTheme.COLOR_TEXT_DIM)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

func _update_sort_button_styles():
	_style_sort_button(sort_by_rank_btn, Color("b88f58"), _active_sort_mode == "rank")
	_style_sort_button(sort_by_suit_btn, Color("718c7d"), _active_sort_mode == "suit")

func _style_compact_monster_health():
	# 名称与生命值收进同一个低矮胶囊，减少顶部漂浮元素的数量。
	monster_health_panel.set_meta("health_capsule_v3", true)
	var capsule = StyleBoxFlat.new()
	capsule.bg_color = Color(0.035, 0.045, 0.055, 0.90)
	capsule.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.72)
	capsule.set_border_width_all(1)
	capsule.set_corner_radius_all(9)
	capsule.shadow_color = Color(0.0, 0.0, 0.0, 0.60)
	capsule.shadow_size = 4
	monster_health_panel.add_theme_stylebox_override("panel", capsule)
	var track = StyleBoxFlat.new()
	track.bg_color = Color(0.035, 0.04, 0.045, 0.78)
	track.set_corner_radius_all(6)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color("c84336")
	fill.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("background", track)
	progress_bar.add_theme_stylebox_override("fill", fill)

func _style_round_turn_badge():
	round_turn_badge.set_meta("compact_round_turn", true)
	var badge = StyleBoxFlat.new()
	badge.bg_color = Color(0.035, 0.045, 0.055, 0.90)
	badge.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.62)
	badge.set_border_width_all(1)
	badge.set_corner_radius_all(7)
	badge.content_margin_left = 4
	badge.content_margin_right = 4
	badge.content_margin_top = 2
	badge.content_margin_bottom = 2
	badge.shadow_color = Color(0.01, 0.01, 0.02, 0.48)
	badge.shadow_size = 2
	round_turn_badge.add_theme_stylebox_override("panel", badge)

func _style_wooden_dock(dock: Panel):
	dock.set_meta("wooden_frame", true)
	var wood = StyleBoxFlat.new()
	wood.bg_color = Color(BATTLE_LACQUER.r, BATTLE_LACQUER.g, BATTLE_LACQUER.b, 0.96)
	wood.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.68)
	wood.set_border_width_all(2)
	wood.set_corner_radius_all(9)
	wood.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	wood.shadow_size = 5
	dock.add_theme_stylebox_override("panel", wood)

func _style_utility_dock(dock: Panel):
	# 草图中的道具区是下半区左栏，而不是一张独立的棕色卡片。
	dock.set_meta("wooden_frame", true)
	dock.set_meta("left_utility_column", true)
	var column := StyleBoxFlat.new()
	column.bg_color = Color(BATTLE_INK_RAISED.r, BATTLE_INK_RAISED.g, BATTLE_INK_RAISED.b, 0.28)
	column.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.42)
	column.border_width_right = 2
	column.content_margin_right = 5
	dock.add_theme_stylebox_override("panel", column)

func _style_weapon_artifact_dock(dock: Panel):
	dock.set_meta("wooden_frame", true)
	dock.set_meta("weapon_artifact_dock", true)
	var wood = StyleBoxFlat.new()
	wood.bg_color = Color(BATTLE_LACQUER.r, BATTLE_LACQUER.g, BATTLE_LACQUER.b, 1.0)
	wood.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.78)
	wood.border_width_left = 0
	wood.border_width_right = 0
	wood.border_width_top = 2
	wood.border_width_bottom = 2
	wood.set_corner_radius_all(0)
	wood.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	wood.shadow_size = 0
	dock.add_theme_stylebox_override("panel", wood)

func _style_battle_regions(round_index: int):
	var accent_colors = [Color("869ac4"), Color("c39454"), Color("c76a4b")]
	var theme_index := clampi(round_index, 0, 2)
	var accent: Color = accent_colors[theme_index]
	operation_area_bg.set_meta("unified_battle_hud_v3", true)
	var battle_frame = StyleBoxFlat.new()
	battle_frame.bg_color = Color(0.015, 0.02, 0.028, 0.04)
	battle_frame.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.28)
	battle_frame.set_border_width_all(1)
	battle_frame.set_corner_radius_all(14)
	$MainVBox/PlaySurface/PlaySurfaceBG.add_theme_stylebox_override("panel", battle_frame)
	var operation_style = StyleBoxFlat.new()
	var operation_color: Color = BATTLE_INK.lerp(accent, 0.065)
	operation_color.a = 0.96
	operation_style.bg_color = operation_color
	operation_style.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.78)
	operation_style.border_width_top = 2
	operation_style.shadow_color = Color(0.01, 0.01, 0.02, 0.72)
	operation_style.shadow_size = 12
	operation_area_bg.add_theme_stylebox_override("panel", operation_style)
	var tray_style = StyleBoxFlat.new()
	tray_style.bg_color = Color(BATTLE_INK_RAISED.r, BATTLE_INK_RAISED.g, BATTLE_INK_RAISED.b, 0.54)
	tray_style.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.20)
	tray_style.set_border_width_all(1)
	tray_style.set_corner_radius_all(16)
	tray_style.content_margin_left = 7
	tray_style.content_margin_right = 7
	tray_style.content_margin_top = 6
	tray_style.content_margin_bottom = 5
	hand_tray.add_theme_stylebox_override("panel", tray_style)
	var sort_style = StyleBoxFlat.new()
	sort_style.bg_color = Color(0.025, 0.03, 0.035, 0.82)
	sort_style.border_color = Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.25)
	sort_style.set_border_width_all(1)
	sort_style.set_corner_radius_all(10)
	sort_style.content_margin_left = 4
	sort_style.content_margin_right = 4
	sort_style.content_margin_top = 2
	sort_style.content_margin_bottom = 2
	sort_dock.add_theme_stylebox_override("panel", sort_style)
func _get_wood_slot_style(is_hover: bool = false, is_pressed: bool = false) -> StyleBoxFlat:
	var slot = StyleBoxFlat.new()
	slot.bg_color = Color("17120f") if not is_hover else Color("3b291a")
	if is_pressed:
		slot.bg_color = Color("110d0b")
	slot.border_color = BATTLE_GOLD_BRIGHT if is_hover else Color(BATTLE_GOLD.r, BATTLE_GOLD.g, BATTLE_GOLD.b, 0.48)
	slot.set_border_width_all(2)
	slot.set_corner_radius_all(7)
	slot.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	slot.shadow_size = 3
	slot.content_margin_left = 3
	slot.content_margin_right = 3
	slot.content_margin_top = 3
	slot.content_margin_bottom = 3
	return slot

func _style_wood_slot_button(btn: Button):
	btn.flat = false
	btn.set_meta("wooden_slot", true)
	btn.add_theme_stylebox_override("normal", _get_wood_slot_style())
	btn.add_theme_stylebox_override("hover", _get_wood_slot_style(true))
	btn.add_theme_stylebox_override("pressed", _get_wood_slot_style(true, true))
	btn.add_theme_stylebox_override("disabled", _get_wood_slot_style())

func _style_weapon_slot_button(btn: Button):
	var normal := _get_wood_slot_style()
	normal.bg_color = Color("17120f")
	normal.border_color = BATTLE_GOLD
	normal.shadow_color = Color(0.86, 0.62, 0.24, 0.28)
	normal.shadow_size = 5
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("3b291a")
	hover.border_color = BATTLE_GOLD_BRIGHT
	hover.shadow_size = 8
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("110d0b")
	pressed.border_color = BATTLE_GOLD_BRIGHT
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _make_empty_wood_slot(slot_size: Vector2) -> Button:
	var slot = Button.new()
	slot.custom_minimum_size = slot_size
	slot.disabled = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.text = ""
	slot.modulate = Color(0.72, 0.72, 0.72, 0.76)
	slot.set_meta("empty_slot", true)
	_style_wood_slot_button(slot)
	return slot

# ── 排序 ────────────────────────────────────────────────────────
# 排序只改 DeckManager.hand 的顺序（A 视为最大），选中状态随之重映射
func _on_sort_by_rank():
	_active_sort_mode = "rank"
	_update_sort_button_styles()
	_sort_hand(func(a, b):
		var ra = 14 if a.rank == 1 else a.rank
		var rb = 14 if b.rank == 1 else b.rank
		return ra > rb  # 大 → 小
	)

func _on_sort_by_suit():
	_active_sort_mode = "suit"
	_update_sort_button_styles()
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
		if RoundManager.current_round == 0 and RoundManager.current_blind == 0 and RoundManager.total_score == 0 and RoundManager.play_log.is_empty():
			_shown_encounter_intros.clear()
		_refresh_all()
		# 商店关闭后，本场敌人已经完成技能初始化；等牌桌布局稳定后再盖上登场演出。
		call_deferred("_maybe_start_encounter_intro")
	else:
		_cancel_encounter_intro()

func _maybe_start_encounter_intro():
	if _encounter_intro_active:
		return
	if RoundManager.current_phase != RoundManager.Phase.PLAYING and RoundManager.current_phase != RoundManager.Phase.ROUND_START:
		return
	if RoundManager.current_blind != 1 and RoundManager.current_blind != 2:
		return
	var encounter_key := "%d:%d" % [RoundManager.current_round, RoundManager.current_blind]
	if _shown_encounter_intros.has(encounter_key):
		return
	_shown_encounter_intros[encounter_key] = true
	_begin_encounter_intro()

func _begin_encounter_intro(force: bool = false):
	if _encounter_intro_active and not force:
		return
	if RoundManager.current_blind != 1 and RoundManager.current_blind != 2:
		return
	# 正常流程由 RoundManager 初始化技能；这里也兜住调试直达关卡的情况。
	if RoundManager.current_blind == 1 and BossSkillManager.current_elite_passive == BossSkillManager.ElitePassive.NONE:
		BossSkillManager.apply_skill(RoundManager.current_round, RoundManager.current_blind)
		BossSkillManager.execute_skill_on_hand(DeckManager.hand)
	elif RoundManager.current_blind == 2 and BossSkillManager.current_skill == BossSkillManager.BossSkill.NONE:
		BossSkillManager.apply_skill(RoundManager.current_round, RoundManager.current_blind)
		BossSkillManager.execute_skill_on_hand(DeckManager.hand)
		_rebuild_hand()

	_encounter_intro_run_id += 1
	var run_id := _encounter_intro_run_id
	_encounter_intro_active = true
	_encounter_dialogue_index = 0
	_clear_encounter_effects()
	_clear_encounter_preview()
	encounter_intro.visible = true
	encounter_intro.modulate = Color.WHITE
	encounter_intro.set_meta("effect_preview_ready", false)
	encounter_shade.color = Color(0.01, 0.012, 0.025, 0.93)
	encounter_theme_tint.color = Color(0.50, 0.16, 0.08, 0.0)
	encounter_portrait.texture = load(RoundManager.MONSTER_TEXTURE_PATHS[RoundManager.current_round][RoundManager.current_blind])
	encounter_portrait.modulate = Color.WHITE
	encounter_portrait.rotation = 0.0
	encounter_portrait.scale = Vector2.ONE
	encounter_card.modulate = Color.WHITE
	encounter_continue_button.disabled = true
	encounter_continue_button.visible = true
	play_button.disabled = true
	discard_button.disabled = true

	if RoundManager.current_blind == 1:
		_encounter_intro_kind = "elite"
		var elite_data: Dictionary = ELITE_ENCOUNTERS[RoundManager.current_round]
		_encounter_dialogue_lines.clear()
		for line in elite_data.get("lines", []):
			_encounter_dialogue_lines.append(str(line))
		encounter_type_label.text = "精英拦路 · %s" % elite_data.get("title", "")
		encounter_name_label.text = RoundManager.get_current_monster_name()
		encounter_dialogue_label.text = _encounter_dialogue_lines[0]
		encounter_skill_name.text = "减益 · %s" % elite_data.get("skill", "")
		encounter_skill_desc.text = elite_data.get("description", "")
		encounter_continue_button.text = "继续  ▶"
		_build_encounter_effect_preview(RoundManager.current_round, 1)
		encounter_intro.set_meta("encounter_variant", "elite_%d" % RoundManager.current_round)
		encounter_intro_stage.emit("elite_dialogue_started")
		_play_elite_entrance(run_id)
	else:
		_encounter_intro_kind = "boss"
		var boss_data: Dictionary = BOSS_ENCOUNTERS[RoundManager.current_round]
		_encounter_dialogue_lines.clear()
		_encounter_dialogue_lines.append(str(boss_data.get("line", "")))
		encounter_type_label.text = "大妖降临 · %s" % boss_data.get("chapter", "")
		encounter_name_label.text = RoundManager.get_current_monster_name()
		encounter_dialogue_label.text = boss_data.get("line", "")
		encounter_skill_name.text = "妖术 · %s" % boss_data.get("skill", "")
		encounter_skill_desc.text = boss_data.get("description", "")
		encounter_continue_button.text = "破阵迎战"
		encounter_continue_button.visible = false
		_build_encounter_effect_preview(RoundManager.current_round, 2)
		var variant := str(boss_data.get("variant", "boss"))
		match variant:
			"white_bone":
				encounter_theme_tint.color = Color(0.40, 0.68, 1.0, 0.0)
				# 白骨精先以少女幻身入场，三变尽破后才允许真身出现。
				encounter_portrait.texture = load(WHITE_BONE_DISGUISE_TEXTURE_PATHS[0])
			"yellow_wind": encounter_theme_tint.color = Color(0.92, 0.55, 0.16, 0.0)
			"holy_fire": encounter_theme_tint.color = Color(1.0, 0.10, 0.015, 0.0)
		encounter_intro.set_meta("encounter_variant", variant)
		encounter_intro_stage.emit("boss_curtain")
		_play_boss_entrance(run_id, variant)

func _cancel_encounter_intro():
	_encounter_intro_run_id += 1
	_encounter_intro_active = false
	encounter_intro.visible = false
	_clear_encounter_effects()

func _on_encounter_continue_pressed():
	if not _encounter_intro_active or encounter_continue_button.disabled:
		return
	if _encounter_intro_kind == "elite" and _encounter_dialogue_index + 1 < _encounter_dialogue_lines.size():
		_encounter_dialogue_index += 1
		encounter_continue_button.disabled = true
		var fade_out := create_tween()
		fade_out.tween_property(encounter_dialogue_label, "modulate:a", 0.0, 0.10)
		await fade_out.finished
		encounter_dialogue_label.text = _encounter_dialogue_lines[_encounter_dialogue_index]
		var fade_in := create_tween()
		fade_in.tween_property(encounter_dialogue_label, "modulate:a", 1.0, 0.18)
		await fade_in.finished
		encounter_continue_button.text = "迎战  ⚔" if _encounter_dialogue_index == _encounter_dialogue_lines.size() - 1 else "继续  ▶"
		encounter_continue_button.disabled = false
		encounter_intro_stage.emit("elite_dialogue_%d" % (_encounter_dialogue_index + 1))
		return
	encounter_continue_button.disabled = true
	if _encounter_intro_kind == "elite":
		await _animate_encounter_effect_preview()
	await _finish_encounter_intro()

func _finish_encounter_intro():
	if not _encounter_intro_active:
		return
	encounter_intro_stage.emit("combat_unlocking")
	var tween := create_tween()
	tween.tween_property(encounter_intro, "modulate:a", 0.0, 0.28).set_ease(Tween.EASE_IN)
	await tween.finished
	encounter_intro.visible = false
	encounter_intro.modulate = Color.WHITE
	_encounter_intro_active = false
	_clear_encounter_effects()
	_update_ui()
	_rebuild_hand_keep_selection()
	encounter_intro_stage.emit("combat_unlocked")

func _play_elite_entrance(run_id: int):
	encounter_portrait.pivot_offset = encounter_portrait.size * 0.5
	encounter_portrait.modulate.a = 0.0
	encounter_portrait.scale = Vector2(0.70, 0.70)
	encounter_card.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(encounter_portrait, "modulate:a", 1.0, 0.42)
	tween.tween_property(encounter_portrait, "scale", Vector2.ONE, 0.58).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(encounter_card, "modulate:a", 1.0, 0.34).set_delay(0.30)
	await tween.finished
	if run_id != _encounter_intro_run_id or not _encounter_intro_active:
		return
	encounter_continue_button.disabled = false
	encounter_intro_stage.emit("elite_ready")

func _play_boss_entrance(run_id: int, variant: String):
	encounter_portrait.pivot_offset = encounter_portrait.size * 0.5
	encounter_portrait.modulate.a = 0.0
	encounter_portrait.scale = Vector2(0.28, 0.28)
	encounter_card.modulate.a = 0.0
	var arrival := create_tween().set_parallel(true)
	arrival.tween_property(encounter_portrait, "modulate:a", 1.0, 0.34)
	arrival.tween_property(encounter_portrait, "scale", Vector2(1.10, 1.10), 0.72).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	arrival.tween_property(encounter_theme_tint, "color:a", 0.30, 0.16)
	arrival.tween_property(encounter_theme_tint, "color:a", 0.0, 0.46).set_delay(0.17)
	await arrival.finished
	if run_id != _encounter_intro_run_id or not _encounter_intro_active:
		return
	match variant:
		"white_bone": await _play_white_bone_intro(run_id)
		"yellow_wind": await _play_yellow_wind_frame_intro(run_id)
		"holy_fire": await _play_holy_fire_frame_intro(run_id)
	if run_id != _encounter_intro_run_id or not _encounter_intro_active:
		return
	# 规则卡先出现，再把本场真正生效的封牌/暗牌/牌型限制逐一盖到预览上。
	var rules_reveal := create_tween()
	rules_reveal.tween_property(encounter_card, "modulate:a", 1.0, 0.30)
	await rules_reveal.finished
	await _animate_encounter_effect_preview()
	var settle := create_tween()
	settle.tween_property(encounter_portrait, "scale", Vector2.ONE, 0.28)
	await settle.finished
	if run_id != _encounter_intro_run_id:
		return
	encounter_continue_button.visible = true
	encounter_continue_button.disabled = false
	encounter_intro_stage.emit("boss_ready")

func _play_white_bone_intro(run_id: int):
	encounter_intro_stage.emit("boss_white_bone_three_forms")
	var form_titles := ["第一变 · 提篮少女", "第二变 · 寻女老妇", "第三变 · 白发老翁"]
	var form_stages := ["white_bone_form_young", "white_bone_form_old_woman", "white_bone_form_old_man"]
	var residuals: Array[Sprite2D] = []
	var caption := _spawn_encounter_label("", Vector2(36.0, size.y * 0.465), Vector2(size.x - 72.0, 54.0), Color(0.91, 0.86, 1.0, 1.0), 21)
	caption.z_index = 5
	for i in range(WHITE_BONE_DISGUISE_TEXTURE_PATHS.size()):
		if run_id != _encounter_intro_run_id:
			return
		encounter_portrait.texture = load(WHITE_BONE_DISGUISE_TEXTURE_PATHS[i])
		encounter_portrait.modulate = Color.WHITE
		encounter_portrait.scale = Vector2.ONE
		caption.text = form_titles[i]
		caption.modulate.a = 0.0
		var form_reveal := create_tween().set_parallel(true)
		form_reveal.tween_property(caption, "modulate:a", 1.0, 0.20)
		form_reveal.tween_property(encounter_portrait, "scale", Vector2(1.045, 1.045), 0.30).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await form_reveal.finished
		await get_tree().process_frame
		encounter_intro_stage.emit(form_stages[i])
		# 每个幻身完整停留，让玩家真正看清三次变化。
		await get_tree().create_timer(0.82).timeout
		if run_id != _encounter_intro_run_id:
			return
		var residual := _make_white_bone_residual(encounter_portrait.texture, [-92.0, 92.0, 0.0][i])
		residuals.append(residual)
		var cracks := _spawn_white_bone_cracks()
		var break_tween := create_tween().set_parallel(true)
		break_tween.tween_property(encounter_portrait, "modulate", Color(0.64, 0.80, 1.0, 0.0), 0.28)
		break_tween.tween_property(encounter_portrait, "scale", Vector2(1.16, 0.88), 0.28).set_ease(Tween.EASE_IN)
		break_tween.tween_property(caption, "modulate:a", 0.0, 0.18)
		break_tween.tween_property(encounter_theme_tint, "color:a", 0.38, 0.08)
		for crack in cracks:
			break_tween.tween_property(crack, "modulate:a", 1.0, 0.09)
			break_tween.tween_property(crack, "modulate:a", 0.0, 0.20).set_delay(0.10)
		await break_tween.finished
		for crack in cracks:
			crack.queue_free()
		encounter_theme_tint.color.a = 0.0

	if run_id != _encounter_intro_run_id:
		return
	caption.text = "三戏皆破 · 白骨现形"
	caption.modulate.a = 0.0
	encounter_portrait.texture = load(RoundManager.MONSTER_TEXTURE_PATHS[0][2])
	encounter_portrait.modulate = Color(0.74, 0.64, 1.0, 0.0)
	encounter_portrait.scale = Vector2(0.52, 0.52)
	var center: Vector2 = encounter_portrait.position + encounter_portrait.size * 0.5
	var merge := create_tween().set_parallel(true)
	for residual in residuals:
		merge.tween_property(residual, "position", center, 0.46).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		merge.tween_property(residual, "scale", residual.scale * 0.38, 0.46).set_ease(Tween.EASE_IN)
		merge.tween_property(residual, "modulate:a", 0.0, 0.46)
	merge.tween_property(encounter_theme_tint, "color", Color(0.48, 0.18, 1.0, 0.46), 0.34)
	await merge.finished
	for residual in residuals:
		residual.queue_free()
	var true_form := create_tween().set_parallel(true)
	true_form.tween_property(encounter_portrait, "modulate", Color.WHITE, 0.30)
	true_form.tween_property(encounter_portrait, "scale", Vector2(1.18, 1.18), 0.44).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	true_form.tween_property(caption, "modulate:a", 1.0, 0.22)
	true_form.tween_property(encounter_theme_tint, "color:a", 0.0, 0.42).set_delay(0.12)
	await true_form.finished
	await get_tree().process_frame
	encounter_intro_stage.emit("boss_white_bone_true_form")
	await get_tree().create_timer(0.62).timeout
	var caption_release := create_tween().set_parallel(true)
	caption_release.tween_property(caption, "modulate:a", 0.0, 0.18)
	caption_release.tween_property(encounter_portrait, "scale", Vector2(1.10, 1.10), 0.22)
	await caption_release.finished
	caption.queue_free()

func _make_white_bone_residual(texture: Texture2D, horizontal_offset: float) -> Sprite2D:
	var residual := Sprite2D.new()
	residual.texture = texture
	residual.centered = true
	residual.position = encounter_portrait.position + encounter_portrait.size * 0.5 + Vector2(horizontal_offset, 0.0)
	var fit_scale := minf(encounter_portrait.size.x / float(texture.get_width()), encounter_portrait.size.y / float(texture.get_height()))
	residual.scale = Vector2.ONE * fit_scale * 0.78
	residual.modulate = Color(0.58, 0.44, 1.0, 0.22)
	residual.z_index = 2
	encounter_effect_layer.add_child(residual)
	return residual

func _spawn_white_bone_cracks() -> Array[Line2D]:
	var cracks: Array[Line2D] = []
	var crack_center: Vector2 = encounter_portrait.position + encounter_portrait.size * Vector2(0.50, 0.43)
	for i in range(8):
		var angle := TAU * float(i) / 8.0 + 0.18
		var inner: Vector2 = crack_center + Vector2(cos(angle), sin(angle)) * 18.0
		var bend: Vector2 = crack_center + Vector2(cos(angle + 0.16), sin(angle + 0.16)) * 70.0
		var outer: Vector2 = crack_center + Vector2(cos(angle), sin(angle)) * 128.0
		var crack := Line2D.new()
		crack.points = PackedVector2Array([inner, bend, outer])
		crack.width = 3.0
		crack.default_color = Color(0.78, 0.90, 1.0, 0.92)
		crack.antialiased = true
		crack.modulate.a = 0.0
		crack.z_index = 4
		encounter_effect_layer.add_child(crack)
		cracks.append(crack)
	return cracks

# 黄风怪与红孩儿的关键动作使用独立绘制帧；这里只切换纹理并做极短淡入淡出，
# 不再通过旋转、位移或挤压待机立绘来模拟动作。
func _play_yellow_wind_frame_intro(run_id: int):
	encounter_intro_stage.emit("boss_yellow_wind_storm")
	encounter_intro.set_meta("action_frame_mode", "static_texture_switch")
	var caption := _spawn_encounter_label("", Vector2(40.0, size.y * 0.465), Vector2(size.x - 80.0, 52.0), Color(1.0, 0.78, 0.30, 1.0), 21)
	caption.z_index = 8
	caption.modulate.a = 0.0
	await _show_static_boss_action_frame(
		YELLOW_WIND_ACTION_TEXTURE_PATHS[0], "聚风蓄势", "yellow_wind_charge",
		Color(0.94, 0.60, 0.14, 0.16), caption, run_id, 1.00
	)
	if run_id != _encounter_intro_run_id:
		return
	await _show_static_boss_action_frame(
		YELLOW_WIND_ACTION_TEXTURE_PATHS[1], "张口一吹 · 三昧神风", "yellow_wind_breath",
		Color(0.94, 0.53, 0.12, 0.23), caption, run_id, 1.10
	)
	if run_id != _encounter_intro_run_id:
		return
	await _restore_static_boss_idle_frame(RoundManager.MONSTER_TEXTURE_PATHS[1][2], caption, run_id)

func _play_holy_fire_frame_intro(run_id: int):
	encounter_intro_stage.emit("boss_holy_fire_burst")
	encounter_intro.set_meta("action_frame_mode", "static_texture_switch")
	var caption := _spawn_encounter_label("", Vector2(36.0, size.y * 0.465), Vector2(size.x - 72.0, 52.0), Color(1.0, 0.73, 0.22, 1.0), 21)
	caption.z_index = 8
	caption.modulate.a = 0.0
	await _show_static_boss_action_frame(
		HOLY_FIRE_ACTION_TEXTURE_PATHS[0], "火尖枪 · 烈焰横扫", "holy_fire_spear_sweep",
		Color(1.0, 0.10, 0.015, 0.19), caption, run_id, 1.00
	)
	if run_id != _encounter_intro_run_id:
		return
	await _show_static_boss_action_frame(
		HOLY_FIRE_ACTION_TEXTURE_PATHS[1], "三昧真火 · 封住牌路", "holy_fire_true_fire",
		Color(1.0, 0.06, 0.01, 0.27), caption, run_id, 1.10
	)
	if run_id != _encounter_intro_run_id:
		return
	await _restore_static_boss_idle_frame(RoundManager.MONSTER_TEXTURE_PATHS[2][2], caption, run_id)

func _show_static_boss_action_frame(texture_path: String, caption_text: String, stage: String, tint: Color, caption: Label, run_id: int, hold_seconds: float):
	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(encounter_portrait, "modulate:a", 0.0, 0.10)
	fade_out.tween_property(caption, "modulate:a", 0.0, 0.08)
	await fade_out.finished
	if run_id != _encounter_intro_run_id:
		return
	encounter_portrait.texture = load(texture_path)
	# 所有动作帧共用完全相同的容器变换，播放过程不改变位置、角度或尺寸。
	encounter_portrait.rotation = 0.0
	encounter_portrait.scale = Vector2(1.10, 1.10)
	encounter_portrait.modulate = Color(1.0, 1.0, 1.0, 0.0)
	caption.text = caption_text
	encounter_theme_tint.color = tint
	var fade_in := create_tween().set_parallel(true)
	fade_in.tween_property(encounter_portrait, "modulate:a", 1.0, 0.14)
	fade_in.tween_property(caption, "modulate:a", 1.0, 0.14)
	await fade_in.finished
	if run_id != _encounter_intro_run_id:
		return
	encounter_intro.set_meta("last_static_action_frame", texture_path)
	await get_tree().process_frame
	encounter_intro_stage.emit(stage)
	await get_tree().create_timer(hold_seconds).timeout

func _restore_static_boss_idle_frame(texture_path: String, caption: Label, run_id: int):
	var fade_out := create_tween().set_parallel(true)
	fade_out.tween_property(encounter_portrait, "modulate:a", 0.0, 0.10)
	fade_out.tween_property(caption, "modulate:a", 0.0, 0.10)
	await fade_out.finished
	if run_id != _encounter_intro_run_id:
		return
	encounter_portrait.texture = load(texture_path)
	encounter_portrait.rotation = 0.0
	encounter_portrait.scale = Vector2(1.10, 1.10)
	encounter_portrait.modulate = Color.WHITE
	encounter_theme_tint.color.a = 0.0
	caption.queue_free()

func _spawn_encounter_label(text_value: String, at: Vector2, label_size: Vector2, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = at
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.015, 0.01, 0.98))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	encounter_effect_layer.add_child(label)
	return label

func _clear_encounter_effects():
	for child in encounter_effect_layer.get_children():
		encounter_effect_layer.remove_child(child)
		child.queue_free()

func _clear_encounter_preview():
	for child in encounter_effect_preview.get_children():
		encounter_effect_preview.remove_child(child)
		child.queue_free()

func _make_encounter_preview_tile(text_value: String, is_target: bool, accent: Color) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(55.0, 52.0)
	tile.set_meta("effect_target", is_target)
	var tile_style := StyleBoxFlat.new()
	tile_style.bg_color = Color(0.055, 0.06, 0.085, 0.96)
	tile_style.border_color = Color(accent.r, accent.g, accent.b, 0.92 if is_target else 0.28)
	tile_style.set_border_width_all(2 if is_target else 1)
	tile_style.set_corner_radius_all(7)
	tile_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.36 if is_target else 0.0)
	tile_style.shadow_size = 5 if is_target else 0
	tile.add_theme_stylebox_override("panel", tile_style)
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", accent if is_target else Color(0.68, 0.68, 0.72, 1.0))
	tile.add_child(label)
	encounter_effect_preview.add_child(tile)
	return tile

func _build_encounter_effect_preview(round_index: int, blind_index: int):
	_clear_encounter_preview()
	var card_faces := ["♠A", "♥K", "♣Q", "♦J", "♠10"]
	if blind_index == 1 and round_index == 2:
		_make_encounter_preview_tile("首击\n-25%", true, Color("ff6a36"))
		_make_encounter_preview_tile("后续\n正常", false, Color("e9c27a"))
		return
	if blind_index == 2 and round_index == 2:
		var allowed_names := BossSkillManager.get_allowed_hand_names()
		for allowed_name in allowed_names:
			_make_encounter_preview_tile("%s\n可破阵" % allowed_name, true, Color("ffba3d"))
		_make_encounter_preview_tile("其余\n封印", false, Color("7b3930"))
		return
	var target_count := 1
	if blind_index == 2:
		target_count = 2 if round_index == 0 else 3
	for i in range(card_faces.size()):
		var targeted := i < target_count
		var text_value: String = card_faces[i]
		var accent := Color("8bd3ff")
		if targeted:
			if round_index == 0:
				text_value = "锁" if blind_index == 1 else "幻"
				accent = Color("b7d8ff")
			else:
				text_value = "?"
				accent = Color("e8a83d")
		_make_encounter_preview_tile(text_value, targeted, accent)

func _animate_encounter_effect_preview():
	var targets: Array[Control] = []
	for child in encounter_effect_preview.get_children():
		if child.get_meta("effect_target", false):
			targets.append(child)
	if targets.is_empty():
		encounter_intro_stage.emit("debuff_applied")
		return
	var tween := create_tween().set_parallel(true)
	for i in range(targets.size()):
		var tile := targets[i]
		tile.pivot_offset = tile.size * 0.5
		tile.scale = Vector2(0.82, 0.82)
		tween.tween_property(tile, "scale", Vector2(1.18, 1.18), 0.24).set_delay(i * 0.08).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(tile, "modulate", Color(1.35, 0.82, 0.62, 1.0), 0.18).set_delay(i * 0.08)
	await tween.finished
	encounter_intro.set_meta("effect_preview_ready", true)
	encounter_intro_stage.emit("debuff_applied")

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
	var background_path := RoundManager.get_current_battle_background_path()
	if background_path != _last_battle_background_path:
		battle_background.texture = load(background_path)
		_last_battle_background_path = background_path
		_style_battle_regions(RoundManager.current_round)
	if backdrop.has_method("set_battle_theme"):
		backdrop.set_battle_theme(RoundManager.current_round)
	round_label.text  = "%s\n%s" % [RoundManager.get_current_stage_label(), RoundManager.get_current_blind_name()]
	var texture_path = RoundManager.get_current_monster_texture_path()
	var is_enraged = RoundManager.is_current_boss_enraged()
	if backdrop.has_method("set_battle_enraged"):
		backdrop.set_battle_enraged(is_enraged)
	battle_background.modulate = Color(1.18, 0.62, 0.52, 1.0) if is_enraged else Color(1.0, 1.0, 1.0, 0.96)
	if is_enraged and not _was_boss_enraged and _last_monster_texture_path != "":
		_enrage_transition_pending = true
	var monster_texture = load(texture_path)
	monster_avatar.texture = monster_texture
	monster_glow.texture = monster_texture
	monster_title.text = RoundManager.get_current_blind_name()
	monster_title.visible = false
	boss_phase_badge.visible = false
	boss_phase_badge.text = ""
	monster_glow.modulate = Color(1.0, 0.18, 0.08, 0.24) if is_enraged else Color(0.95, 0.55, 0.20, 0.12)
	round_turn_label.text = "第%d轮 · 第%d回合" % [RoundManager.current_round + 1, RoundManager.current_blind + 1]
	_last_monster_texture_path = texture_path
	_was_boss_enraged = is_enraged
	coins_label.text  = "💎 %d" % RoundManager.game_coins
	total_score_label.text = "总伤 %d" % RoundManager.total_score

	# v3.1: 怪物名+技能提示
	var skill_text = RoundManager.get_current_enemy_skill_text()
	if skill_text != "":
		boss_skill_label.text = skill_text
		if skill_text.find("已克制") != -1:
			boss_skill_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1))
		elif skill_text.find("大妖 ·") != -1:
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
	_set_discard_button_action()

	var threshold = RoundManager.get_current_threshold()
	var hp_left = RoundManager.get_current_monster_health()
	score_label.text     = "%s  %d/%d" % [RoundManager.get_current_blind_name(), hp_left, threshold]
	threshold_label.text = RoundManager.get_current_blind_name()
	round_score_detail.text = "已造成 %d 伤害" % RoundManager.round_score
	progress_bar.max_value = threshold
	progress_bar.value     = hp_left

	play_button.disabled    = plays <= 0
	discard_button.disabled = discards <= 0
	play_button.get_node("ActionContent").modulate = Color.WHITE if plays > 0 else Color(0.62, 0.62, 0.62, 0.62)
	discard_button.get_node("ActionContent").modulate = Color.WHITE if discards > 0 else Color(0.62, 0.62, 0.62, 0.62)

func _on_score_updated(_rs: int, _ts: int):
	# 分数模型可以先完成结算，但血条必须等金箍棒真正命中后才刷新。
	if _damage_visual_transaction:
		_pending_health_refresh = true
		return
	_update_ui()
	_pulse_monster_health()

func _pulse_monster_health():
	var pulse = create_tween()
	score_label.pivot_offset = score_label.size * 0.5
	pulse.tween_property(score_label, "scale", Vector2(1.18, 1.18), 0.08).set_ease(Tween.EASE_OUT)
	pulse.tween_property(score_label, "scale", Vector2.ONE, 0.13).set_ease(Tween.EASE_IN)

func _begin_damage_visual_transaction():
	_damage_visual_transaction = true
	_pending_health_refresh = false

func _commit_damage_visual_transaction():
	if not _damage_visual_transaction:
		return
	_damage_visual_transaction = false
	if not _pending_health_refresh:
		return
	_pending_health_refresh = false
	var previous_hp: float = progress_bar.value
	_update_ui()
	var target_hp: float = progress_bar.value
	progress_bar.value = previous_hp
	var hp_tween = create_tween()
	hp_tween.tween_property(progress_bar, "value", target_hp, 0.24).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_pulse_monster_health()

# ════════════════════════════════════════════════════════════════
# 参数面板（实时预览）
# ════════════════════════════════════════════════════════════════
func _update_params_panel(hand_result: Dictionary = {}):
	_base_score_preview = hand_result.get("base_chips", 0) + hand_result.get("card_chips", 0)
	var active_items = ItemManager.get_active_round_consumables().duplicate()
	active_items.append_array(_used_consumable_items)
	var params = ScoreCalculator.preview_params(
		hand_result,
		ItemManager.get_active_joker_states(),
		active_items,
		DeckManager.hand
	)
	_apply_params_to_labels(
		params.get("mult",      1.0),
		params.get("crit_rate", 0.0),
		params.get("crit_mult", 2.0),
		params.get("special_mult", 1.0),
		params.get("special_mult_prob", -1.0)
	)
	return params

func _apply_params_to_labels(mult: float, cr: float, cm: float, sm: float = 1.0, sm_prob: float = -1.0):
	mult_label.text      = "伤害 %d  ×  倍率 %.2f" % [_base_score_preview, mult]
	crit_rate_label.text = "暴击 %d%%" % int(cr * 100)
	crit_mult_label.text = "暴击时 ×%.1f" % cm
	if sm > 1.01:
		var prob_str = " (%d%%概率)" % int(sm_prob * 100) if sm_prob >= 0.0 else ""
		crit_mult_label.text += "\n🎭 ×%.0f%s" % [sm, prob_str]

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
	_layout_hand_cards(false)
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
	_layout_hand_cards(false)
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
	btn.custom_minimum_size = HAND_CARD_SIZE
	btn.size = HAND_CARD_SIZE
	btn.pivot_offset = HAND_CARD_SIZE * 0.5
	btn.text = ""
	btn.set_meta("card_face_v2", true)
	_create_card_face(btn)

	# v3.1: 精英怪/大妖技能视觉特效
	var is_locked = not BossSkillManager.is_card_selectable(idx, DeckManager.hand)
	var is_hidden = not BossSkillManager.is_card_visible(idx)
	btn.set_meta("is_hidden", is_hidden)
	btn.set_meta("is_locked", is_locked)
	if is_hidden:
		btn.tooltip_text = "此牌被遮挡，无法查看"
	elif is_locked:
		btn.tooltip_text = "此牌被锁定，不可选中"
	_apply_card_style(btn, Color(0.42, 0.44, 0.48, 1) if is_hidden or is_locked else sc, false)
	_set_card_face_state(btn, card, is_hidden, is_locked, false)

	var i = idx
	btn.pressed.connect(func(): _on_card_pressed(i))
	return btn

func _create_card_face(btn: Button):
	var selection_glow = ColorRect.new()
	selection_glow.name = "SelectionGlow"
	selection_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selection_glow.offset_left = 3
	selection_glow.offset_top = 3
	selection_glow.offset_right = -3
	selection_glow.offset_bottom = -3
	selection_glow.color = Color.TRANSPARENT
	selection_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(selection_glow)
	var rail = ColorRect.new()
	rail.name = "SuitRail"
	rail.anchor_bottom = 1.0
	rail.offset_left = 4
	rail.offset_top = 9
	rail.offset_right = 8
	rail.offset_bottom = -9
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(rail)
	_add_card_face_label(btn, "RankLabel", Rect2(0.12, 0.05, 0.46, 0.24), 23, 0)
	_add_card_face_label(btn, "SuitLabel", Rect2(0.12, 0.26, 0.40, 0.22), 19, 0)
	_add_card_face_label(btn, "PipLabel", Rect2(0.20, 0.31, 0.64, 0.44), 36, 1)
	_add_card_face_label(btn, "CornerLabel", Rect2(0.52, 0.72, 0.35, 0.22), 17, 2)
	# 状态标记固定在叠牌后仍会露出的左下角，选中牌无需置顶也能看清。
	_add_card_face_label(btn, "StateLabel", Rect2(0.08, 0.75, 0.34, 0.19), 13, 0)

func _add_card_face_label(btn: Button, node_name: String, rect: Rect2, font_size: int, alignment: int):
	var label = Label.new()
	label.name = node_name
	label.anchor_left = rect.position.x
	label.anchor_top = rect.position.y
	label.anchor_right = rect.position.x + rect.size.x
	label.anchor_bottom = rect.position.y + rect.size.y
	label.horizontal_alignment = alignment
	label.vertical_alignment = 1
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(label)

func _set_card_face_state(btn: Button, card, is_hidden: bool, is_locked: bool, selected: bool):
	var sc: Color = SUIT_COLORS[card.suit]
	var face_color := Color(0.48, 0.50, 0.54, 0.72) if is_locked or is_hidden else sc
	var rank_label: Label = btn.get_node("RankLabel")
	var suit_label: Label = btn.get_node("SuitLabel")
	var pip_label: Label = btn.get_node("PipLabel")
	var corner_label: Label = btn.get_node("CornerLabel")
	var state_label: Label = btn.get_node("StateLabel")
	var rail: ColorRect = btn.get_node("SuitRail")
	var selection_glow: ColorRect = btn.get_node("SelectionGlow")
	if is_hidden:
		rank_label.text = "?"
		suit_label.text = ""
		pip_label.text = "?"
		corner_label.text = ""
		state_label.text = "暗"
	elif is_locked:
		rank_label.text = card.get_rank_name()
		suit_label.text = SUIT_SYMBOLS[card.suit]
		pip_label.text = SUIT_SYMBOLS[card.suit]
		corner_label.text = card.get_rank_name()
		state_label.text = "封"
	else:
		rank_label.text = card.get_rank_name()
		suit_label.text = SUIT_SYMBOLS[card.suit]
		pip_label.text = SUIT_SYMBOLS[card.suit]
		corner_label.text = card.get_rank_name()
		state_label.text = "✓" if selected else ""
	for label in [rank_label, suit_label, corner_label]:
		label.add_theme_color_override("font_color", face_color.darkened(0.10) if selected else face_color)
	var watermark = face_color
	watermark.a = 0.38 if selected else 0.20
	pip_label.add_theme_color_override("font_color", watermark)
	state_label.add_theme_color_override("font_color", GameTheme.COLOR_GOLD if selected else Color(0.58, 0.58, 0.62, 0.85))
	state_label.add_theme_color_override("font_outline_color", Color(0.22, 0.10, 0.01, 0.96))
	state_label.add_theme_constant_override("outline_size", 3 if selected else 0)
	rail.color = GameTheme.COLOR_GOLD if selected else face_color
	selection_glow.color = Color(1.0, 0.68, 0.12, 0.16) if selected else Color.TRANSPARENT

func _layout_hand_cards(animated: bool = true):
	var count := _card_nodes.size()
	if count == 0 or hand_area.size.x <= 1.0:
		return
	var exposed_step := HAND_CARD_SIZE.x
	if count > 1:
		exposed_step = clampf((hand_area.size.x - HAND_CARD_SIZE.x) / float(count - 1), 34.0, 52.0)
	var total_width := HAND_CARD_SIZE.x + exposed_step * float(count - 1)
	var start_x := maxf(0.0, (hand_area.size.x - total_width) * 0.5)
	var middle := float(count - 1) * 0.5
	# 手牌保持稳定扇形；选中只改变描边、光晕和标记，不改变位置或叠放层级。
	# 始终让右侧牌压住左侧牌，确保任何一张选中后都不会遮挡后续牌的点击区域。
	var base_y := maxf(45.0, (hand_area.size.y - HAND_CARD_SIZE.y) * 0.5)
	for i in range(count):
		var btn: Button = _card_nodes[i]
		var fan_distance := absf(float(i) - middle)
		var target := Vector2(start_x + exposed_step * i, base_y + fan_distance * 1.4)
		var target_rotation := deg_to_rad((float(i) - middle) * 1.7)
		btn.z_index = i
		btn.scale = Vector2.ONE
		if animated:
			var tw = create_tween().set_parallel()
			tw.tween_property(btn, "position", target, 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tw.tween_property(btn, "rotation", target_rotation, 0.14).set_ease(Tween.EASE_OUT)
		else:
			btn.position = target
			btn.rotation = target_rotation

func _apply_card_style(btn: Button, sc: Color, selected: bool):
	var normal = StyleBoxFlat.new()
	var is_hidden: bool = btn.get_meta("is_hidden", false)
	normal.bg_color = Color("1b2946") if is_hidden else (Color("fff4cf") if selected else Color("f8f1df"))
	normal.border_color = Color("8ea0c7") if is_hidden else (BATTLE_GOLD_BRIGHT if selected else Color("b8a783"))
	normal.set_border_width_all(4 if selected else 2)
	normal.border_width_bottom = 5 if selected else 3
	normal.set_corner_radius_all(10)
	normal.shadow_color = Color(0.94, 0.68, 0.22, 0.50) if selected else Color(0.01, 0.01, 0.02, 0.48)
	normal.shadow_size = 8 if selected else 5
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.07)
	hover.border_color = Color("fff08c") if selected else sc
	hover.shadow_size += 3
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.05)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _on_card_pressed(idx: int):
	# v3.1: 被锁定的牌不可选中（骷髅将/白骨幻术）
	# 翻面的牌（小旋风/风沙走石）可以选中但看不到内容
	if not BossSkillManager.is_card_selectable(idx, DeckManager.hand):
		return
	if _selected_indices.has(idx): _selected_indices.erase(idx)
	elif _selected_indices.size() < 5: _selected_indices.append(idx)
	_update_card_visuals()
	_update_hand_name_label()
	if idx >= 0 and idx < _card_nodes.size():
		var card_btn = _card_nodes[idx]
		# 原位闪光确认，不做上浮或缩放弹跳。
		card_btn.scale = Vector2.ONE
		card_btn.modulate = Color(1.13, 1.06, 0.78, 1.0) if _selected_indices.has(idx) else Color(0.86, 0.93, 1.08, 1.0)
		var flash = create_tween()
		flash.tween_property(card_btn, "modulate", Color.WHITE, 0.16).set_ease(Tween.EASE_OUT)

func _update_card_visuals():
	for i in range(_card_nodes.size()):
		var btn = _card_nodes[i]
		var card = DeckManager.hand[i]
		var sc = SUIT_COLORS[card.suit]

		# v3.1: 被锁定/遮挡的牌保持特殊视觉
		var is_locked = not BossSkillManager.is_card_selectable(i, DeckManager.hand)
		var is_hidden = not BossSkillManager.is_card_visible(i)

		if is_hidden:
			btn.set_meta("is_hidden", true)
			btn.set_meta("is_locked", false)
			_apply_card_style(btn, Color(0.3, 0.3, 0.3, 1), false)
			_set_card_face_state(btn, card, true, false, false)
			continue
		elif is_locked:
			btn.set_meta("is_hidden", false)
			btn.set_meta("is_locked", true)
			_apply_card_style(btn, Color(0.5, 0.5, 0.5, 0.6), false)
			_set_card_face_state(btn, card, false, true, false)
			continue

		var sel = _selected_indices.has(i)
		btn.set_meta("selected_card", sel)
		btn.set_meta("is_hidden", false)
		btn.set_meta("is_locked", false)
		_apply_card_style(btn, sc, sel)
		_set_card_face_state(btn, card, false, false, sel)
	_layout_hand_cards(true)
	_update_played_preview()

func _update_hand_name_label():
	# 手牌区不再放独立状态框，选牌反馈统一收进出牌按钮副标题。
	_base_score_preview = 0
	if _selected_indices.size() == 5:
		var sel_cards = []; for idx in _selected_indices: sel_cards.append(DeckManager.hand[idx])
		var result = HandEvaluator.evaluate(sel_cards)
		var has_hidden := false
		for idx in _selected_indices:
			if not BossSkillManager.is_card_visible(idx):
				has_hidden = true
				break
		var allowed = BossSkillManager.is_hand_rank_allowed(result.rank)
		if has_hidden:
			_set_play_button_action("盲打出牌")
		elif allowed:
			_set_play_button_action("打出 %s" % result.hand_name)
		else:
			_set_play_button_action("该牌型被阻挡")
	elif _selected_indices.size() > 0:
		_set_play_button_action("已选 %d/5 · 还需 %d 张" % [_selected_indices.size(), 5 - _selected_indices.size()])
	else:
		_set_play_button_action("选择 5 张牌")
	_set_discard_button_action()

func _set_play_button_action(action_text: String):
	play_count_label.text = "出牌 ×%d" % RoundManager.plays_left
	play_action_label.text = action_text
	play_button.tooltip_text = "剩余出牌 %d 次 · %s" % [RoundManager.plays_left, action_text]

func _set_discard_button_action():
	var action_text := "选择卡牌"
	if not _selected_indices.is_empty():
		action_text = "换掉 %d 张" % _selected_indices.size()
	discard_count_label.text = "换牌 ×%d" % RoundManager.discards_left
	discard_action_label.text = action_text
	discard_button.tooltip_text = "剩余换牌 %d 次 · %s" % [RoundManager.discards_left, action_text]

func _update_played_preview():
	for child in played_area.get_children():
		child.queue_free()
	# 选牌阶段只让手牌原位高亮；伤害区直到真正出牌时才展开。
	monster_avatar.visible = true
	monster_glow.visible = true
	monster_title.visible = false
	boss_phase_badge.visible = false
	table_hint_label.visible = false
	attack_stick_button.visible = true
	_set_damage_zone_visible(false)

func _make_table_card(card, idx: int = -1) -> Button:
	var is_hidden = (idx >= 0 and not BossSkillManager.is_card_visible(idx))
	var sc = SUIT_COLORS[card.suit]
	var btn = Button.new()
	btn.disabled = true
	btn.custom_minimum_size = TABLE_CARD_SIZE
	btn.size = TABLE_CARD_SIZE
	if is_hidden:
		btn.text = "?\n?"
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		var style = GameTheme.get_card_style(Color(0.4, 0.4, 0.4, 1), false)
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		btn.add_theme_stylebox_override("disabled", style)
		btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 1))
		btn.tooltip_text = "此牌被遮挡，无法查看"
	else:
		btn.text = "%s\n%s" % [card.get_rank_name(), SUIT_SYMBOLS[card.suit]]
		btn.add_theme_font_size_override("font_size", 15)
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
	for joker in ItemManager.jokers:
		var badge = _make_joker_badge(joker)
		joker_slots.add_child(badge)
		_joker_badge_nodes.append(badge)
	for _slot_index in range(maxi(0, ARTIFACT_SLOT_COUNT - ItemManager.jokers.size())):
		joker_slots.add_child(_make_empty_wood_slot(ARTIFACT_SLOT_SIZE))
	artifact_bar_label.text = "法宝 %d/%d" % [mini(ItemManager.jokers.size(), ARTIFACT_SLOT_COUNT), ARTIFACT_SLOT_COUNT]

func _make_joker_badge(joker) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = ARTIFACT_SLOT_SIZE
	_style_wood_slot_button(btn)
	btn.tooltip_text = "%s · Lv%d%s\n%s" % [
		joker.resource_data.get("display_name", "法宝"), joker.level,
		" · 临时" if joker.is_temporary else "",
		joker.resource_data.get("description", "")]
	var art = TextureRect.new()
	btn.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 2; art.offset_top = 2; art.offset_right = -2; art.offset_bottom = -2
	art.texture = ItemManager.get_artifact_texture(joker)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var j = joker
	btn.pressed.connect(func(): _show_joker_detail(j))
	btn.mouse_entered.connect(func(): _pulse_icon(btn, Vector2(1.12, 1.12)))
	btn.mouse_exited.connect(func(): _pulse_icon(btn, Vector2.ONE))
	return btn

func _pulse_icon(icon_button: Control, target_scale: Vector2):
	icon_button.pivot_offset = icon_button.size * 0.5
	var tw = create_tween()
	tw.tween_property(icon_button, "scale", target_scale, 0.10).set_ease(Tween.EASE_OUT)

# ── 法宝详情弹窗 ──────────────────────────────────────────
func _show_attack_info():
	_detail_consumable = null
	joker_detail_use.visible = false
	_set_detail_panel_bounds(0.08, 0.92)
	joker_detail_title.text = "如意金箍棒 · 攻击信息"
	var battle_entries := _get_current_battle_play_entries()
	joker_detail_level.text = "本场已出牌 %d 次" % battle_entries.size()
	joker_detail_desc.text = "伤害只在金箍棒命中后扣除。选牌阶段不预估伤害；每次真实结算公式记录在下方。"
	for child in joker_detail_params.get_children():
		child.queue_free()

	var active_items = ItemManager.get_active_round_consumables().duplicate()
	var params = ScoreCalculator.preview_params({}, ItemManager.get_active_joker_states(), active_items, DeckManager.hand)
	_add_param_row("常驻暴击率", "%d%%" % int(params.get("crit_rate", 0.05) * 100), GameTheme.COLOR_GOLD, true)
	_add_param_row("暴击倍数", "×%.1f" % params.get("crit_mult", 2.0), GameTheme.COLOR_CRIT, true)
	_add_param_row("常驻倍率加成", "+%.2f" % maxf(0.0, float(params.get("mult", 1.0)) - 1.0), GameTheme.COLOR_BLUE_CHIP, true)

	var detail_separator = HSeparator.new()
	joker_detail_params.add_child(detail_separator)
	var detail_title = Label.new()
	detail_title.text = "本场出牌伤害记录"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_title.add_theme_font_size_override("font_size", 14)
	detail_title.add_theme_color_override("font_color", GameTheme.COLOR_ACCENT)
	joker_detail_params.add_child(detail_title)
	if battle_entries.is_empty():
		_add_param_row("尚未出牌", "命中妖怪后会记录实际公式", GameTheme.COLOR_TEXT_DIM, true)
	else:
		for entry in battle_entries:
			var play_number := int(entry.get("play_idx", 0)) + 1
			var is_crit := bool(entry.get("is_crit", entry.get("snapshot", {}).get("is_crit", false)))
			_add_param_row(
				"第%d次 · %s" % [play_number, entry.get("hand_name", "牌型")],
				_format_play_formula(entry),
				GameTheme.COLOR_CRIT if is_crit else GameTheme.COLOR_GOLD,
				true
			)
			var bonus_sources := _format_play_bonus_sources(entry)
			if bonus_sources != "":
				_add_param_row("加成来源", bonus_sources, GameTheme.COLOR_JOKER, true)

	var separator = HSeparator.new()
	joker_detail_params.add_child(separator)
	var rule_title = Label.new()
	rule_title.text = "牌型计分表"
	rule_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule_title.add_theme_font_size_override("font_size", 14)
	rule_title.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	joker_detail_params.add_child(rule_title)
	for rank in range(9):
		_add_param_row(
			HandEvaluator.HAND_NAMES[rank],
			"基础伤害 %d  ·  ×%d" % [HandEvaluator.BASE_CHIPS[rank], HandEvaluator.BASE_MULTS[rank]],
			GameTheme.COLOR_TEXT_MAIN,
			true
		)
	joker_detail_overlay.visible = true

func _get_current_battle_play_entries() -> Array:
	return RoundManager.play_log.filter(func(entry):
		return int(entry.get("round", -1)) == RoundManager.current_round \
			and int(entry.get("blind", -1)) == RoundManager.current_blind
	)

func _format_play_formula(entry: Dictionary) -> String:
	var snapshot: Dictionary = entry.get("snapshot", {})
	var base_chips := int(snapshot.get("base_chips", 0))
	var card_chips := int(snapshot.get("card_chips", 0))
	var chips := int(entry.get("chips", snapshot.get("chips", base_chips + card_chips)))
	var chip_bonus := chips - base_chips - card_chips
	var mult := float(entry.get("mult", snapshot.get("mult", 1.0)))
	var special_mult := float(entry.get("special_mult", snapshot.get("special_mult", 1.0)))
	var is_crit := bool(entry.get("is_crit", snapshot.get("is_crit", false)))
	var crit_mult := float(entry.get("crit_mult", snapshot.get("crit_mult", 2.0))) if is_crit else 1.0
	var claimed := int(entry.get("claimed", 0))
	var formula := "(%d + %d" % [base_chips, card_chips]
	if chip_bonus != 0:
		formula += " %+d" % chip_bonus
	formula += ") × %.2f" % mult
	if not is_equal_approx(special_mult, 1.0):
		formula += " × %.2f" % special_mult
	if is_crit:
		formula += " × %.1f暴击" % crit_mult
	var raw_damage := float(chips) * mult * special_mult * crit_mult
	if bool(entry.get("blocked_by_boss", false)):
		formula += " × 0阻挡"
	elif roundi(raw_damage) != claimed and raw_damage > 0.0:
		formula += " × %.2f" % (float(claimed) / raw_damage)
	return "%s = %d" % [formula, claimed]

func _format_play_bonus_sources(entry: Dictionary) -> String:
	var sources: Array[String] = []
	for step in entry.get("steps", []):
		if step.get("type", "") == "base":
			continue
		var description := _describe_score_delta(step.get("delta", {}))
		if step.get("type", "") == "boss_block":
			description = "伤害归零"
		sources.append("%s：%s" % [step.get("label", "效果"), description])
	return "；".join(sources)

func _describe_score_delta(delta: Dictionary) -> String:
	var parts: Array[String] = []
	if delta.get("chip_add", 0.0) != 0.0:
		parts.append("伤害%+d" % int(delta.get("chip_add", 0.0)))
	if delta.get("mult_add", 0.0) != 0.0:
		parts.append("倍率%+.1f" % float(delta.get("mult_add", 0.0)))
	if delta.get("mult_factor", 1.0) != 1.0:
		parts.append("倍率×%.1f" % float(delta.get("mult_factor", 1.0)))
	if delta.get("crit_rate_add", 0.0) != 0.0:
		parts.append("暴击率%+d%%" % int(float(delta.get("crit_rate_add", 0.0)) * 100.0))
	if delta.get("crit_mult_add", 0.0) != 0.0:
		parts.append("暴击倍率%+.1f" % float(delta.get("crit_mult_add", 0.0)))
	if delta.get("special_mult", 1.0) != 1.0:
		parts.append("特殊×%.2f" % float(delta.get("special_mult", 1.0)))
	return "、".join(parts) if not parts.is_empty() else "状态效果"

func _show_joker_detail(joker):
	_detail_consumable = null
	joker_detail_use.visible = false
	_set_detail_panel_bounds(0.16, 0.84)
	var color    = GameTheme.COLOR_JOKER
	var name_str = joker.resource_data.get("display_name", "?")
	var desc_str = joker.resource_data.get("description", "")

	joker_detail_title.text = "法宝 · %s" % name_str
	joker_detail_level.text = "等级：Lv%d · 临时法宝" % joker.level if joker.is_temporary else "等级：Lv%d / 3" % joker.level
	# 优先使用动态描述（如火眼金睛会反映当前花色和伤害值）
	if joker.has_method("get_dynamic_description"):
		joker_detail_desc.text = joker.get_dynamic_description()
	else:
		joker_detail_desc.text = desc_str

	# 清空旧参数
	for child in joker_detail_params.get_children(): child.queue_free()
	if joker.is_temporary:
		_add_param_row("持续时间", "当前回合结束后消失", GameTheme.COLOR_RARE, true)

	if joker.has_method("get_chain_info"):
		var info = joker.get_chain_info()
		_add_param_row("第一手牌型", info.get("hand_name", "尚未触发"), GameTheme.COLOR_GOLD, info.get("has_chain", false))
		_add_param_row("连锁次数", "%d 次" % info.get("consecutive", 0), GameTheme.COLOR_TEXT_DIM, info.get("consecutive", 0) > 0)
		_add_param_row("提升倍率", "+%.2f" % info.get("current_bonus", 0.0), GameTheme.COLOR_BLUE_CHIP, info.get("current_bonus", 0.0) != 0.0)
		_add_param_row("每次提升", "+%.2f" % info.get("per_stack", 0.0), GameTheme.COLOR_JOKER, true)
	else:
		# 优先用 get_preview_modifiers（确定性，不触发随机）
		var delta = joker.get_preview_modifiers({}) if joker.has_method("get_preview_modifiers") else joker.get_passive_modifiers({})
		var dca   = delta.get("chip_add",      0.0)
		var dm    = delta.get("mult_add",      0.0)
		var dcr   = delta.get("crit_rate_add",  0.0)
		var dcm   = delta.get("crit_mult_add",  0.0)
		var dsm   = delta.get("special_mult",  1.0)
		var dprob = delta.get("special_mult_prob", -1.0)
		var is_per_card = delta.get("_preview_per_card", false)

		# 伤害加成：区分"每张牌 +N"（火眼金睛）和"固定 +N"
		if dca != 0.0:
			var chip_str = "每张匹配牌 +%d" % int(dca) if is_per_card else "+%d" % int(dca)
			_add_param_row("伤害加成", chip_str, Color(0.30, 0.85, 0.50, 1), true)
		_add_param_row("倍率加成",      "+%.2f" % dm,            GameTheme.COLOR_BLUE_CHIP, dm != 0.0)
		_add_param_row("暴击率加成",    "+%d%%" % int(dcr*100),  Color(1.0, 0.72, 0.10, 1), dcr != 0.0)
		_add_param_row("暴击倍数加成",  "+%.1f" % dcm,           Color(1.0, 0.40, 0.10, 1), dcm != 0.0)
		if dsm != 1.0:
			var prob_str = " (%d%%概率)" % int(dprob * 100) if dprob >= 0 else ""
			_add_param_row("特殊倍率", "×%.0f%s" % [dsm, prob_str], GameTheme.COLOR_JOKER, true)

	# 升级后预览（若未满级）
	var cost = joker.get_upgrade_cost()
	if not joker.is_temporary and cost != -1 and joker.level < 3:
		var sep = HSeparator.new(); joker_detail_params.add_child(sep)
		var hint = Label.new()
		hint.text = "升级 Lv%d → Lv%d 需要 💰%d（在商店升级）" % [joker.level, joker.level + 1, cost]
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		joker_detail_params.add_child(hint)

	# 火眼金睛：显示当前随机花色（只读，每回合自动更换）
	if joker.has_method("get_suit_name"):
		var sep2 = HSeparator.new(); joker_detail_params.add_child(sep2)
		var suit_lbl = Label.new()
		suit_lbl.text = "🎲 本回合指定花色：%s（每回合随机更换）" % joker.get_suit_name()
		suit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		suit_lbl.add_theme_font_size_override("font_size", 13)
		suit_lbl.add_theme_color_override("font_color", Color(1.0, 0.70, 0.20, 1))
		suit_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		joker_detail_params.add_child(suit_lbl)

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
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(vl)

# ════════════════════════════════════════════════════════════════
# 冲分道具
# ════════════════════════════════════════════════════════════════
func _rebuild_consumables():
	for child in cons_slots.get_children():
		child.queue_free()
	var item_count := 0
	for active in ItemManager.get_active_round_consumables():
		cons_slots.add_child(_make_consumable_icon(active, true))
		item_count += 1
	for cons in ItemManager.consumables:
		cons_slots.add_child(_make_consumable_icon(cons, false))
		item_count += 1
	for _slot_index in range(maxi(0, CONSUMABLE_SLOT_COUNT - item_count)):
		cons_slots.add_child(_make_empty_wood_slot(CONSUMABLE_SLOT_SIZE))
	consumable_bar_label.text = "道具 %d/%d" % [mini(item_count, CONSUMABLE_SLOT_COUNT), CONSUMABLE_SLOT_COUNT]

func _make_consumable_icon(cons, is_active: bool = false) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = CONSUMABLE_SLOT_SIZE
	_style_wood_slot_button(btn)
	btn.text = ""
	var texture := ItemManager.get_consumable_texture(cons)
	if texture != null:
		var art = TextureRect.new()
		btn.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.offset_left = 2; art.offset_top = 2; art.offset_right = -2; art.offset_bottom = -2
		art.texture = texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		btn.text = ItemManager.get_item_icon(cons)
		btn.add_theme_font_size_override("font_size", 23)
	btn.tooltip_text = "%s\n%s\n%s" % [
		cons.resource_data.get("display_name", "道具"),
		cons.resource_data.get("description", ""),
		"当前持续生效" if is_active else cons.get_use_timing_label()]
	if is_active:
		btn.modulate = Color(0.62, 1.22, 0.90, 1.0)
	elif _used_consumable_items.has(cons):
		btn.modulate = Color(1.30, 1.12, 0.48, 1.0)
		btn.scale = Vector2(1.08, 1.08)
	var captured = cons
	btn.pressed.connect(func(): _show_consumable_detail(captured, is_active))
	btn.mouse_entered.connect(func(): _pulse_icon(btn, Vector2(1.14, 1.14)))
	btn.mouse_exited.connect(func(): _pulse_icon(btn, Vector2(1.08, 1.08) if _used_consumable_items.has(captured) else Vector2.ONE))
	return btn

func _show_consumable_detail(cons, is_active: bool = false):
	_detail_consumable = cons
	_detail_consumable_active = is_active
	_set_detail_panel_bounds(0.22, 0.58)
	var data = cons.resource_data
	joker_detail_title.text = "%s  %s" % [ItemManager.get_item_icon(cons), data.get("display_name", "道具")]
	joker_detail_level.text = "%s · %s" % [
		"稀有" if data.get("rarity", 0) == 1 else "普通", cons.get_use_timing_label()]
	joker_detail_desc.text = data.get("description", "")
	for child in joker_detail_params.get_children(): child.queue_free()
	var mods = cons.get_score_modifiers()
	if mods.get("chip_add", 0) != 0: _add_param_row("伤害加成", "+%d" % int(mods.chip_add), Color(0.3,0.85,0.5,1), true)
	if mods.get("mult_add", 0) != 0: _add_param_row("倍率加成", "+%.1f" % mods.mult_add, GameTheme.COLOR_BLUE_CHIP, true)
	if mods.get("mult_factor", 1) != 1: _add_param_row("倍率乘数", "×%.1f" % mods.mult_factor, GameTheme.COLOR_GOLD, true)
	if mods.get("crit_rate_add", 0) != 0: _add_param_row("暴击率", "+%d%%" % int(mods.crit_rate_add * 100), GameTheme.COLOR_RARE, true)
	if mods.get("crit_mult_add", 0) != 0: _add_param_row("暴击倍率", "+%.1f" % mods.crit_mult_add, GameTheme.COLOR_CRIT, true)
	if mods.get("extra_plays", 0) != 0: _add_param_row("出牌次数", "+%d" % int(mods.extra_plays), GameTheme.COLOR_BLUE_CHIP, true)
	if mods.get("extra_discards", 0) != 0: _add_param_row("换牌次数", "+%d" % int(mods.extra_discards), GameTheme.COLOR_GOLD, true)
	if mods.get("hand_size_add", 0) != 0: _add_param_row("手牌上限", "+%d" % int(mods.hand_size_add), GameTheme.COLOR_ACCENT, true)
	if mods.get("boss_suppress", false): _add_param_row("克制效果", "整场压制对应大妖技能", GameTheme.COLOR_RARE, true)
	var status = "✓ 当前怪物战持续生效" if is_active else ("✓ 当前可使用" if cons.can_use_now() else "暂不可用：%s" % cons.get_unavailable_reason())
	_add_param_row("当前状态", status, GameTheme.COLOR_ACCENT if (is_active or cons.can_use_now()) else GameTheme.COLOR_TEXT_DIM, true)
	joker_detail_use.visible = true
	if is_active:
		joker_detail_use.text = "已持续生效"
		joker_detail_use.disabled = true
	else:
		var timing = cons.get_use_timing()
		joker_detail_use.text = "取消本次使用" if _used_consumable_items.has(cons) else (
			"加入下次出牌" if timing == "next_play" else (
			"激活本场效果" if timing == "round" else (
			"仅可在仙铺使用" if timing == "shop" else "立即使用")))
		joker_detail_use.disabled = not cons.can_use_now()
	joker_detail_overlay.visible = true

func _on_detail_consumable_use():
	if _detail_consumable == null or _detail_consumable_active:
		return
	var cons = _detail_consumable
	_on_consumable_used(cons.resource_data.get("id", ""), cons, null)
	joker_detail_overlay.visible = false

func _set_detail_panel_bounds(top: float, bottom: float):
	joker_detail_panel.anchor_top = top
	joker_detail_panel.anchor_bottom = bottom

func _on_consumable_used(_item_id: String, cons, _panel: Control):
	if not cons.can_use_now():
		_show_tip(cons.get_unavailable_reason(), GameTheme.COLOR_CRIT)
		return
	match cons.get_use_timing():
		"next_play":
			if _used_consumable_items.has(cons):
				_used_consumable_items.erase(cons)
			else:
				_used_consumable_items.append(cons)
		"round":
			var mods = cons.get_score_modifiers()
			if ItemManager.activate_round_consumable(cons):
				if mods.get("boss_suppress", false):
					BossSkillManager.suppress_skill()
					_rebuild_hand()
				_show_tip("%s 已激活，本场战斗持续生效" % cons.resource_data.get("display_name", "道具"), GameTheme.COLOR_ACCENT)
		"instant":
			var outcome = null
			if cons.has_method("apply_special_effect"):
				outcome = cons.apply_special_effect()
			if cons.is_round_wide():
				ItemManager.activate_round_consumable(cons)
			else:
				ItemManager.consume_instance(cons)
			if cons.resource_data.get("id", "") == "cloud_step": _rebuild_hand()
			if outcome is String and outcome != "":
				_rebuild_jokers()
				_show_tip("七十二变化作临时【%s】Lv1，本回合有效！" % outcome, GameTheme.COLOR_JOKER)
			else:
				_show_tip("%s 已生效" % cons.resource_data.get("display_name", "道具"), GameTheme.COLOR_ACCENT)
		"shop":
			_show_tip(cons.get_unavailable_reason(), GameTheme.COLOR_TEXT_DIM)
	_rebuild_consumables()
	_update_ui()
	_update_hand_name_label()
	GameState.save_state()

func _clear_used_consumables():
	_used_consumable_items.clear()

func _get_queued_consumable_ids() -> Array:
	return _used_consumable_items.map(func(c): return c.resource_data.get("id", ""))

# ════════════════════════════════════════════════════════════════
# 出牌 / 换牌
# ════════════════════════════════════════════════════════════════
func _on_play_pressed():
	if _selected_indices.size() != 5:
		_show_tip("请选择 5 张牌！", Color(0.95, 0.35, 0.35, 1)); return
	if RoundManager.plays_left <= 0: return

	play_button.disabled = true; discard_button.disabled = true
	var played_cards = []
	var source_nodes = []
	for idx in _selected_indices:
		played_cards.append(DeckManager.hand[idx])
		source_nodes.append(_card_nodes[idx])

	_begin_damage_visual_transaction()
	var result = await RoundManager.play_hand(
		_selected_indices.duplicate(), _get_queued_consumable_ids()
	)

	# ── 先播完计算过程动画，再推进阶段 ──
	await _show_calc_animation(result, played_cards, source_nodes)

	_clear_used_consumables()
	_rebuild_hand(); _rebuild_consumables(); _update_ui(); _reset_inline_calc()
	play_button.disabled    = RoundManager.plays_left <= 0
	discard_button.disabled = RoundManager.discards_left <= 0

	# 动画结束后由此处推进阶段（blind_cleared / out_of_plays）
	RoundManager.advance_after_play(result)
	GameState.save_state()

func _on_discard_pressed():
	if _selected_indices.is_empty():
		_show_tip("请选择要换掉的牌！", Color(0.95, 0.60, 0.15, 1)); return
	if RoundManager.discards_left <= 0: return
	# 黄风怪的遮挡牌需消耗1次换牌机会翻开；一次只翻1张，不替换手牌。
	if BossSkillManager.current_skill == BossSkillManager.BossSkill.SANDSTORM and not BossSkillManager.skill_suppressed:
		for idx in _selected_indices:
			if not BossSkillManager.is_card_visible(idx):
				if BossSkillManager.reveal_face_down_card(DeckManager.hand[idx]):
					RoundManager.discards_left -= 1
					_selected_indices.clear()
					_rebuild_hand(); _update_ui(); GameState.save_state()
					_show_tip("消耗1次换牌，已吹散一张风沙", GameTheme.COLOR_GOLD)
					return
	RoundManager.discard_cards(_selected_indices.duplicate())
	_rebuild_hand(); _update_ui(); GameState.save_state()

# ════════════════════════════════════════════════════════════════
# 计算过程动画
# ════════════════════════════════════════════════════════════════
func _show_calc_animation(result: Dictionary, played_cards: Array = [], source_nodes: Array = []):
	_set_damage_zone_visible(true)
	var final_score := int(result.get("score", 0))
	_strike_reference_damage = maxf(float(final_score), 1.0)
	_strike_damage_target_scale = _get_stick_target_scale(final_score)
	for child in calc_steps_list.get_children():
		child.queue_free()
	for child in played_area.get_children():
		child.queue_free()
	score_burst_label.text = "0"
	score_burst_label.modulate.a = 1.0
	score_burst_label.scale = Vector2.ONE
	score_burst_label.add_theme_font_size_override("font_size", 46)
	score_burst_label.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	crit_banner.visible = false
	monster_damage_label.visible = false
	strike_stick.visible = false
	strike_stick.modulate = Color.WHITE
	strike_stick.rotation = 0.0
	strike_stick.scale = Vector2.ONE
	strike_stick.pivot_offset = strike_stick.size * 0.5
	strike_stick.set_meta("flight_spin_observed", false)
	strike_stick.set_meta("return_shrink_observed", false)

	# 金箍棒先从武器槽旋转飞到妖怪身旁，抵达后才开始随伤害数字膨胀。
	await _fly_stick_into_battle()

	var steps: Array = result.get("steps", [])
	var snapshot: Dictionary = result.get("snapshot", {})
	var base_step: Dictionary = steps[0] if not steps.is_empty() else {}
	var base_chips := int(snapshot.get("base_chips", 0))
	var running_chips := 0
	await _roll_attack_value(0, base_chips, 0.20, 0.06)
	running_chips = base_chips

	# 手牌依次飞向攻击数字；不再铺开大结算面板或堆叠落地牌。
	for i in range(played_cards.size()):
		var source = source_nodes[i] if i < source_nodes.size() else null
		await _fly_card_to_damage(played_cards[i], source, i, played_cards.size())
		var card_value := int(played_cards[i].get_chip_value())
		var previous := running_chips
		running_chips += card_value
		await _roll_attack_value(previous, running_chips, 0.14, 0.045)
		damage_animation_stage.emit("card_%d" % (i + 1))
		await get_tree().process_frame

	# 伤害加成只推动数字和金箍棒成长，明细统一放在金箍棒详情里。
	for step in steps.slice(1):
		var delta: Dictionary = step.get("delta", {})
		var chip_add := int(delta.get("chip_add", 0.0))
		if chip_add == 0:
			continue
		var previous := running_chips
		running_chips += chip_add
		if step.get("type", "") == "joker":
			await _bounce_joker_by_name(step.get("label", ""))
		await _roll_attack_value(previous, running_chips, 0.20, 0.07)

	var final_chips := int(result.get("chips", snapshot.get("chips", running_chips)))
	if final_chips != running_chips:
		await _roll_attack_value(running_chips, final_chips, 0.18, 0.06)
		running_chips = final_chips
	damage_animation_stage.emit("chips_done")

	# 倍率阶段直接展示“当前攻击值”的增长，不再显示公式或独立倍率框。
	var running_mult := float(base_step.get("mult", 1.0))
	var running_attack := running_chips
	var base_attack := int(running_chips * running_mult)
	if base_attack != running_attack:
		await _roll_attack_value(running_attack, base_attack, 0.24, 0.10)
		running_attack = base_attack
	for step in steps.slice(1):
		var next_mult := float(step.get("mult", running_mult))
		if is_equal_approx(next_mult, running_mult):
			continue
		if step.get("type", "") == "joker":
			await _bounce_joker_by_name(step.get("label", ""))
		var next_attack := int(running_chips * next_mult)
		await _roll_attack_value(running_attack, next_attack, 0.24, 0.10)
		running_attack = next_attack
		running_mult = next_mult

	var special_mult := float(result.get("special_mult", 1.0))
	if special_mult > 1.001:
		for step in steps:
			if step.get("type", "") == "joker" and float(step.get("delta", {}).get("special_mult", 1.0)) > 1.001:
				await _bounce_joker_by_name(step.get("label", ""))
		var next_attack := int(running_attack * special_mult)
		await _roll_attack_value(running_attack, next_attack, 0.30, 0.13)
		running_attack = next_attack
		running_mult *= special_mult

	for step in steps:
		if step.get("type", "") == "elite_nerf":
			var next_attack := int(running_attack * 0.75)
			await _roll_attack_value(running_attack, next_attack, 0.24, 0.04)
			running_attack = next_attack
			break

	var blocked: bool = bool(result.get("blocked_by_boss", false))
	var non_crit_score := 0 if blocked else running_attack
	if blocked:
		await _roll_attack_value(running_attack, 0, 0.22, 0.0)
	damage_animation_stage.emit("mult_done")

	var is_crit := bool(result.get("is_crit", false))
	if blocked:
		crit_banner.text = "三昧真火 · 伤害归零"
		crit_banner.visible = true
		score_burst_label.text = "0"
		score_burst_label.add_theme_color_override("font_color", GameTheme.COLOR_CRIT)
	elif is_crit:
		var crit_mult := float(result.get("crit_mult", 2.0))
		crit_banner.text = "暴击 ×%.1f" % crit_mult
		crit_banner.visible = true
		crit_banner.scale = Vector2(0.35, 0.35)
		crit_banner.modulate.a = 1.0
		var damage_center: Vector2 = score_burst_label.global_position + score_burst_label.size * 0.5
		backdrop.flash(GameTheme.COLOR_CRIT, 0.42)
		backdrop.burst(damage_center, GameTheme.COLOR_CRIT, 60)
		hit_flash.color = Color(1.0, 0.08, 0.02, 0.36)
		score_burst_label.pivot_offset = score_burst_label.size * 0.5
		var explosion = create_tween()
		explosion.tween_property(score_burst_label, "scale", Vector2(1.28, 1.28), 0.11).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		explosion.parallel().tween_property(crit_banner, "scale", Vector2(1.35, 1.35), 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		explosion.tween_property(score_burst_label, "scale", Vector2.ONE, 0.14)
		score_burst_label.add_theme_font_size_override("font_size", 64)
		score_burst_label.add_theme_color_override("font_color", Color("ff291f"))
		await _roll_attack_value(non_crit_score, final_score, 0.36, 0.17)
		damage_animation_stage.emit("critical")
		await get_tree().process_frame
	else:
		score_burst_label.text = "%d" % final_score
		score_burst_label.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)

	await _play_stick_strike(final_score, is_crit, blocked)
	await _impact_feedback(final_score, is_crit, blocked)
	await get_tree().create_timer(0.70).timeout
	_finish_monster_hit_reaction()

func _set_damage_zone_visible(active: bool):
	damage_zone.visible = active
	damage_zone_title.visible = false
	damage_chips_label.visible = false
	damage_mult_label.visible = false
	calc_title.visible = false
	formula_label.visible = false
	played_center.visible = false
	score_burst_label.visible = active
	attack_stick_button.visible = not active
	table_hint_label.visible = false
	if not active:
		strike_stick.visible = false
		monster_damage_label.visible = false
		_clear_damage_spikes()
		damage_zone.scale = Vector2.ONE

func _roll_attack_value(from_value: int, to_value: int, duration: float, _stick_growth: float):
	score_burst_label.text = "%d" % from_value
	var attack_progress := clampf(maxf(absf(float(from_value)), absf(float(to_value))) / _strike_reference_damage, 0.0, 1.0)
	var target_scale_value := lerpf(STICK_BATTLE_BASE_SCALE, _strike_damage_target_scale, pow(attack_progress, 0.42))
	var tw = create_tween().set_parallel()
	tw.tween_method(
		func(value: float): score_burst_label.text = "%d" % roundi(value),
		float(from_value), float(to_value), duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(strike_stick, "scale", _get_stick_combat_scale(target_scale_value), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw.finished
	score_burst_label.text = "%d" % to_value

func _get_stick_target_scale(damage: int) -> float:
	if damage <= 0:
		return STICK_BATTLE_BASE_SCALE
	var magnitude := log(float(damage)) / log(10.0)
	return clampf(STICK_BATTLE_BASE_SCALE + (magnitude - 1.0) * 0.55, STICK_BATTLE_BASE_SCALE, 3.45)

func _get_stick_combat_scale(length_scale: float) -> Vector2:
	# 原图为细长比例，战斗态单独加宽，长度仍完全由伤害决定。
	return Vector2(length_scale * STICK_BATTLE_WIDTH_RATIO, length_scale)

func _get_weapon_stick_center() -> Vector2:
	return attack_stick_art.get_global_transform() * (attack_stick_art.size * 0.5)

func _get_stick_battle_center() -> Vector2:
	# 停在妖怪右侧，为从右向左的挥击和右侧伤害数字留出清晰空间。
	return monster_avatar.get_global_transform() * (monster_avatar.size * Vector2(0.84, 0.61))

func _stick_position_for_global_center(global_center: Vector2) -> Vector2:
	var stick_parent := strike_stick.get_parent() as Control
	var local_center: Vector2 = stick_parent.get_global_transform().affine_inverse() * global_center
	return local_center - strike_stick.size * 0.5

func _fly_stick_into_battle():
	var source_position := _stick_position_for_global_center(_get_weapon_stick_center())
	var target_position := _stick_position_for_global_center(_get_stick_battle_center())
	var flight_state := {"mid_emitted": false}
	strike_stick.visible = true
	strike_stick.position = source_position
	strike_stick.pivot_offset = strike_stick.size * 0.5
	strike_stick.scale = _get_stick_combat_scale(0.72)
	strike_stick.rotation = -0.22
	strike_stick.modulate = Color.WHITE
	var flight = create_tween().set_parallel()
	flight.tween_method(func(progress: float):
		var arc_lift := Vector2(0.0, -sin(progress * PI) * 58.0)
		strike_stick.position = source_position.lerp(target_position, progress) + arc_lift
		strike_stick.rotation = lerpf(-0.22, TAU * 2.0, progress)
		if progress >= 0.46 and not flight_state.mid_emitted:
			flight_state.mid_emitted = true
			strike_stick.set_meta("flight_spin_observed", absf(strike_stick.rotation) > PI)
			damage_animation_stage.emit("stick_flying")
	, 0.0, 1.0, 0.46).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	var battle_scale := _get_stick_combat_scale(STICK_BATTLE_BASE_SCALE)
	flight.tween_property(strike_stick, "scale", battle_scale, 0.46).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await flight.finished
	# 登场演出可能让牌桌待机更久；落点在抵达帧重新追踪漂浮中的妖怪，避免金箍棒停在旧坐标。
	target_position = _stick_position_for_global_center(_get_stick_battle_center())
	strike_stick.position = target_position
	strike_stick.rotation = 0.0
	strike_stick.scale = battle_scale
	backdrop.burst(_get_stick_battle_center(), GameTheme.COLOR_GOLD, 16)
	damage_animation_stage.emit("stick_arrived")
	await get_tree().process_frame

func _roll_int_label(label: Label, from_value: int, to_value: int, duration: float):
	label.text = "%d" % from_value
	var tw = create_tween()
	tw.tween_method(func(value: float): label.text = "%d" % roundi(value), float(from_value), float(to_value), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	label.text = "%d" % to_value

func _roll_mult_label(from_value: float, to_value: float, duration: float):
	var tw = create_tween()
	tw.tween_method(func(value: float): damage_mult_label.text = "×%.2f" % value, from_value, to_value, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	damage_mult_label.text = "×%.2f" % to_value

func _fly_card_to_damage(card, source, card_index: int, card_count: int):
	var flying = _make_table_card(card)
	flying.disabled = true
	flying.z_index = 300 + card_index
	add_child(flying)
	var source_global := Vector2(size.x * 0.5, size.y * 0.84)
	var source_size := HAND_CARD_SIZE
	if source != null and is_instance_valid(source):
		source_global = source.global_position
		source_size = source.size
		source.modulate.a = 0.0
	flying.global_position = source_global
	flying.size = source_size
	flying.pivot_offset = flying.size * 0.5
	var number_center: Vector2 = score_burst_label.global_position + score_burst_label.size * 0.5
	var spread := 16.0
	var target_x: float = number_center.x - TABLE_CARD_SIZE.x * 0.5 + (card_index - (card_count - 1) * 0.5) * spread
	var target_y: float = number_center.y - TABLE_CARD_SIZE.y * 0.5
	var tw = create_tween().set_parallel()
	tw.tween_property(flying, "global_position", Vector2(target_x, target_y), 0.24).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(flying, "size", TABLE_CARD_SIZE, 0.24).set_ease(Tween.EASE_OUT)
	tw.tween_property(flying, "rotation", 0.0, 0.28)
	tw.tween_property(flying, "scale", Vector2(0.45, 0.45), 0.24).set_ease(Tween.EASE_IN)
	tw.tween_property(flying, "modulate:a", 0.0, 0.24).set_ease(Tween.EASE_IN)
	await tw.finished
	flying.queue_free()

func _play_stick_strike(final_score: int, is_crit: bool, blocked: bool):
	strike_stick.visible = true
	strike_stick.pivot_offset = Vector2(strike_stick.size.x * 0.5, strike_stick.size.y * 0.96)
	var origin: Vector2 = strike_stick.position
	var grown_scale: Vector2 = strike_stick.scale
	strike_stick.rotation = 0.0
	var swing_angle := deg_to_rad(-64.0)
	var impact_center: Vector2 = _get_monster_head_impact_center()
	strike_stick.set_meta("last_impact_center", impact_center)
	var impact_scale := grown_scale * 1.12
	# 以底部旋转轴和棒头的真实距离反推落点，保证旋转后的顶端准确击中头部中心。
	var tip_offset := Vector2(0.0, -strike_stick.pivot_offset.y * impact_scale.y).rotated(swing_angle)
	var desired_pivot_global := impact_center - tip_offset
	var stick_parent := strike_stick.get_parent() as Control
	var desired_pivot_local: Vector2 = stick_parent.get_global_transform().affine_inverse() * desired_pivot_global
	var impact_position: Vector2 = desired_pivot_local - strike_stick.pivot_offset
	var tw = create_tween().set_parallel()
	# 金箍棒已飞到妖怪右侧，蓄力完成后从右向左砸中妖怪。
	tw.tween_property(strike_stick, "rotation", swing_angle, 0.20).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.tween_property(strike_stick, "position", impact_position, 0.20).set_ease(Tween.EASE_IN)
	tw.tween_property(strike_stick, "scale", impact_scale, 0.20).set_ease(Tween.EASE_IN)
	await tw.finished
	var actual_tip_global: Vector2 = strike_stick.get_global_transform() * Vector2(strike_stick.pivot_offset.x, 0.0)
	strike_stick.set_meta("last_actual_tip", actual_tip_global)
	var impact_color := GameTheme.COLOR_CRIT if is_crit else GameTheme.COLOR_GOLD
	if blocked:
		impact_color = GameTheme.COLOR_RED
	backdrop.flash(impact_color, 0.34 if is_crit else 0.24)
	backdrop.burst(impact_center, impact_color, 62 if is_crit else 36)
	score_burst_label.visible = false
	crit_banner.visible = false
	_show_monster_damage(final_score, is_crit, blocked)
	_start_monster_hit_reaction(final_score, is_crit, blocked)
	# 命中特效和伤害数字先出现，再正式把模型中的伤害同步到妖怪血条。
	_commit_damage_visual_transaction()
	await get_tree().create_timer(0.13).timeout
	damage_animation_stage.emit("stick_impact")
	await get_tree().process_frame
	# 先从命中姿势快速回弹，再旋转、缩小飞回下方武器槽。
	var recoil = create_tween()
	recoil.tween_property(strike_stick, "position", origin, 0.14).set_ease(Tween.EASE_OUT)
	recoil.parallel().tween_property(strike_stick, "rotation", 0.0, 0.14)
	recoil.parallel().tween_property(strike_stick, "scale", grown_scale, 0.14).set_ease(Tween.EASE_OUT)
	await recoil.finished

	strike_stick.pivot_offset = strike_stick.size * 0.5
	var return_source: Vector2 = strike_stick.position
	var return_target := _stick_position_for_global_center(_get_weapon_stick_center())
	var return_start_scale: Vector2 = strike_stick.scale
	var return_state := {"mid_emitted": false}
	var return_flight = create_tween().set_parallel()
	return_flight.tween_method(func(progress: float):
		var arc_lift := Vector2(0.0, -sin(progress * PI) * 42.0)
		strike_stick.position = return_source.lerp(return_target, progress) + arc_lift
		strike_stick.rotation = lerpf(0.0, -TAU * 1.5, progress)
		if progress >= 0.48 and not return_state.mid_emitted:
			return_state.mid_emitted = true
			strike_stick.set_meta("return_shrink_observed", strike_stick.scale.x < return_start_scale.x)
			damage_animation_stage.emit("stick_returning")
	, 0.0, 1.0, 0.42).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	return_flight.tween_property(strike_stick, "scale", _get_stick_combat_scale(0.58), 0.42).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await return_flight.finished

	# 最后一小段与装备栏图标合并，明确表现“回到武器”。
	attack_stick_button.visible = true
	attack_stick_button.modulate.a = 0.0
	var merge = create_tween().set_parallel()
	merge.tween_property(strike_stick, "scale", _get_stick_combat_scale(0.34), 0.11).set_ease(Tween.EASE_IN)
	merge.tween_property(strike_stick, "modulate:a", 0.0, 0.11)
	merge.tween_property(attack_stick_button, "modulate:a", 1.0, 0.11).set_ease(Tween.EASE_OUT)
	await merge.finished
	strike_stick.visible = false
	strike_stick.modulate = Color.WHITE
	strike_stick.position = origin
	strike_stick.rotation = 0.0
	strike_stick.scale = Vector2.ONE
	attack_stick_button.modulate = Color.WHITE
	damage_animation_stage.emit("stick_returned")
	await get_tree().process_frame

func _get_monster_head_impact_center() -> Vector2:
	return monster_avatar.get_global_transform() * (monster_avatar.size * MONSTER_HEAD_IMPACT_POINT)

func _show_monster_damage(final_score: int, is_crit: bool, blocked: bool):
	_spawn_damage_spikes(is_crit, blocked)
	monster_damage_label.visible = true
	monster_damage_label.modulate.a = 1.0
	monster_damage_label.scale = Vector2(0.25, 0.25)
	monster_damage_label.pivot_offset = monster_damage_label.size * 0.5
	if blocked:
		monster_damage_label.text = "免疫  0"
		monster_damage_label.add_theme_font_size_override("font_size", 42)
		monster_damage_label.add_theme_color_override("font_color", GameTheme.COLOR_TEXT_DIM)
	elif is_crit:
		monster_damage_label.text = "暴击！\n-%d" % final_score
		monster_damage_label.add_theme_font_size_override("font_size", 72)
		monster_damage_label.add_theme_color_override("font_color", Color("ff1710"))
	else:
		monster_damage_label.text = "-%d" % final_score
		monster_damage_label.add_theme_font_size_override("font_size", 48)
		monster_damage_label.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	monster_damage_label.set_meta("spiky_damage_value", true)
	damage_animation_stage.emit("spiky_damage")
	var damage_tw = create_tween()
	var origin_y: float = monster_damage_label.position.y
	damage_tw.tween_property(monster_damage_label, "scale", Vector2(1.28, 1.28) if is_crit else Vector2(1.08, 1.08), 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	damage_tw.tween_property(monster_damage_label, "scale", Vector2.ONE, 0.10)
	damage_tw.tween_interval(0.30)
	damage_tw.tween_property(monster_damage_label, "position:y", origin_y - 28.0, 0.24).set_ease(Tween.EASE_OUT)
	damage_tw.parallel().tween_property(monster_damage_label, "modulate:a", 0.0, 0.24)
	damage_tw.tween_callback(func():
		monster_damage_label.visible = false
		monster_damage_label.position.y = origin_y
	)

func _spawn_damage_spikes(is_crit: bool, blocked: bool):
	_clear_damage_spikes()
	var center: Vector2 = monster_damage_label.position + monster_damage_label.size * 0.5
	var impact_color: Color = GameTheme.COLOR_CRIT if is_crit else GameTheme.COLOR_GOLD
	if blocked:
		impact_color = GameTheme.COLOR_TEXT_DIM
	var outer_radius: float = 104.0 if is_crit else 78.0
	if blocked:
		outer_radius = 62.0
	var spike_count := 18 if is_crit else 15
	var layers := [
		{"radius": outer_radius + 11.0, "inner": outer_radius * 0.25, "color": Color(0.12, 0.01, 0.01, 0.82), "z": 496, "delay": 0.0},
		{"radius": outer_radius, "inner": outer_radius * 0.31, "color": Color(impact_color.r, impact_color.g, impact_color.b, 0.84), "z": 497, "delay": 0.018},
		{"radius": outer_radius * 0.68, "inner": outer_radius * 0.24, "color": Color(1.0, 0.92, 0.52, 0.58), "z": 498, "delay": 0.035},
	]
	for layer_index in range(layers.size()):
		var layer: Dictionary = layers[layer_index]
		var spike := Polygon2D.new()
		spike.polygon = _build_damage_spike_polygon(float(layer.radius), float(layer.inner), spike_count, layer_index)
		spike.color = layer.color
		spike.position = center
		spike.z_index = int(layer.z)
		spike.scale = Vector2(0.08, 0.08)
		spike.rotation = -0.08 if layer_index % 2 == 0 else 0.06
		spike.set_meta("spiky_damage_value", true)
		play_surface.add_child(spike)
		_damage_spike_nodes.append(spike)
		var target_scale := Vector2(1.16, 1.16) if is_crit else Vector2.ONE
		var spike_tw := create_tween()
		spike_tw.tween_interval(float(layer.delay))
		spike_tw.tween_property(spike, "scale", target_scale, 0.11).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		spike_tw.parallel().tween_property(spike, "rotation", -spike.rotation * 0.35, 0.13).set_ease(Tween.EASE_OUT)
		spike_tw.tween_interval(0.25 if is_crit else 0.20)
		spike_tw.tween_property(spike, "scale", target_scale * 1.28, 0.27).set_ease(Tween.EASE_OUT)
		spike_tw.parallel().tween_property(spike, "modulate:a", 0.0, 0.27)
		spike_tw.tween_callback(func(): _finish_damage_spike(spike))

func _build_damage_spike_polygon(outer_radius: float, inner_radius: float, spike_count: int, layer_index: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(spike_count * 2):
		var is_tip := point_index % 2 == 0
		var radius := outer_radius if is_tip else inner_radius
		if is_tip:
			# 长短交错的尖刺让伤害数字更像漫画中的爆裂冲击框。
			var tip_index := int(point_index / 2)
			radius *= [1.0, 0.76, 0.90][(tip_index + layer_index) % 3]
		var angle := -PI * 0.5 + TAU * float(point_index) / float(spike_count * 2)
		points.append(Vector2(cos(angle) * radius * 1.30, sin(angle) * radius * 0.72))
	return points

func _finish_damage_spike(spike: Polygon2D):
	_damage_spike_nodes.erase(spike)
	if is_instance_valid(spike):
		spike.queue_free()

func _clear_damage_spikes():
	for spike in _damage_spike_nodes:
		if is_instance_valid(spike):
			spike.queue_free()
	_damage_spike_nodes.clear()

func _start_monster_hit_reaction(final_score: int, is_crit: bool, blocked: bool):
	_monster_hit_generation += 1
	var hit_generation := _monster_hit_generation
	if _monster_hit_tween and _monster_hit_tween.is_valid():
		_monster_hit_tween.kill()
	if not _monster_idle_initialized:
		_monster_shake_origin_position = monster_shake_root.position
		_monster_idle_origin_position = monster_avatar.position
		_monster_glow_idle_origin_position = monster_glow.position
		_monster_idle_initialized = true
	# 妖怪本体始终交给布局系统管理；受击只在容器原位附近抖动。
	# 先清掉可能被上一段中断动画留下的瞬时偏移，避免连续受击累计位移。
	monster_shake_root.position = _monster_shake_origin_position
	var power := clampf(2.2 + log(maxf(float(final_score), 1.0)) * 0.16, 2.6, 3.8)
	if is_crit:
		power = minf(4.8, power + 0.8)
	if blocked:
		power = 1.6
	monster_avatar.set_meta("hit_shake_active", true)
	monster_avatar.set_meta("hit_shake_observed", true)
	monster_avatar.set_meta("hit_returned_to_origin", false)
	monster_avatar.set_meta("last_hit_shake_power", power)
	damage_animation_stage.emit("monster_hit_shake")

	# 只进行几像素、四拍以内的短促抖动；没有旋转、缩放或全屏位移。
	var directions := [
		Vector2(-1.0, 0.12), Vector2(0.82, -0.10),
		Vector2(-0.48, 0.06), Vector2(0.22, -0.03),
	]
	_monster_hit_tween = create_tween()
	for shake_index in range(directions.size()):
		var decay := 1.0 - float(shake_index) / float(directions.size()) * 0.55
		var offset: Vector2 = directions[shake_index] * power * decay
		_monster_hit_tween.tween_property(monster_shake_root, "position", _monster_shake_origin_position + offset, 0.024)
	_monster_hit_tween.tween_property(monster_shake_root, "position", _monster_shake_origin_position, 0.045).set_ease(Tween.EASE_OUT)
	_monster_hit_tween.tween_callback(func():
		if hit_generation != _monster_hit_generation:
			return
		_restore_monster_hit_origin()
	)

func _restore_monster_hit_origin():
	if not _monster_idle_initialized:
		return
	# 受击反馈从不改妖怪和光环本体，因此这里只需复位抖动容器。
	monster_shake_root.position = _monster_shake_origin_position
	monster_avatar.set_meta("hit_shake_active", false)
	monster_avatar.set_meta("hit_returned_to_origin", true)
	monster_avatar.set_meta("last_restored_position", _monster_idle_origin_position)
	monster_shake_root.set_meta("returned_to_zero", true)

func _finish_monster_hit_reaction():
	# 最终兜底归零；待机只保留光环呼吸，不再改变妖怪位置。
	_restore_monster_hit_origin()
	_start_monster_idle()

func _bounce_joker_by_name(item_name: String):
	for i in range(ItemManager.jokers.size()):
		if ItemManager.jokers[i].resource_data.get("display_name", "") == item_name:
			await _bounce_joker_badge(i)
			return

func _impact_feedback(final_score: int, is_crit: bool, blocked: bool):
	var color = GameTheme.COLOR_CRIT if is_crit else GameTheme.COLOR_GOLD
	if blocked: color = GameTheme.COLOR_RED
	backdrop.flash(color, 0.30 if is_crit else 0.18)
	backdrop.burst(Vector2(size.x * 0.5, size.y * 0.43), color, 44 if is_crit else 28)
	monster_avatar.visible = true
	monster_glow.visible = true
	boss_phase_badge.visible = false

	hit_flash.color = Color(color.r, color.g, color.b, 0.34 if is_crit else 0.20)
	var flash_tw = create_tween()
	flash_tw.tween_property(hit_flash, "color:a", 0.0, 0.24)

	if not blocked:
		var combo = _get_current_combo()
		var rating = "漂亮一击！"
		if final_score >= 5000: rating = "天崩地裂！"
		elif final_score >= 2000: rating = "数值炸裂！"
		elif final_score >= 800: rating = "一击入魂！"
		elif final_score >= 300: rating = "爆了！"
		combo_banner.text = "%s  连击 ×%d" % [rating, combo]
		combo_banner.visible = true
		combo_banner.pivot_offset = combo_banner.size * 0.5
		combo_banner.scale = Vector2(0.25, 0.25)
		combo_banner.modulate.a = 1.0
		var combo_tw = create_tween()
		combo_tw.tween_property(combo_banner, "scale", Vector2(1.22, 1.22), 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		combo_tw.tween_property(combo_banner, "scale", Vector2.ONE, 0.10)
		combo_tw.tween_interval(0.28)
		combo_tw.tween_property(combo_banner, "modulate:a", 0.0, 0.18)
		combo_tw.tween_callback(func(): combo_banner.visible = false)
	if _enrage_transition_pending:
		_enrage_transition_pending = false
		await get_tree().create_timer(0.14).timeout
		await _play_boss_enrage_transition()
	else:
		await get_tree().create_timer(0.18).timeout

func _play_boss_enrage_transition():
	monster_avatar.visible = true
	monster_glow.visible = true
	monster_title.visible = false
	boss_phase_badge.visible = false
	boss_phase_badge.text = ""
	backdrop.flash(GameTheme.COLOR_CRIT, 0.44)
	backdrop.burst(Vector2(size.x * 0.22, size.y * 0.44), GameTheme.COLOR_CRIT, 52)
	monster_avatar.pivot_offset = monster_avatar.size * 0.5
	monster_glow.pivot_offset = monster_glow.size * 0.5
	monster_avatar.scale = Vector2(0.58, 0.58)
	monster_glow.scale = Vector2(0.72, 0.72)
	# 不使用任何文字说明形态变化，红色气场和第二阶段立绘承担全部反馈。
	combo_banner.visible = false
	var tw = create_tween()
	tw.tween_property(monster_avatar, "scale", Vector2(1.28, 1.28), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(monster_glow, "scale", Vector2(1.42, 1.42), 0.22)
	tw.parallel().tween_property(monster_glow, "modulate", Color(1.0, 0.08, 0.02, 0.62), 0.16)
	tw.tween_property(monster_avatar, "scale", Vector2.ONE, 0.14)
	tw.parallel().tween_property(monster_glow, "scale", Vector2(1.08, 1.08), 0.14)
	tw.parallel().tween_property(monster_glow, "modulate", Color(1.0, 0.18, 0.08, 0.24), 0.14)
	tw.tween_interval(0.38)
	await tw.finished

func _get_current_combo() -> int:
	var combo := 0
	for i in range(RoundManager.play_log.size() - 1, -1, -1):
		var entry = RoundManager.play_log[i]
		if entry.get("round", -1) != RoundManager.current_round or entry.get("blind", -1) != RoundManager.current_blind:
			break
		combo += 1
	return maxi(1, combo)

func _start_idle_juice():
	_start_monster_idle()
	play_button.pivot_offset = play_button.size * 0.5
	var glow_tw = create_tween().set_loops()
	glow_tw.tween_property(play_button, "modulate", Color(1.16, 1.08, 1.02, 1), 0.65).set_ease(Tween.EASE_IN_OUT)
	glow_tw.tween_property(play_button, "modulate", Color.WHITE, 0.65).set_ease(Tween.EASE_IN_OUT)

func _start_monster_idle():
	if _monster_aura_tween and _monster_aura_tween.is_valid():
		_monster_aura_tween.kill()
	if not _monster_idle_initialized:
		_monster_shake_origin_position = monster_shake_root.position
		_monster_idle_origin_position = monster_avatar.position
		_monster_glow_idle_origin_position = monster_glow.position
		_monster_idle_initialized = true
	monster_shake_root.position = _monster_shake_origin_position
	monster_avatar.rotation = 0.0
	monster_avatar.scale = Vector2.ONE
	monster_avatar.pivot_offset = monster_avatar.size * 0.5
	monster_glow.pivot_offset = monster_glow.size * 0.5
	monster_glow.scale = Vector2(1.08, 1.08)
	_monster_aura_tween = create_tween().set_loops()
	_monster_aura_tween.tween_property(monster_glow, "modulate:a", 0.28, 0.70).set_ease(Tween.EASE_IN_OUT)
	_monster_aura_tween.parallel().tween_property(monster_glow, "scale", Vector2(1.14, 1.14), 0.70)
	_monster_aura_tween.tween_property(monster_glow, "modulate:a", 0.10, 0.70).set_ease(Tween.EASE_IN_OUT)
	_monster_aura_tween.parallel().tween_property(monster_glow, "scale", Vector2(1.06, 1.06), 0.70)


func _make_step_label(icon: String, name: String, delta: String, result: String, color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var icon_lbl = Label.new(); icon_lbl.text = icon; icon_lbl.add_theme_font_size_override("font_size", 14)
	var name_lbl = Label.new(); name_lbl.text = name; name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", color); name_lbl.size_flags_horizontal = 3
	var delta_lbl = Label.new(); delta_lbl.text = delta; delta_lbl.add_theme_font_size_override("font_size", 11)
	delta_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.55, 1))
	var result_lbl = Label.new(); result_lbl.text = result; result_lbl.add_theme_font_size_override("font_size", 12)
	result_lbl.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	row.add_child(icon_lbl); row.add_child(name_lbl); row.add_child(delta_lbl); row.add_child(result_lbl)
	return row

func _fade_in_row(row: Control):
	row.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(row, "modulate:a", 1.0, 0.20)

func _bounce_joker_badge(index: int):
	if index < 0 or index >= _joker_badge_nodes.size():
		return
	var node: Control = _joker_badge_nodes[index]
	if not is_instance_valid(node):
		return
	var artifact_id := str(ItemManager.jokers[index].resource_data.get("id", ""))
	var started_at := Time.get_ticks_msec()
	match artifact_id:
		"artifact_bjs": await _play_banana_fan_effect(node)
		"artifact_zjl": await _play_purple_bell_effect(node)
		"artifact_rsg": await _play_ginseng_fruit_effect(node, index)
		"artifact_hyjj": await _play_fire_eye_effect(node)
		_: await _play_banana_fan_effect(node)
	node.set_meta("last_artifact_effect_id", artifact_id)
	node.set_meta("last_artifact_effect_duration_ms", Time.get_ticks_msec() - started_at)

func _artifact_source_global(node: Control) -> Vector2:
	return node.get_global_transform() * (node.size * 0.5)

func _artifact_target_global() -> Vector2:
	return strike_stick.get_global_transform() * (strike_stick.size * 0.5)

func _global_to_board(point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * point

func _make_artifact_line(points: PackedVector2Array, color: Color, width: float, layer: int = 180) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.z_index = layer
	add_child(line)
	return line

func _make_artifact_ring(global_center: Vector2, color: Color, radius: float = 18.0) -> Line2D:
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in range(33):
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	ring.width = 3.0
	ring.default_color = color
	ring.antialiased = true
	ring.closed = true
	ring.position = _global_to_board(global_center)
	ring.z_index = 185
	add_child(ring)
	return ring

func _emit_artifact_effect_stage(artifact_id: String):
	damage_animation_stage.emit(artifact_id)
	damage_animation_stage.emit("artifact_boost")
	await get_tree().process_frame

# 芭蕉扇：连续扇动三次，三股青金罡风沿弧线卷入金箍棒。
func _play_banana_fan_effect(node: Control):
	node.set_meta("last_artifact_effect_kind", "wind_sweep")
	var original_scale: Vector2 = node.scale
	var original_rotation: float = node.rotation
	var original_modulate: Color = node.modulate
	var stick_modulate: Color = strike_stick.modulate
	node.pivot_offset = node.size * 0.5
	var source := _global_to_board(_artifact_source_global(node))
	var target := _global_to_board(_artifact_target_global())
	var direction := target - source
	var normal := Vector2(-direction.y, direction.x).normalized()
	var wind_lines: Array[Line2D] = []
	for lane in range(-1, 2):
		var points := PackedVector2Array()
		for point_index in range(17):
			var progress := float(point_index) / 16.0
			var wave := sin(progress * PI * 3.0 + float(lane)) * 7.0
			points.append(source.lerp(target, progress) + normal * (float(lane) * 11.0 + wave))
		var wind := _make_artifact_line(points, Color(0.38, 1.0, 0.76, 0.82), 3.5 if lane == 0 else 2.2, 184 + lane)
		wind.modulate.a = 0.0
		wind_lines.append(wind)
	var reveal = create_tween().set_parallel()
	reveal.tween_property(node, "scale", original_scale * 1.18, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	reveal.tween_property(node, "rotation", -0.24, 0.22).set_ease(Tween.EASE_OUT)
	reveal.tween_property(strike_stick, "modulate", Color(0.52, 1.0, 0.68, 1.0), 0.24)
	for wind in wind_lines:
		reveal.tween_property(wind, "modulate:a", 1.0, 0.28)
	await reveal.finished
	var sweeps = create_tween()
	sweeps.tween_property(node, "rotation", 0.30, 0.22).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	sweeps.tween_property(node, "rotation", -0.20, 0.20).set_ease(Tween.EASE_IN_OUT)
	sweeps.tween_property(node, "rotation", 0.18, 0.18).set_ease(Tween.EASE_IN_OUT)
	await sweeps.finished
	backdrop.burst(_artifact_target_global(), Color(0.42, 1.0, 0.72, 1.0), 24)
	await _emit_artifact_effect_stage("artifact_bjs")
	var release = create_tween().set_parallel()
	release.tween_property(node, "rotation", original_rotation, 0.26).set_ease(Tween.EASE_OUT)
	release.tween_property(node, "scale", original_scale, 0.26).set_ease(Tween.EASE_IN)
	release.tween_property(node, "modulate", original_modulate, 0.26)
	release.tween_property(strike_stick, "modulate", stick_modulate, 0.26)
	for wind in wind_lines:
		release.tween_property(wind, "modulate:a", 0.0, 0.26)
	await release.finished
	for wind in wind_lines:
		wind.queue_free()

# 紫金铃：三次摇铃依次扩散火、烟、沙色铃波，最后形成紫金共鸣。
func _play_purple_bell_effect(node: Control):
	node.set_meta("last_artifact_effect_kind", "triple_bell_wave")
	var original_scale: Vector2 = node.scale
	var original_rotation: float = node.rotation
	var stick_modulate: Color = strike_stick.modulate
	node.pivot_offset = node.size * 0.5
	var source_global := _artifact_source_global(node)
	var ring_colors := [Color("ff6b2b"), Color("c69cff"), Color("e5bd61")]
	var final_ring: Line2D = null
	for ring_index in range(3):
		var ring := _make_artifact_ring(source_global, ring_colors[ring_index], 17.0)
		ring.scale = Vector2(0.28, 0.28)
		ring.modulate.a = 0.0
		var pulse = create_tween().set_parallel()
		pulse.tween_property(ring, "scale", Vector2(1.75, 1.75), 0.18).set_ease(Tween.EASE_OUT)
		pulse.tween_property(ring, "modulate:a", 1.0, 0.10)
		pulse.tween_property(node, "rotation", 0.18 if ring_index % 2 == 0 else -0.18, 0.11).set_ease(Tween.EASE_OUT)
		pulse.tween_property(node, "scale", original_scale * 1.13, 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		await pulse.finished
		if ring_index < 2:
			var echo = create_tween().set_parallel()
			echo.tween_property(ring, "scale", Vector2(2.20, 2.20), 0.11)
			echo.tween_property(ring, "modulate:a", 0.0, 0.11)
			echo.tween_property(node, "rotation", 0.0, 0.11)
			echo.tween_property(node, "scale", original_scale, 0.11)
			await echo.finished
			ring.queue_free()
		else:
			final_ring = ring
	var source := _global_to_board(source_global)
	var target := _global_to_board(_artifact_target_global())
	var resonance := _make_artifact_line(PackedVector2Array([source, target]), Color(0.82, 0.42, 1.0, 0.90), 8.0, 184)
	var resonance_core := _make_artifact_line(PackedVector2Array([source, target]), Color(1.0, 0.88, 0.32, 1.0), 2.5, 185)
	resonance.modulate.a = 0.0
	resonance_core.modulate.a = 0.0
	var charge = create_tween().set_parallel()
	charge.tween_property(resonance, "modulate:a", 1.0, 0.18)
	charge.tween_property(resonance_core, "modulate:a", 1.0, 0.18)
	charge.tween_property(strike_stick, "modulate", Color(0.94, 0.58, 1.0, 1.0), 0.18)
	await charge.finished
	backdrop.burst(_artifact_target_global(), GameTheme.COLOR_JOKER, 26)
	await _emit_artifact_effect_stage("artifact_zjl")
	var release = create_tween().set_parallel()
	release.tween_property(resonance, "modulate:a", 0.0, 0.24)
	release.tween_property(resonance_core, "modulate:a", 0.0, 0.24)
	release.tween_property(strike_stick, "modulate", stick_modulate, 0.24)
	release.tween_property(node, "rotation", original_rotation, 0.24)
	release.tween_property(node, "scale", original_scale, 0.24)
	if final_ring != null:
		release.tween_property(final_ring, "scale", Vector2(2.35, 2.35), 0.24)
		release.tween_property(final_ring, "modulate:a", 0.0, 0.24)
	await release.finished
	resonance.queue_free()
	resonance_core.queue_free()
	if final_ring != null:
		final_ring.queue_free()

# 人参果：触发极高倍率时，果实从法宝槽升起、成熟放大并融入金箍棒。
func _play_ginseng_fruit_effect(node: Control, index: int):
	node.set_meta("last_artifact_effect_kind", "golden_fruit_bloom")
	var original_scale: Vector2 = node.scale
	var original_modulate: Color = node.modulate
	var stick_modulate: Color = strike_stick.modulate
	node.pivot_offset = node.size * 0.5
	var source_global := _artifact_source_global(node)
	var target_global := _artifact_target_global()
	var source := _global_to_board(source_global)
	var target := _global_to_board(target_global)
	var fruit := TextureRect.new()
	fruit.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fruit.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fruit.texture = ItemManager.get_artifact_texture(ItemManager.jokers[index])
	fruit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fruit.z_index = 190
	add_child(fruit)
	fruit.size = Vector2(54, 54)
	fruit.position = source - fruit.size * 0.5
	fruit.pivot_offset = fruit.size * 0.5
	var halo := _make_artifact_ring(source_global, Color(1.0, 0.82, 0.24, 0.94), 22.0)
	halo.scale = Vector2(0.35, 0.35)
	var rise = create_tween().set_parallel()
	rise.tween_property(node, "scale", original_scale * 1.20, 0.24).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	rise.tween_property(node, "modulate", Color(1.25, 1.08, 0.55, 1.0), 0.24)
	rise.tween_property(fruit, "position", target - fruit.size * 0.5 + Vector2(0.0, -16.0), 0.54).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	rise.tween_property(fruit, "scale", Vector2(1.35, 1.35), 0.54).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	rise.tween_property(fruit, "rotation", 0.22, 0.54)
	rise.tween_property(halo, "scale", Vector2(2.25, 2.25), 0.46).set_ease(Tween.EASE_OUT)
	rise.tween_property(halo, "modulate:a", 0.0, 0.46)
	await rise.finished
	backdrop.flash(Color(1.0, 0.72, 0.12, 1.0), 0.24)
	backdrop.burst(target_global, Color(1.0, 0.78, 0.20, 1.0), 42)
	strike_stick.modulate = Color(1.0, 0.82, 0.30, 1.0)
	var bloom = create_tween()
	bloom.tween_property(fruit, "scale", Vector2(1.75, 1.75), 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await bloom.finished
	await _emit_artifact_effect_stage("artifact_rsg")
	var release = create_tween().set_parallel()
	release.tween_property(fruit, "scale", Vector2(0.42, 0.42), 0.26).set_ease(Tween.EASE_IN)
	release.tween_property(fruit, "modulate:a", 0.0, 0.26)
	release.tween_property(node, "scale", original_scale, 0.26)
	release.tween_property(node, "modulate", original_modulate, 0.26)
	release.tween_property(strike_stick, "modulate", stick_modulate, 0.26)
	await release.finished
	fruit.queue_free()
	halo.queue_free()

# 火眼金睛：赤金锥形目光扫过妖怪，锁定本相后将火光注入金箍棒。
func _play_fire_eye_effect(node: Control):
	node.set_meta("last_artifact_effect_kind", "truth_scan")
	var original_scale: Vector2 = node.scale
	var original_modulate: Color = node.modulate
	var stick_modulate: Color = strike_stick.modulate
	node.pivot_offset = node.size * 0.5
	var source := _global_to_board(_artifact_source_global(node))
	var head := _global_to_board(_get_monster_head_impact_center())
	var target := _global_to_board(_artifact_target_global())
	var direction := (head - source).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var cone := Polygon2D.new()
	cone.polygon = PackedVector2Array([source, head + normal * 66.0, head - normal * 66.0])
	cone.color = Color(1.0, 0.20, 0.04, 0.28)
	cone.modulate.a = 0.0
	cone.z_index = 178
	add_child(cone)
	var gaze := _make_artifact_line(PackedVector2Array([source, head]), Color(1.0, 0.66, 0.12, 0.94), 4.0, 185)
	gaze.modulate.a = 0.0
	var scan := _make_artifact_line(PackedVector2Array([Vector2(-72, 0), Vector2(72, 0)]), Color(1.0, 0.24, 0.05, 1.0), 4.0, 188)
	scan.position = head + Vector2(0.0, -44.0)
	scan.modulate.a = 0.0
	var focus := _make_artifact_line(PackedVector2Array([head, target]), Color(1.0, 0.78, 0.16, 1.0), 3.0, 186)
	focus.modulate.a = 0.0
	var reveal = create_tween().set_parallel()
	reveal.tween_property(node, "scale", original_scale * 1.24, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	reveal.tween_property(node, "modulate", Color(1.28, 0.62, 0.30, 1.0), 0.25)
	reveal.tween_property(cone, "modulate:a", 1.0, 0.25)
	reveal.tween_property(gaze, "modulate:a", 1.0, 0.25)
	await reveal.finished
	var scan_tw = create_tween().set_parallel()
	scan_tw.tween_property(scan, "modulate:a", 1.0, 0.10)
	scan_tw.tween_property(scan, "position:y", scan.position.y + 88.0, 0.42).set_ease(Tween.EASE_IN_OUT)
	scan_tw.tween_property(focus, "modulate:a", 1.0, 0.30).set_delay(0.12)
	scan_tw.tween_property(strike_stick, "modulate", Color(1.0, 0.40, 0.16, 1.0), 0.30).set_delay(0.12)
	await scan_tw.finished
	backdrop.flash(Color(1.0, 0.25, 0.06, 1.0), 0.18)
	backdrop.burst(_get_monster_head_impact_center(), Color(1.0, 0.52, 0.10, 1.0), 28)
	await _emit_artifact_effect_stage("artifact_hyjj")
	var release = create_tween().set_parallel()
	release.tween_property(cone, "modulate:a", 0.0, 0.28)
	release.tween_property(gaze, "modulate:a", 0.0, 0.28)
	release.tween_property(scan, "modulate:a", 0.0, 0.28)
	release.tween_property(focus, "modulate:a", 0.0, 0.28)
	release.tween_property(node, "scale", original_scale, 0.28)
	release.tween_property(node, "modulate", original_modulate, 0.28)
	release.tween_property(strike_stick, "modulate", stick_modulate, 0.28)
	await release.finished
	cone.queue_free()
	gaze.queue_free()
	scan.queue_free()
	focus.queue_free()

func _reset_inline_calc():
	_set_damage_zone_visible(false)
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
	score_burst_label.add_theme_font_size_override("font_size", 46)
	score_burst_label.add_theme_color_override("font_color", GameTheme.COLOR_GOLD)
	crit_banner.visible = false
	crit_banner.modulate.a = 1.0
	damage_chips_label.text = "0"
	damage_mult_label.text = "×1.00"
	monster_damage_label.visible = false
	monster_damage_label.modulate.a = 1.0
	calc_close_hint.visible = false
	monster_avatar.visible = true
	monster_glow.visible = true
	monster_title.visible = false
	boss_phase_badge.visible = false
	table_hint_label.visible = false

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

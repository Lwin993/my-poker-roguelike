# MainUI.gd - 主场景控制器，负责场景切换
extends Control

@onready var main_menu    = $MainMenu
@onready var game_board   = $GameBoard
@onready var shop_node    = $Shop
@onready var result_screen = $ResultScreen
@onready var rules_dialog  = $RulesDialog
@onready var gold_coins_label = $MainMenu/Center/VBox/GoldCoinsLabel

# 子场景脚本引用（动态加载）
var _game_board_ui = null
var _shop_ui       = null
var _result_ui     = null
var _rank_ui       = null

func _ready():
	# 连接相位切换信号
	RoundManager.phase_changed.connect(_on_phase_changed)

	# 连接主菜单按钮
	$MainMenu/Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$MainMenu/Center/VBox/RulesButton.pressed.connect(_on_rules_pressed)
	$MainMenu/Center/VBox/RankButton.pressed.connect(_on_rank_pressed)

	# 预加载子场景
	_load_sub_scenes()

	# Connect GameAPI signals for async flow
	GameAPI.game_started.connect(_on_game_started)
	GameAPI.wallet_balance_loaded.connect(_on_wallet_loaded)

	_show_panel(main_menu)

	# 首次进入主菜单时查询外部金币余额
	GameAPI.get_wallet_balance()

func _load_sub_scenes():
	# 动态加载子场景内容
	var board_scene  = load("res://scenes/GameBoard.tscn")
	var shop_scene   = load("res://scenes/Shop.tscn")
	var result_scene = load("res://scenes/ResultScreen.tscn")
	var rank_scene   = load("res://scenes/Rank.tscn")

	if board_scene:
		var board_inst = board_scene.instantiate()
		game_board.add_child(board_inst)
		_game_board_ui = board_inst

	if shop_scene:
		var shop_inst = shop_scene.instantiate()
		shop_node.add_child(shop_inst)
		_shop_ui = shop_inst

	if result_scene:
		var result_inst = result_scene.instantiate()
		result_screen.add_child(result_inst)
		_result_ui = result_inst

	if rank_scene:
		var rank_inst = rank_scene.instantiate()
		add_child(rank_inst)
		_rank_ui = rank_inst

func _on_start_pressed():
	GameAPI.start_game()
	# RoundManager.start_new_game() is deferred to _on_game_started callback
	# after ConfigLoader has loaded configs from backend

# codeflicker-fix: LOGIC-Issue-3/dj8jw3oav3b23dnz7vyz — 主菜单展示外部金币 + 余额不足检查
var _entry_cost: int = 10  # default, updated from game_started response

func _on_wallet_loaded(balance: int):
	gold_coins_label.text = "💎 灵石: %d" % balance
	_update_start_button()

func _update_start_button():
	var btn = $MainMenu/Center/VBox/StartButton
	if GameAPI.gold_coins < _entry_cost:
		btn.disabled = true
		btn.tooltip_text = "灵石不足，需要 %d 灵石" % _entry_cost
	else:
		btn.disabled = false
		btn.tooltip_text = "开始游戏（入场费: %d 灵石）" % _entry_cost

func _on_rules_pressed():
	rules_dialog.popup_centered()

func _on_rank_pressed():
	if _rank_ui:
		_rank_ui.visible = true
		_rank_ui.show_rank()

func _on_phase_changed(new_phase: int):
	match new_phase:
		RoundManager.Phase.PLAYING, RoundManager.Phase.ROUND_START:
			_show_panel(game_board)
		RoundManager.Phase.SHOP:
			_show_panel(shop_node)
			if _shop_ui and _shop_ui.has_method("refresh_shop"):
				_shop_ui.refresh_shop()
		RoundManager.Phase.FINAL_RESULT:
			_show_panel(result_screen)
			if _result_ui and _result_ui.has_method("show_result"):
				_result_ui.show_result()
		RoundManager.Phase.MAIN_MENU:
			_show_panel(main_menu)
			GameAPI.get_wallet_balance()
			_update_start_button()

func _show_panel(panel: Control):
	for child in [main_menu, game_board, shop_node, result_screen]:
		child.visible = (child == panel)

# Callback when backend confirms game start
func _on_game_started(data: Dictionary):
	# ConfigLoader already loaded from GameAPI.start_game callback
	# Now initialize game state with loaded configs
	_entry_cost = int(data.get("entry_cost", 10))
	gold_coins_label.text = "💎 灵石: %d" % GameAPI.gold_coins
	RoundManager.start_new_game()

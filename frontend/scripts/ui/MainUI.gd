# MainUI.gd - 主场景控制器，负责场景切换
extends Control

@onready var main_menu    = $MainMenu
@onready var game_board   = $GameBoard
@onready var shop_node    = $Shop
@onready var result_screen = $ResultScreen
@onready var rules_dialog  = $RulesDialog

# 子场景脚本引用（动态加载）
var _game_board_ui = null
var _shop_ui       = null
var _result_ui     = null

func _ready():
	# 连接相位切换信号
	RoundManager.phase_changed.connect(_on_phase_changed)

	# 连接主菜单按钮
	$MainMenu/Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$MainMenu/Center/VBox/RulesButton.pressed.connect(_on_rules_pressed)

	# 预加载子场景
	_load_sub_scenes()

	_show_panel(main_menu)

func _load_sub_scenes():
	# 动态加载子场景内容
	var board_scene  = load("res://scenes/GameBoard.tscn")
	var shop_scene   = load("res://scenes/Shop.tscn")
	var result_scene = load("res://scenes/ResultScreen.tscn")

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

func _on_start_pressed():
	GameAPI.start_game()
	RoundManager.start_new_game()

func _on_rules_pressed():
	rules_dialog.popup_centered()

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

func _show_panel(panel: Control):
	for child in [main_menu, game_board, shop_node, result_screen]:
		child.visible = (child == panel)

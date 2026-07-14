extends SceneTree

const MOCK_ITEMS = [
	{"id":"artifact_bjs","display_name":"芭蕉扇","description":"每次出牌掀起罡风，固定增加倍率","price":35,"rarity":0,"item_type":0,"effect_class":"BaJiaoShan"},
	{"id":"artifact_hyjj","display_name":"火眼金睛","description":"每战随机花色，匹配牌增加伤害","price":40,"rarity":0,"item_type":0,"effect_class":"HuoYanJinJing"},
	{"id":"nine_elixir","display_name":"九转金丹","description":"当次出牌伤害+25","price":8,"rarity":0,"item_type":1,"effect_class":"NineElixir"},
	{"id":"double_potion","display_name":"狂战药水","description":"当前战斗所有出牌倍率+3","price":15,"rarity":0,"item_type":1,"effect_class":"FrenzyPotion"},
	{"id":"mirror_reveal","display_name":"照妖镜","description":"白骨精战破除幻术，持续整场战斗","price":20,"rarity":1,"item_type":1,"effect_class":"MirrorReveal"},
	{"id":"quint_crit","display_name":"五连暴击","description":"当前战斗暴击率提升至50%","price":30,"rarity":1,"item_type":1,"effect_class":"QuintCrit"},
	{"id":"cloud_step","display_name":"筋斗云","description":"当前战斗手牌上限8→9张","price":25,"rarity":1,"item_type":1,"effect_class":"CloudStep"},
	{"id":"seventy_two","display_name":"七十二变","description":"随机复制1个临时法宝Lv1效果，当前回合结束后失效","price":35,"rarity":1,"item_type":1,"effect_class":"SeventyTwo"},
]

func _initialize():
	call_deferred("_run")

func _wait_until(check: Callable, timeout_seconds: float = 5.0) -> bool:
	var elapsed := 0.0
	while elapsed < timeout_seconds:
		if check.call():
			return true
		await create_timer(0.05).timeout
		elapsed += 0.05
	return bool(check.call())

func _run():
	var items = root.get_node("ItemManager")
	var rounds = root.get_node("RoundManager")
	var deck = root.get_node("DeckManager")
	var boss = root.get_node("BossSkillManager")
	for item in MOCK_ITEMS: items.register_item_resource(item)
	for monster_row in rounds.MONSTER_TEXTURE_PATHS:
		for texture_path in monster_row:
			assert(ResourceLoader.exists(texture_path), "妖怪素材缺失：%s" % texture_path)
	for texture_path in rounds.BOSS_ENRAGED_TEXTURE_PATHS:
		assert(ResourceLoader.exists(texture_path), "Boss狂暴素材缺失：%s" % texture_path)
	for disguise_path in [
		"res://assets/monsters/baigujing-disguise-young.png",
		"res://assets/monsters/baigujing-disguise-old-woman.png",
		"res://assets/monsters/baigujing-disguise-old-man.png",
	]:
		assert(ResourceLoader.exists(disguise_path), "白骨精三重幻身素材缺失：%s" % disguise_path)
	for action_frame_path in [
		"res://assets/monsters/huangfengguai-charge.png",
		"res://assets/monsters/huangfengguai-breath.png",
		"res://assets/monsters/honghaier-spear-sweep.png",
		"res://assets/monsters/honghaier-true-fire.png",
	]:
		assert(ResourceLoader.exists(action_frame_path), "Boss独立动作帧素材缺失：%s" % action_frame_path)
	for background_path in rounds.BATTLE_BACKGROUND_PATHS:
		assert(ResourceLoader.exists(background_path), "主题战斗背景缺失：%s" % background_path)
	for artifact_id in items.ARTIFACT_IDS:
		assert(items.get_artifact_texture({"id": artifact_id}) != null, "法宝素材缺失：%s" % artifact_id)
	assert(items.ARTIFACT_IDS.has("artifact_bjs") and not items.ARTIFACT_IDS.has("artifact_jgb"), "法宝栏应以芭蕉扇替换金箍棒")
	assert(items.get_artifact_texture_path({"id":"artifact_bjs"}).ends_with("bajiaoshan.png"), "芭蕉扇应使用新的UI图")
	items.restore_items([{"id":"artifact_jgb", "level":2}], [])
	assert(items.jokers.size() == 1 and items.jokers[0].resource_data.get("id") == "artifact_bjs", "旧存档金箍棒法宝必须自动迁移为芭蕉扇")
	assert(items.jokers[0].resource_data.get("display_name") == "芭蕉扇" and items.jokers[0].level == 2, "迁移后应保留等级并替换名称")
	items.reset()
	assert(ResourceLoader.exists("res://assets/artifacts/jingubang-straight.png"), "攻击区应使用新的笔直金箍棒UI图")
	assert(ResourceLoader.exists(items.CONSUMABLE_ATLAS_PATH), "道具栏应使用统一的西游像素风图集")
	assert(items.get_consumable_texture({"id":"nine_elixir"}) != null, "道具图集应能正确切分九转金丹图标")
	items.restore_items([], ["nine_elixir", "double_potion", "mirror_reveal", "quint_crit"])
	assert(items.get_consumable_limit() == 3 and items.consumables.size() == 3, "每场战斗最多只能携带三个道具")
	assert(not items.can_add_consumable(), "三个道具槽占满后不可继续添加")

	# 行囊分别限制三个法宝和三个道具；出售按半价返还灵石并立即腾出槽位。
	items.reset()
	items.jokers = [
		items.create_item_effect(MOCK_ITEMS[0]),
		items.create_item_effect({"id":"artifact_zjl","display_name":"紫金铃","price":30,"item_type":0,"effect_class":"ZiJinLing"}),
		items.create_item_effect({"id":"artifact_rsg","display_name":"人参果","price":50,"item_type":0,"effect_class":"RenShenGuo"}),
	]
	rounds.game_coins = 100
	assert(items.get_artifact_limit() == 3 and not items.can_add_artifact(), "行囊最多只能保留三个法宝")
	assert(not items.buy_item(MOCK_ITEMS[1], 0) and rounds.game_coins == 100, "法宝槽满后不能继续购买法宝")
	var artifact_sell_price: int = items.sell_item(items.jokers[0])
	assert(artifact_sell_price == 17 and rounds.game_coins == 117 and items.can_add_artifact(), "出售法宝应返还半价灵石并腾出法宝槽")
	assert(items.buy_item(MOCK_ITEMS[1], 0) and items.jokers.size() == 3, "出售后应能购买新的法宝补入空槽")
	items.restore_items([], ["nine_elixir", "double_potion", "mirror_reveal"])
	var consumable_sell_price: int = items.sell_item(items.consumables[0])
	assert(consumable_sell_price == 4 and items.consumables.size() == 2 and items.can_add_consumable(), "出售道具应返还半价灵石并腾出道具槽")

	# 稀有道具整局限购一次；购买记录在消耗后仍保留，新开一局才清空。
	items.reset()
	rounds.game_coins = 100
	assert(items.buy_item(MOCK_ITEMS[5], 0), "首次购买稀有道具应成功")
	assert(items.has_purchased_rare_item("quint_crit"), "稀有道具购买后应写入本局购买记录")
	items.consume_instance(items.consumables[0])
	var coins_after_rare_purchase: int = rounds.game_coins
	assert(not items.buy_item(MOCK_ITEMS[5], 1) and rounds.game_coins == coins_after_rare_purchase, "稀有道具即使已经消耗，本局也不能再次购买")
	assert(items.is_shop_item_available(MOCK_ITEMS[4], 1), "白骨精通关前照妖镜仍可刷新")
	assert(not items.is_shop_item_available(MOCK_ITEMS[4], 2), "白骨精通关后照妖镜应退出刷新池")
	assert(items.is_shop_item_available({"id":"wind_calmer","rarity":1}, 4) and not items.is_shop_item_available({"id":"wind_calmer","rarity":1}, 5), "定风丹应在黄风怪通关后退出刷新池")
	assert(items.is_shop_item_available({"id":"holy_dew","rarity":1}, 7) and not items.is_shop_item_available({"id":"holy_dew","rarity":1}, 8), "净瓶甘露应在红孩儿通关后退出刷新池")

	# 七十二变复制的法宝参与当前战斗，但在回合结束钩子中自动移除。
	items.jokers = [items.create_item_effect(MOCK_ITEMS[0])]
	var copied_name: String = items.add_random_temporary_artifact_copy()
	assert(copied_name != "" and items.jokers.size() == 2, "七十二变应复制一个法宝")
	assert(items.jokers[1].is_temporary and items.jokers[1].level == 1, "复制法宝必须标记为Lv1临时法宝")
	assert(not items.upgrade_joker(items.jokers[1]) and items.jokers[1].level == 1, "临时法宝不可升级")
	items.on_round_end()
	assert(items.jokers.size() == 1 and not items.jokers[0].is_temporary, "回合结束后只清除七十二变复制的临时法宝")
	items.restore_items([{"id":"artifact_bjs","level":1,"temporary":true}], [], [], ["quint_crit"])
	assert(items.jokers[0].is_temporary and items.has_purchased_rare_item("quint_crit"), "存档恢复应保留当前回合临时法宝和稀有购买记录")
	items.reset()
	rounds.start_new_game()
	assert(items.purchased_rare_item_ids.is_empty(), "新开一局应清空稀有道具购买记录")
	assert(rounds.discards_left == 4, "v3.1 每场应有4次换牌")

	var bell = items.create_item_effect({"id":"artifact_zjl","display_name":"紫金铃","item_type":0,"effect_class":"ZiJinLing"})
	var pair_hand = {"rank":1}
	assert(bell.get_preview_modifiers(pair_hand).mult_add == 0.0, "预览不应提前推进连锁")
	assert(bell.get_passive_modifiers(pair_hand).mult_add == 0.0, "紫金铃首手不加倍率")
	assert(bell.get_passive_modifiers(pair_hand).mult_add == 4.0, "紫金铃第二手应加4倍率")

	var frenzy = items.create_item_effect(MOCK_ITEMS[3])
	items.consumables = [frenzy]
	assert(frenzy.get_use_timing() == "round")
	assert(items.activate_round_consumable(frenzy))
	assert(items.consumables.is_empty() and items.active_round_consumables.size() == 1)
	assert(frenzy.get_score_modifiers().mult_add == 3.0)
	var quint = items.create_item_effect(MOCK_ITEMS[5])
	assert(quint.get_score_modifiers().crit_rate_add == 0.45)
	rounds.current_blind = 2
	var sword = items.create_item_effect({"id":"boss_burst","display_name":"斩妖剑","item_type":1,"effect_class":"BossBurst"})
	var clone = items.create_item_effect({"id":"clone_spell","display_name":"分身术","item_type":1,"effect_class":"CloneSpell"})
	var ordered = root.get_node("ScoreCalculator").preview_params(
		{"base_chips":10,"card_chips":30,"base_mult":2,"rank":1,"cards":[]}, [], [sword, clone], [])
	assert(ordered.mult == 18.0, "倍率加成必须先于斩妖剑乘数，且不受选择顺序影响")

	# 三昧真火必须真实阻断非指定牌型，而不只是显示提示。
	items.reset()
	deck.reset()
	rounds.current_round = 2
	rounds.current_blind = 2
	rounds.round_score = 0
	rounds.plays_left = 4
	boss.reset()
	boss.current_skill = boss.BossSkill.HOLY_FIRE
	var first_cards = deck.hand.slice(0, 5)
	var evaluated = root.get_node("HandEvaluator").evaluate(first_cards)
	boss.allowed_hand_ranks = [(int(evaluated.rank) + 1) % 9]
	var blocked = rounds.play_hand([0, 1, 2, 3, 4], [])
	assert(blocked.score == 0 and blocked.blocked_by_boss, "三昧真火应将非指定牌型伤害归零")

	rounds.current_round = 0
	rounds.current_blind = 2
	rounds.round_score = 420
	rounds.boss_enraged = false
	rounds.boss_enrage_score_start = 0
	rounds.plays_left = 4
	rounds.discards_left = 4
	assert(not rounds.is_current_boss_enraged(), "白骨精剩余血量高于30%时应保持初始形态")
	assert(rounds.get_current_monster_texture_path().ends_with("baigujing.png"))
	rounds.game_coins = 168
	rounds.total_score = 1260
	items.reset()
	deck.reset()
	boss.apply_skill(0, 2)
	boss.execute_skill_on_hand(deck.hand)
	items.jokers = [items.create_item_effect(MOCK_ITEMS[0]), items.create_item_effect(MOCK_ITEMS[1])]
	items.consumables = [items.create_item_effect(MOCK_ITEMS[2]), items.create_item_effect(MOCK_ITEMS[3]), items.create_item_effect(MOCK_ITEMS[4])]

	if DisplayServer.get_name() != "headless":
		var main = load("res://scenes/Main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		assert(root.get_texture().get_image().save_png("/tmp/poker_main.png") == OK)
		main.queue_free()
		await process_frame

	var board = load("res://scenes/GameBoard.tscn").instantiate()
	root.add_child(board)
	await process_frame
	board._refresh_all()
	await process_frame
	assert(not board.get_node("MainVBox/TopBar").visible, "战斗界面不应显示轮次或钻石状态栏")
	assert(not board.get_node("MainVBox/ScoreContainer").visible, "旧的顶部血量区应隐藏")
	assert(board.monster_health_panel.visible, "妖怪血量必须放在角色头顶")
	assert(board.round_turn_label.text == "第1轮 · 第3回合", "血条右侧应显示当前轮次与回合")
	assert(board.round_turn_badge.global_position.x > board.monster_health_panel.global_position.x + board.monster_health_panel.size.x, "轮次回合标记应放在妖怪血条右侧")
	assert(board.round_turn_badge.size.x < board.monster_health_panel.size.x * 0.70 and board.round_turn_badge.get_meta("compact_round_turn", false), "轮次回合区域应保持紧凑")
	assert(not board.threshold_label.visible, "头顶血条只保留血量数值，避免重复显示妖怪名称")
	assert(not board.monster_title.visible and board.score_label.text.find("白骨精") != -1, "妖怪名称应收进血条，不再单独占据空间")
	assert(board.artifact_bar_label.text.begins_with("法宝 ") and board.artifact_bar_label.text.ends_with("/3"), "法宝标题应精简展示三格携带状态")
	assert(board.consumable_bar_label.text == "道具 3/3", "出牌区道具栏应显示三格携带状态")
	var play_surface = board.get_node("MainVBox/PlaySurface")
	var hand_row = board.get_node("MainVBox/HandRow")
	var artifact_dock = board.get_node("MainVBox/ArtifactDock")
	var consumable_dock = board.get_node("MainVBox/HandRow/HandContent/ConsumableDock")
	assert(not board.has_node("MainVBox/HandRow/HandContent/HandHintLabel"), "出牌区不应保留选牌0/5状态框")
	assert(play_surface.size.y >= board.size.y * 0.41 and play_surface.size.y <= board.size.y * 0.45, "妖怪舞台应独立占据画面上方约43%")
	assert(hand_row.size.y >= board.size.y * 0.42, "下方道具与手牌区应占据约44%的画面")
	assert(board.operation_area_bg.position.y <= hand_row.global_position.y + 3.0, "底部操作台必须与手牌区边界对齐并完整承托操作")
	assert(board.battle_background.texture.resource_path == rounds.get_current_battle_background_path(), "战斗背景必须跟随当前主题")
	assert(board.battle_background.size.y <= board.size.y * 0.44, "妖怪场景背景必须在装备区上方结束，不能继续铺到装备和手牌后面")
	assert(board.get_node("EquipmentAreaBG").position.y >= board.battle_background.position.y + board.battle_background.size.y - 2.0, "装备区必须拥有独立不透明背景层")
	assert(board.monster_avatar.size.x >= play_surface.size.x * 0.59, "妖怪形象应占据战斗区的视觉中心")
	assert(artifact_dock.get_parent() == board.main_vbox and artifact_dock.global_position.y >= play_surface.global_position.y + play_surface.size.y - 2.0, "装备与法宝必须是妖怪舞台之外的独立中间层")
	assert(artifact_dock.size.x > play_surface.size.x * 0.94, "中间装备栏应接近横向铺满，形成独立分区")
	assert(consumable_dock.global_position.y >= hand_row.global_position.y, "道具栏必须移入底部出牌区域")
	assert(consumable_dock.size.x >= board.size.x * 0.20 and consumable_dock.size.x <= board.size.x * 0.28, "道具栏应固定占据下方左侧约四分之一")
	assert(board.play_button.global_position.x > consumable_dock.global_position.x + consumable_dock.size.x and board.play_button.global_position.x < board.discard_button.global_position.x, "手牌区上方应按草图从左到右排列出牌、换牌按钮")
	assert(board.sort_dock.global_position.y > board.hand_area.global_position.y + board.hand_area.size.y * 0.78, "按大小、按花色按钮应位于手牌区底部")
	assert(board.monster_health_panel.global_position.y < board.monster_avatar.global_position.y + board.monster_avatar.size.y * 0.22, "血条应位于妖怪头顶区域")
	assert(board.get_node("MainVBox/ArtifactDock").get_meta("wooden_frame", false), "法宝装备栏必须使用木质外框")
	assert(board.get_node("MainVBox/ArtifactDock").get_meta("weapon_artifact_dock", false), "装备栏应使用武器与法宝一体式木框")
	assert(board.get_node("MainVBox/HandRow/HandContent/ConsumableDock").get_meta("wooden_frame", false), "出牌区道具栏必须使用木质外框")
	assert(board.joker_slots.get_child_count() >= board.ARTIFACT_SLOT_COUNT, "法宝栏应展示完整装备槽")
	assert(board.cons_slots.get_child_count() >= board.CONSUMABLE_SLOT_COUNT, "道具栏应展示完整道具槽")
	assert(board.joker_slots.alignment == BoxContainer.ALIGNMENT_CENTER, "法宝槽应在装备分区内横向居中，避免右侧无意义留白")
	assert(board.cons_slots.alignment == BoxContainer.ALIGNMENT_CENTER, "道具槽应在左侧栏内纵向居中，而不是挂在顶部")
	assert(board.joker_slots.get_child(0) is Button and not board.joker_slots.get_child(0).flat)
	assert(board.joker_slots.get_child(0).get_meta("wooden_slot", false), "法宝图标必须位于木质装备槽中")
	assert(board.joker_slots.get_child(0).text == "", "法宝栏只保留图标")
	assert(board.cons_slots.get_child(0) is Button and not board.cons_slots.get_child(0).flat)
	assert(board.cons_slots.get_child(0).get_meta("wooden_slot", false), "道具图标必须位于木质道具槽中")
	assert(board.cons_slots.get_child(0).text.find("\n") == -1, "道具栏只保留单个图标")
	assert(board.joker_slots.get_child(0).custom_minimum_size.x > board.cons_slots.get_child(0).custom_minimum_size.x, "法宝图标应明显大于道具图标")
	assert(is_equal_approx(board.attack_stick_button.size.x, board.joker_slots.get_child(0).custom_minimum_size.x), "待机金箍棒必须与法宝槽保持同样大小")
	assert(board.attack_stick_button.get_parent() == artifact_dock and board.attack_stick_button.get_meta("weapon_slot", false), "金箍棒必须成为装备栏中的武器槽")
	assert(board.attack_stick_button.global_position.x < board.joker_slots.get_child(0).global_position.x, "武器与法宝必须在同一横排依次展示")
	assert(absf((board.attack_stick_button.global_position.y + board.attack_stick_button.size.y * 0.5) - (board.joker_slots.get_child(0).global_position.y + board.joker_slots.get_child(0).size.y * 0.5)) < 8.0, "武器与法宝槽需要保持横向对齐")
	assert(board.attack_stick_button.size.x < board.monster_avatar.size.x * 0.35, "待机金箍棒必须明显小于妖怪")
	assert(not board.boss_phase_badge.visible and board.boss_phase_badge.text == "", "Boss形态不应使用文字标签展示")
	var health_style = board.monster_health_panel.get_theme_stylebox("panel")
	assert(health_style is StyleBoxFlat and board.monster_health_panel.get_meta("health_capsule_v3", false), "妖怪名称与生命值应收进统一的低矮胶囊")
	assert(board.monster_health_panel.size.y < 60.0, "妖怪头顶血条应保持紧凑")
	assert(board.operation_area_bg.get_meta("unified_battle_hud_v3", false), "战斗操作区应使用统一的墨色漆木视觉语言")

	# 精英怪必须先走拦路对话，再演示本场真实减益，最后才解锁牌桌。
	rounds.current_round = 0
	rounds.current_blind = 1
	rounds.round_score = 0
	rounds.plays_left = 4
	rounds.discards_left = 4
	deck.reset()
	boss.apply_skill(0, 1)
	boss.execute_skill_on_hand(deck.hand)
	board._shown_encounter_intros.clear()
	board._on_phase_changed(rounds.Phase.PLAYING)
	await process_frame
	assert(await _wait_until(func(): return not board.encounter_continue_button.disabled, 2.0), "精英怪进场后应开放对话按钮")
	assert(board.encounter_intro.visible and board._encounter_intro_kind == "elite", "精英怪应先停留在拦路对话页")
	assert(board.encounter_name_label.text == "骷髅将" and board.encounter_skill_name.text.find("枯骨锁魂") != -1, "对话页应展示精英身份和专属减益")
	assert(board.play_button.disabled and boss.elite_locked_cards.size() == 1, "进入战斗前应封锁牌桌，并已确定本场被锁手牌")
	if DisplayServer.get_name() != "headless":
		assert(root.get_texture().get_image().save_png("/tmp/poker_elite_intro.png") == OK)
	board.encounter_continue_button.pressed.emit()
	assert(await _wait_until(func(): return board._encounter_dialogue_index == 1 and not board.encounter_continue_button.disabled, 1.0), "精英对话应可点击推进到挑衅台词")
	assert(board.encounter_continue_button.text.find("迎战") != -1, "最后一句对话后按钮应切换为迎战")
	board.encounter_continue_button.pressed.emit()
	assert(await _wait_until(func(): return not board.encounter_intro.visible, 2.0), "减益演示结束后应进入牌桌")
	assert(not board.play_button.disabled and board.encounter_intro.get_meta("effect_preview_ready", false), "点击迎战后应完成减益落地并解锁出牌")

	# 三位大妖分别播放白骨三变、黄风神风、火云真火，且规则预览读取实际技能状态。
	var boss_intro_stages: Dictionary = {}
	var static_action_snapshots: Dictionary = {}
	var boss_intro_observer = func(stage: String):
		boss_intro_stages[stage] = true
		if stage in ["yellow_wind_charge", "yellow_wind_breath", "holy_fire_spear_sweep", "holy_fire_true_fire"]:
			static_action_snapshots[stage] = {
				"texture": board.encounter_portrait.texture.resource_path,
				"position": board.encounter_portrait.position,
				"rotation": board.encounter_portrait.rotation,
				"scale": board.encounter_portrait.scale,
			}
		if DisplayServer.get_name() != "headless" and stage in [
			"white_bone_form_young", "white_bone_form_old_woman", "white_bone_form_old_man", "boss_white_bone_true_form",
			"yellow_wind_charge", "yellow_wind_breath", "holy_fire_spear_sweep", "holy_fire_true_fire",
		]:
			root.get_texture().get_image().save_png("/tmp/poker_%s.png" % stage)
	board.encounter_intro_stage.connect(boss_intro_observer)
	var expected_variants := ["white_bone", "yellow_wind", "holy_fire"]
	var expected_stages := ["boss_white_bone_three_forms", "boss_yellow_wind_storm", "boss_holy_fire_burst"]
	var screenshot_names := ["baigujing", "huangfengguai", "honghaier"]
	for boss_round in range(3):
		rounds.current_round = boss_round
		rounds.current_blind = 2
		rounds.round_score = 0
		rounds.plays_left = 4
		rounds.discards_left = 4
		deck.reset()
		boss.apply_skill(boss_round, 2)
		boss.execute_skill_on_hand(deck.hand)
		board._refresh_all()
		board._begin_encounter_intro(true)
		assert(await _wait_until(func(): return board.encounter_continue_button.visible and not board.encounter_continue_button.disabled, 10.0), "大妖主题演出应完整结束并开放迎战")
		assert(board.encounter_intro.get_meta("encounter_variant", "") == expected_variants[boss_round], "每位大妖必须使用独立原著主题动画")
		assert(boss_intro_stages.has(expected_stages[boss_round]), "大妖演出必须触发对应主题关键帧")
		assert(board.encounter_intro.get_meta("effect_preview_ready", false), "Boss出场应演示专属限制如何落到本场牌桌")
		if boss_round == 0:
			assert(boss.phantom_cards.size() == 2, "白骨幻术预演应对应两张真实幻影牌")
			for form_stage in ["white_bone_form_young", "white_bone_form_old_woman", "white_bone_form_old_man", "boss_white_bone_true_form"]:
				assert(boss_intro_stages.has(form_stage), "白骨精必须完整播放少女、老妇、老翁与真身四个关键帧：%s" % form_stage)
			assert(board.encounter_portrait.texture.resource_path.ends_with("baigujing.png"), "三重幻身全部破除后才可显示白骨精真身")
		elif boss_round == 1:
			assert(boss.face_down_cards.size() == 3, "风沙走石预演应对应三张真实暗牌")
			for action_stage in ["yellow_wind_charge", "yellow_wind_breath"]:
				assert(boss_intro_stages.has(action_stage), "黄风怪必须切换到独立蓄风与吐风动作帧：%s" % action_stage)
			assert(not boss_intro_stages.has("yellow_wind_trident_sweep"), "黄风怪不应再用旋转待机图模拟挥叉")
			assert(board.encounter_intro.get_meta("action_frame_mode", "") == "static_texture_switch", "黄风怪动作必须使用静态纹理切换模式")
			assert(static_action_snapshots.yellow_wind_charge.texture.ends_with("huangfengguai-charge.png"))
			assert(static_action_snapshots.yellow_wind_breath.texture.ends_with("huangfengguai-breath.png"))
			assert(static_action_snapshots.yellow_wind_charge.position == static_action_snapshots.yellow_wind_breath.position and is_equal_approx(static_action_snapshots.yellow_wind_charge.rotation, 0.0) and static_action_snapshots.yellow_wind_charge.scale == static_action_snapshots.yellow_wind_breath.scale, "黄风动作帧之间只能换图，不能移动、旋转或挤压立绘")
		else:
			assert(boss.allowed_hand_ranks.size() == 2 and board.encounter_effect_preview.get_child_count() == 3, "三昧真火应亮出本场两种可用牌型并封住其余牌路")
			for action_stage in ["holy_fire_spear_sweep", "holy_fire_true_fire"]:
				assert(boss_intro_stages.has(action_stage), "红孩儿必须切换到独立挥枪与喷火动作帧：%s" % action_stage)
			assert(not boss_intro_stages.has("holy_fire_cloud_jump"), "红孩儿不应再通过移动待机图模拟踏云跃起")
			assert(board.encounter_intro.get_meta("action_frame_mode", "") == "static_texture_switch", "红孩儿动作必须使用静态纹理切换模式")
			assert(static_action_snapshots.holy_fire_spear_sweep.texture.ends_with("honghaier-spear-sweep.png"))
			assert(static_action_snapshots.holy_fire_true_fire.texture.ends_with("honghaier-true-fire.png"))
			assert(static_action_snapshots.holy_fire_spear_sweep.position == static_action_snapshots.holy_fire_true_fire.position and is_equal_approx(static_action_snapshots.holy_fire_spear_sweep.rotation, 0.0) and static_action_snapshots.holy_fire_spear_sweep.scale == static_action_snapshots.holy_fire_true_fire.scale, "红孩儿动作帧之间只能换图，不能移动、旋转或挤压立绘")
		if DisplayServer.get_name() != "headless":
			assert(root.get_texture().get_image().save_png("/tmp/poker_boss_intro_%s.png" % screenshot_names[boss_round]) == OK)
		board.encounter_continue_button.pressed.emit()
		assert(await _wait_until(func(): return not board.encounter_intro.visible, 1.5), "点击破阵迎战后应回到牌桌")
	board.encounter_intro_stage.disconnect(boss_intro_observer)

	# 恢复后续交互与伤害动画测试使用的白骨精初始战斗状态。
	rounds.current_round = 0
	rounds.current_blind = 2
	rounds.round_score = 420
	rounds.boss_enraged = false
	rounds.boss_enrage_score_start = 0
	rounds.plays_left = 4
	rounds.discards_left = 4
	deck.reset()
	boss.apply_skill(0, 2)
	boss.execute_skill_on_hand(deck.hand)
	board._refresh_all()
	await process_frame
	board.joker_slots.get_child(0).pressed.emit()
	assert(board.joker_detail_overlay.visible and not board.joker_detail_use.visible, "点击法宝图标应只展示法宝详情")
	board.joker_detail_overlay.visible = false
	assert(board.play_count_label.text == "出牌 ×4" and not board.play_action_label.visible, "出牌按钮应按草图只显示动作与剩余次数")
	assert(board.discard_count_label.text == "换牌 ×4" and not board.discard_action_label.visible, "换牌按钮应按草图只显示动作与剩余次数")
	assert(board.play_button.get_meta("action_button_v2", false), "出牌按钮应使用新的主操作样式")
	assert(board.discard_button.get_meta("action_button_v2", false), "换牌按钮应使用新的次操作样式")
	assert(absf(board.play_button.size.x - board.discard_button.size.x) < 2.0, "出牌与换牌按钮应按草图使用等宽布局")
	assert(board.sort_by_rank_btn.get_meta("active_sort", false), "默认点数排序应显示选中状态")
	board.sort_by_suit_btn.pressed.emit()
	assert(board.sort_by_suit_btn.get_meta("active_sort", false) and not board.sort_by_rank_btn.get_meta("active_sort", false), "花色排序后应切换胶囊选中态")
	board.sort_by_rank_btn.pressed.emit()
	assert(board.sort_by_rank_btn.get_meta("active_sort", false), "切回点数排序后应恢复选中态")
	if DisplayServer.get_name() != "headless":
		await process_frame
		var board_image = root.get_texture().get_image()
		assert(board_image.save_png("/tmp/poker_gameboard.png") == OK)
		rounds.current_round = 1
		board._update_ui()
		await process_frame
		assert(board.battle_background.texture.resource_path.ends_with("yellow-wind-ridge.png"))
		assert(root.get_texture().get_image().save_png("/tmp/poker_gameboard_yellow_wind.png") == OK)
		rounds.current_round = 2
		board._update_ui()
		await process_frame
		assert(board.battle_background.texture.resource_path.ends_with("fire-cloud-cave.png"))
		assert(root.get_texture().get_image().save_png("/tmp/poker_gameboard_fire_cloud.png") == OK)
		rounds.current_round = 0
		board._update_ui()
		await process_frame

	# 四种法宝必须使用各自的慢速主题动画，而不是共用一次短促闪光。
	var gameplay_jokers: Array = items.jokers.duplicate()
	items.jokers = [
		items.create_item_effect(MOCK_ITEMS[0]),
		items.create_item_effect({"id":"artifact_zjl","display_name":"紫金铃","item_type":0,"effect_class":"ZiJinLing"}),
		items.create_item_effect({"id":"artifact_rsg","display_name":"人参果","item_type":0,"effect_class":"RenShenGuo"}),
		items.create_item_effect(MOCK_ITEMS[1]),
	]
	board._rebuild_jokers()
	board._set_damage_zone_visible(true)
	await board._fly_stick_into_battle()
	var artifact_effect_stages: Dictionary = {}
	var artifact_effect_observer = func(stage: String):
		if stage in ["artifact_bjs", "artifact_zjl", "artifact_rsg", "artifact_hyjj"]:
			artifact_effect_stages[stage] = true
			if DisplayServer.get_name() != "headless":
				root.get_texture().get_image().save_png("/tmp/poker_%s.png" % stage)
	board.damage_animation_stage.connect(artifact_effect_observer)
	var expected_effect_kinds := ["wind_sweep", "triple_bell_wave", "golden_fruit_bloom", "truth_scan"]
	for artifact_index in range(4):
		await board._bounce_joker_badge(artifact_index)
		var artifact_node = board._joker_badge_nodes[artifact_index]
		assert(artifact_node.get_meta("last_artifact_effect_kind", "") == expected_effect_kinds[artifact_index], "每种法宝应播放符合自身特点的独立动画")
		assert(int(artifact_node.get_meta("last_artifact_effect_duration_ms", 0)) >= 800, "法宝生效动画应放慢到足够看清")
	board.damage_animation_stage.disconnect(artifact_effect_observer)
	assert(artifact_effect_stages.size() == 4, "芭蕉扇、紫金铃、人参果和火眼金睛都应有专属动画阶段")
	board._set_damage_zone_visible(false)
	items.jokers = gameplay_jokers
	board._rebuild_jokers()

	# 手牌必须重叠但仍保留足够点击宽度；选中牌应原位高亮且不遮挡相邻牌。
	assert(board._card_nodes.size() >= 8)
	assert(board._card_nodes[0].get_meta("card_face_v2", false), "扑克牌应使用新的角标、花色水印牌面")
	assert(board._card_nodes[0].has_node("RankLabel") and board._card_nodes[0].has_node("PipLabel"), "扑克牌必须拆分点数与花色层级")
	var exposed_width = board._card_nodes[1].position.x - board._card_nodes[0].position.x
	assert(exposed_width >= 34.0 and exposed_width < board.HAND_CARD_SIZE.x, "手牌应重叠且每张至少露出34px")
	var selectable_indices: Array = []
	for i in range(deck.hand.size()):
		if boss.is_card_selectable(i, deck.hand):
			selectable_indices.append(i)
			if selectable_indices.size() == 5:
				break
	assert(selectable_indices.size() == 5)
	var selected_position_before: Vector2 = board._card_nodes[selectable_indices[0]].position
	for idx in selectable_indices:
		board._on_card_pressed(idx)
	await create_timer(0.20).timeout
	assert(board._selected_indices.size() == 5)
	var selected_node = board._card_nodes[selectable_indices[0]]
	assert(selected_node.position.distance_to(selected_position_before) < 1.0 and selected_node.scale == Vector2.ONE, "选中牌必须保持原位且不缩放弹出")
	assert(selected_node.z_index == selectable_indices[0], "选中牌应保持自然叠放层级，不能遮挡右侧手牌")
	if selectable_indices[0] + 1 < board._card_nodes.size():
		assert(board._card_nodes[selectable_indices[0] + 1].z_index > selected_node.z_index, "右侧相邻牌应继续显示在选中牌上方")
	assert(selected_node.get_meta("selected_card", false) and selected_node.get_node("StateLabel").text == "✓", "选中牌应改用金色高亮和勾选标记")
	assert(selected_node.get_node("StateLabel").anchor_right <= 0.5, "选中勾应位于叠牌后仍可见的左侧区域")
	assert(board.play_action_label.text.find("≈") == -1, "选牌阶段不应提前计算或展示伤害")
	if DisplayServer.get_name() != "headless":
		assert(root.get_texture().get_image().save_png("/tmp/poker_gameboard_selected.png") == OK)

	board.attack_stick_button.pressed.emit()
	assert(board.joker_detail_overlay.visible)
	assert(board.joker_detail_params.get_child_count() >= 13, "攻击信息应含暴击、公式和九种牌型规则")
	var has_history_title := false
	var has_selected_calc := false
	for detail_node in board.joker_detail_params.get_children():
		if detail_node is Label and detail_node.text == "本场出牌伤害记录":
			has_history_title = true
		if detail_node is Label and detail_node.text == "当前选牌计算明细":
			has_selected_calc = true
	assert(has_history_title and not has_selected_calc, "金箍棒详情应展示实际出牌历史，不应计算当前选牌")
	await process_frame
	if DisplayServer.get_name() != "headless":
		assert(root.get_texture().get_image().save_png("/tmp/poker_attack_info.png") == OK)
	board.joker_detail_overlay.visible = false

	# 用真实计分结果播放完整飞牌/滚动/暴击动画，并在关键帧自动留图。
	var played_cards: Array = []
	var source_nodes: Array = []
	for idx in selectable_indices:
		played_cards.append(deck.hand[idx])
		source_nodes.append(board._card_nodes[idx])
	var hp_text_before_hit: String = str(board.score_label.text)
	board._begin_damage_visual_transaction()
	var animated_result = rounds.play_hand(selectable_indices, [])
	assert(board.score_label.text == hp_text_before_hit, "完成模型计分后、金箍棒命中前不得提前扣血")
	var non_crit_score = int(animated_result.chips * animated_result.mult * animated_result.special_mult)
	animated_result.is_crit = true
	animated_result.crit_mult = 2.0
	animated_result.score = non_crit_score * 2
	assert(board._get_stick_target_scale(10000) > board._get_stick_target_scale(100), "金箍棒目标尺寸必须随伤害量级增长")
	var animation_observed := {"stick_flight": false, "stick_arrival": false, "stick_growth": false, "artifact_boost": false, "attack_value": false, "impact_damage": false, "spiky_damage": false, "monster_shake": false, "stick_return": false, "hp_held": false, "hp_committed": false}
	var monster_transform_before_hit := {"position": Vector2.ZERO, "rotation": 0.0, "scale": Vector2.ONE}
	board.damage_animation_stage.connect(func(stage: String):
		if stage == "stick_flying":
			animation_observed.stick_flight = board.strike_stick.visible and board.strike_stick.get_meta("flight_spin_observed", false)
		elif stage == "stick_arrived":
			var stick_center: Vector2 = board.strike_stick.get_global_transform() * (board.strike_stick.size * 0.5)
			# 妖怪自身有轻微待机漂浮，允许抵达点随立绘移动产生少量偏差。
			animation_observed.stick_arrival = stick_center.distance_to(board._get_stick_battle_center()) < 20.0 and board.strike_stick.scale.y >= 1.3 and board.strike_stick.scale.x / board.strike_stick.scale.y >= 1.8
		elif stage == "mult_done":
			animation_observed.stick_growth = board.strike_stick.scale.x > 1.0
			animation_observed.hp_held = board.score_label.text == hp_text_before_hit
		if stage == "artifact_boost":
			animation_observed.artifact_boost = true
		if stage == "critical":
			animation_observed.attack_value = board.score_burst_label.visible and board.score_burst_label.get_theme_font_size("font_size") == 64
		if stage == "spiky_damage":
			animation_observed.spiky_damage = board.monster_damage_label.get_meta("spiky_damage_value", false) and board._damage_spike_nodes.size() >= 3 and board._damage_spike_nodes.all(func(spike): return spike.get_meta("spiky_damage_value", false))
		if stage == "monster_hit_shake":
			monster_transform_before_hit.position = board.monster_avatar.position
			monster_transform_before_hit.rotation = board.monster_avatar.rotation
			monster_transform_before_hit.scale = board.monster_avatar.scale
			var shake_power := float(board.monster_avatar.get_meta("last_hit_shake_power", 0.0))
			animation_observed.monster_shake = board.monster_avatar.get_meta("hit_shake_active", false) and shake_power >= 2.0 and shake_power <= 5.0
		if stage == "stick_impact":
			var impact_center: Vector2 = board.strike_stick.get_meta("last_actual_tip", Vector2.ZERO)
			# 妖怪已在命中帧开始抖动；用挥击开始时锁定的头部落点校验棒头命中精度。
			var head_center: Vector2 = board.strike_stick.get_meta("last_impact_center", Vector2.ZERO)
			animation_observed.impact_damage = board.monster_damage_label.visible and board.monster_damage_label.text.find(str(animated_result.score)) != -1 and impact_center.distance_to(head_center) < 20.0
			animation_observed.hp_committed = board.score_label.text != hp_text_before_hit
		if stage == "stick_returned":
			animation_observed.stick_return = not board.strike_stick.visible and board.attack_stick_button.visible and board.strike_stick.get_meta("return_shrink_observed", false)
		if DisplayServer.get_name() == "headless":
			return
		if stage == "stick_flying":
			root.get_texture().get_image().save_png("/tmp/poker_stick_flying.png")
		elif stage == "stick_arrived":
			root.get_texture().get_image().save_png("/tmp/poker_stick_arrived.png")
		elif stage == "card_3":
			root.get_texture().get_image().save_png("/tmp/poker_attack_numbers.png")
		elif stage == "artifact_boost":
			root.get_texture().get_image().save_png("/tmp/poker_artifact_boost.png")
		elif stage == "stick_impact":
			root.get_texture().get_image().save_png("/tmp/poker_monster_damage.png")
		elif stage == "stick_returned":
			root.get_texture().get_image().save_png("/tmp/poker_stick_returned.png")
		elif stage == "critical":
			root.get_texture().get_image().save_png("/tmp/poker_damage_critical.png")
	)
	await board._show_calc_animation(animated_result, played_cards, source_nodes)
	assert(board.damage_zone.visible and board.attack_stick_button.visible, "金箍棒结算后应缩小并回归武器槽")
	assert(not board.damage_zone_title.visible and not board.damage_chips_label.visible and not board.damage_mult_label.visible, "结算界面不应再展示大面板、伤害/倍率分栏")
	assert(not board.formula_label.visible and not board.played_center.visible, "计算公式与落地牌应移入金箍棒详情")
	assert(board.score_burst_label.get_theme_font_size("font_size") == 64, "暴击后攻击数值应明显放大")
	assert(animation_observed.stick_flight, "金箍棒应旋转着从武器槽飞出")
	assert(animation_observed.stick_arrival, "金箍棒应先飞到妖怪旁边，再开始结算")
	assert(animation_observed.stick_growth, "攻击数值变化时金箍棒应持续变大")
	assert(animation_observed.artifact_boost, "法宝加成时应播放能量注入金箍棒的动效")
	assert(animation_observed.attack_value, "挥击前应只展示放大的攻击数值")
	assert(animation_observed.impact_damage, "金箍棒击中妖怪时应显示最终伤害数额")
	assert(animation_observed.spiky_damage, "最终伤害数值后方应出现多层尖刺爆裂效果")
	assert(animation_observed.monster_shake, "金箍棒命中时妖怪自身应立即播放高频受击抖动")
	assert(animation_observed.stick_return, "金箍棒命中后应旋转缩小并回归武器槽")
	assert(animation_observed.hp_held and animation_observed.hp_committed, "血量必须保持到命中帧，并在命中后扣除")
	assert(board.monster_avatar.get_meta("hit_returned_to_origin", false), "打击结束后妖怪必须完成原位置复位")
	assert(board.monster_shake_root.position == board._monster_shake_origin_position and board.monster_shake_root.get_meta("returned_to_zero", false), "独立受击容器在抖动后必须严格回到命中前的位置")
	assert(board.monster_avatar.position.distance_to(monster_transform_before_hit.position) < 0.01 and is_equal_approx(board.monster_avatar.rotation, monster_transform_before_hit.rotation) and board.monster_avatar.scale == monster_transform_before_hit.scale, "妖怪本体的坐标、旋转与缩放不应被受击动画改变")
	var stable_monster_position: Vector2 = board.monster_avatar.position
	for repeated_hit in range(5):
		board._start_monster_hit_reaction(600 + repeated_hit * 900, repeated_hit == 4, false)
		await create_timer(0.18).timeout
		assert(board.monster_shake_root.position == board._monster_shake_origin_position, "连续受击后抖动容器仍必须回到命中前的位置：第%d次" % (repeated_hit + 1))
		assert(board.monster_avatar.position.distance_to(stable_monster_position) < 0.01, "连续受击不能让妖怪本体产生累计偏移：第%d次" % (repeated_hit + 1))
	board._reset_inline_calc()
	board.attack_stick_button.pressed.emit()
	var history_labels = board.joker_detail_params.find_children("*", "Label", true, false)
	var has_first_play_formula := false
	for history_label in history_labels:
		if history_label.text.find("第1次") != -1 or (history_label.text.find(" × ") != -1 and history_label.text.find(" = ") != -1):
			has_first_play_formula = true
	assert(has_first_play_formula, "金箍棒详情必须记录本场第一次出牌的实际伤害公式")
	if DisplayServer.get_name() != "headless":
		await process_frame
		assert(root.get_texture().get_image().save_png("/tmp/poker_attack_history.png") == OK)
	board.joker_detail_overlay.visible = false
	board._rebuild_hand()
	await process_frame
	await board._impact_feedback(5000, true, false)

	# 大妖剩余血量到 30% 时切换第二形态，并完整播放一次狂暴反馈。
	# 先明确回到30%血线之外，避免上面的真实计分动画随机跨线并提前消费转场。
	rounds.round_score = 900
	rounds.boss_enraged = false
	rounds.boss_enrage_score_start = 0
	board._update_ui()
	board._enrage_transition_pending = false
	assert(not rounds.is_current_boss_enraged(), "狂暴转场测试开始前应处于第一形态")
	rounds.round_score = 1050
	var plays_before_enrage: int = rounds.plays_left
	var discards_before_enrage: int = rounds.discards_left
	rounds._enter_boss_enrage()
	board._update_ui()
	assert(rounds.is_current_boss_enraged(), "白骨精剩余30%血量时应进入狂暴形态")
	assert(rounds.get_current_threshold() == 2250 and rounds.get_current_monster_health() == 2250, "狂暴后应回满血，且血量上限提升至原始血量的150%")
	assert(rounds.plays_left == plays_before_enrage + 4 and rounds.discards_left == discards_before_enrage + 4, "狂暴后玩家应各获得4次额外出牌与弃牌机会")
	assert(rounds.get_current_monster_texture_path().ends_with("baigujing_enraged.png"))
	assert(board._enrage_transition_pending, "跨过30%血线应排队播放狂暴转场")
	assert(board.backdrop.battle_enraged and board.battle_background.modulate.r > board.battle_background.modulate.g, "狂暴后战斗背景应切换为更激烈的赤红动态效果")
	await board._impact_feedback(450, false, false)
	assert(not board._enrage_transition_pending, "狂暴转场播放后应清除排队状态")
	assert(not board.boss_phase_badge.visible and board.boss_phase_badge.text == "", "狂暴形态必须只通过立绘与特效展示")
	assert(not board.combo_banner.visible or board.combo_banner.text.find("狂暴") == -1, "狂暴转场不应出现文字提示")
	if DisplayServer.get_name() != "headless":
		var enraged_image = root.get_texture().get_image()
		assert(enraged_image.save_png("/tmp/poker_gameboard_enraged.png") == OK)
	var combat_frenzy = items.get_consumable_by_id("double_potion")
	board._on_consumable_used("double_potion", combat_frenzy, null)
	assert(items.active_round_consumables.has(combat_frenzy), "狂战药水应进入整场持续状态")
	var combat_mirror = items.get_consumable_by_id("mirror_reveal")
	board._on_consumable_used("mirror_reveal", combat_mirror, null)
	assert(boss.skill_suppressed, "照妖镜应整场压制白骨幻术")
	var combat_elixir = items.get_consumable_by_id("nine_elixir")
	board._show_consumable_detail(combat_elixir)
	assert(board.joker_detail_use.visible and not board.joker_detail_use.disabled, "道具详情中应提供使用选择")
	await process_frame
	if DisplayServer.get_name() != "headless":
		assert(root.get_texture().get_image().save_png("/tmp/poker_item_detail.png") == OK)
	board.joker_detail_use.pressed.emit()
	assert(board._get_queued_consumable_ids() == ["nine_elixir"], "九转金丹应加入下一次出牌")
	board.queue_free()
	await process_frame

	# 每场战斗结束后必须先进入战斗结算，保留刚击败的妖怪与本回合战果。
	rounds.current_round = 1
	rounds.current_blind = 1
	rounds.round_score = 2860
	rounds.current_phase = rounds.Phase.PLAYING
	rounds.play_log.append({"round":1, "blind":1, "claimed":860, "hand_name":"同花"})
	rounds.play_log.append({"round":1, "blind":1, "claimed":2000, "hand_name":"四条"})
	var coins_before_clear: int = rounds.game_coins
	rounds._on_blind_cleared()
	assert(rounds.current_phase == rounds.Phase.ROUND_END, "每场战斗命中结算后应先进入独立战斗结算阶段")
	assert(rounds.current_round == 1 and rounds.current_blind == 1, "结算页显示期间不能提前切换到下一只妖怪")
	assert(rounds.game_coins == coins_before_clear + rounds.coin_rewards[1][1], "通关奖励应在结算页显示前准确发放一次")
	var coins_after_clear: int = rounds.game_coins
	rounds._on_blind_cleared()
	assert(rounds.game_coins == coins_after_clear, "重复结算回调不得重复发放灵石")

	var settlement = load("res://scenes/BattleSettlement.tscn").instantiate()
	root.add_child(settlement)
	await process_frame
	settlement.show_settlement()
	await process_frame
	assert(settlement.get_meta("battle_settlement", false), "战斗结算页应具有可识别的独立界面标记")
	assert(settlement.monster_name.text == "小旋风" and settlement.background.texture.resource_path.ends_with("yellow-wind-ridge.png"), "结算页应展示刚击败的妖怪与对应主题背景")
	assert(settlement.damage_value.text == "2,860" and settlement.play_value.text == "2 次" and settlement.highest_value.text == "2,000", "结算页应汇总本回合总伤害、出牌次数和最高一击")
	assert(settlement.best_hand_label.text.find("四条") != -1 and settlement.reward_label.text.find("+130") != -1, "结算页应展示最强牌型和灵石奖励")
	assert(settlement.continue_button.text.find("前往仙铺") != -1 and not settlement.continue_button.get_meta("final_boss_skips_shop", false), "普通关卡通过按钮仍应前往仙铺")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.8).timeout
		assert(root.get_texture().get_image().save_png("/tmp/poker_battle_settlement.png") == OK)
	settlement.continue_button.pressed.emit()
	assert(rounds.current_phase == rounds.Phase.SHOP and rounds.current_round == 1 and rounds.current_blind == 2, "普通/精英结算通过后应准备下一场并进入仙铺")
	settlement.queue_free()
	await process_frame

	rounds.last_cleared_round = 0
	rounds.last_cleared_blind = 2
	rounds.last_cleared_reward = 130
	items.on_round_end()
	var shop = load("res://scenes/Shop.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	shop._update_header()
	shop._current_shop_node = 2
	items.purchased_rare_item_ids.append("quint_crit")
	shop._on_shop_items_loaded(MOCK_ITEMS)
	assert(shop._current_shop_items.all(func(item): return item.get("id", "") != "mirror_reveal" and item.get("id", "") != "quint_crit"), "商店刷新应过滤已过期克制道具与本局已购稀有道具")
	shop._rebuild_owned_panel()
	await create_timer(0.75).timeout
	assert(shop.shop_grid.columns == 3 and shop.shop_grid.get_child_count() > 0, "仙铺商品应陈列在三列双层木质货架上")
	assert(shop.shop_grid.get_child(0).get_meta("shelf_item", false) and shop.shop_grid.get_child(0).custom_minimum_size.y <= 140.0, "货架商品应使用紧凑图标陈列，不再展示大段卡片说明")
	assert(shop.shop_grid.get_theme_constant("h_separation") == 0, "货架商品三列应贴合木格，不保留卡片间隙")
	assert(shop.shop_grid.get_child(0).get_theme_stylebox("normal") is StyleBoxEmpty, "货架商品常态应无卡片底和边框")
	assert(shop.guide_text.get_theme_font_size("font_size") >= 15, "土地公讲解字体应足够醒目")
	assert(shop.find_children("*", "ScrollContainer", true, false).is_empty(), "仙铺整个页面不应出现任何滚动条")
	assert(shop.owned_dock.size.y >= 150.0, "行囊区应保留足够纵向空间展示两排物品")
	assert(shop.guide_area.size.y > shop.owned_dock.size.y * 1.15, "土地公讲解区应明显大于行囊区，完整容纳说明与操作按钮")
	assert(shop.owned_panel.columns == 3 and shop.owned_panel.get_child(0).custom_minimum_size.x >= 64.0, "行囊应使用三列两排的紧凑图标布局")
	shop.owned_panel.get_child(0).pressed.emit()
	assert(shop.guide_sell_button.visible and not shop.guide_sell_button.disabled and shop.guide_sell_button.text.find("出售") != -1, "点击行囊物品后应提供明确的出售入口")
	assert(shop.land_god_portrait.custom_minimum_size.x <= 150.0, "土地公立绘应适度收窄，为讲解气泡留出空间")
	assert(shop.land_god_portrait.texture.resource_path.ends_with("tudigong-shopkeeper.png"), "商店右下角应展示Q版土地公")
	assert(shop.land_god_portrait.global_position.x > shop.guide_bubble.global_position.x, "土地公应位于讲解气泡右侧")
	var explained_index := 0
	for i in range(shop._current_shop_items.size()):
		if shop._current_shop_items[i].get("id", "") == "nine_elixir":
			explained_index = i
			break
	var explained_item: Dictionary = shop._current_shop_items[explained_index]
	shop.shop_grid.get_child(explained_index).pressed.emit()
	assert(shop.guide_name.text.find(explained_item.get("display_name", "")) != -1, "点击商品后土地公标题应显示商品名称")
	assert(shop.guide_text.text.find(explained_item.get("description", "")) != -1 and shop._guide_action_mode == "buy", "土地公应讲解商品效果并提供集中购买操作")
	assert(not shop.guide_action_button.disabled and shop.guide_action_button.text.find("收下它") != -1, "可购买商品应在土地公气泡中提供购买按钮")
	items.jokers = [
		items.create_item_effect(MOCK_ITEMS[0]),
		items.create_item_effect({"id":"artifact_zjl","display_name":"紫金铃","price":30,"item_type":0,"effect_class":"ZiJinLing"}),
		items.create_item_effect({"id":"artifact_rsg","display_name":"人参果","price":50,"item_type":0,"effect_class":"RenShenGuo"}),
	]
	items.consumables = [items.create_item_effect(MOCK_ITEMS[2]), items.create_item_effect(MOCK_ITEMS[3]), items.create_item_effect(MOCK_ITEMS[6])]
	shop._rebuild_owned_panel()
	await process_frame
	assert(shop.owned_panel.get_child_count() == 6, "行囊必须同时完整显示三个法宝和三个道具")
	assert(shop.owned_panel.get_child(3).position.y > shop.owned_panel.get_child(0).position.y, "六件物品应分成三列两排显示，不应挤在单排或依赖横向滚动")
	await process_frame
	if DisplayServer.get_name() != "headless":
		var shop_image = root.get_texture().get_image()
		assert(shop_image.save_png("/tmp/poker_shop.png") == OK)
	shop._show_purchase_burst(MOCK_ITEMS[5])
	await create_timer(0.20).timeout
	shop.queue_free()
	await process_frame

	# 最终红孩儿通关同样先展示战斗结算；点击“通过”必须直达最终结算，绝不进入仙铺。
	rounds.current_round = 2
	rounds.current_blind = 2
	rounds.round_score = 16880
	rounds.boss_enraged = true
	rounds.boss_enrage_score_start = 0
	rounds.current_phase = rounds.Phase.PLAYING
	rounds.play_log.append({"round":2, "blind":2, "claimed":16880, "hand_name":"同花顺"})
	rounds._on_blind_cleared()
	assert(rounds.current_phase == rounds.Phase.ROUND_END and not rounds._pending_final_result, "红孩儿击败后应进入战斗结算，不得标记为最后一次仙铺")
	var final_settlement = load("res://scenes/BattleSettlement.tscn").instantiate()
	root.add_child(final_settlement)
	await process_frame
	final_settlement.show_settlement()
	await process_frame
	assert(final_settlement.monster_name.text == "红孩儿" and final_settlement.monster_portrait.texture.resource_path.ends_with("honghaier_enraged.png"), "最终结算页应突出红孩儿战果")
	assert(final_settlement.continue_button.text.find("查看最终结算") != -1 and final_settlement.continue_button.get_meta("final_boss_skips_shop", false), "红孩儿结算按钮应明确直达最终结算")
	if DisplayServer.get_name() != "headless":
		await create_timer(0.8).timeout
		assert(root.get_texture().get_image().save_png("/tmp/poker_final_battle_settlement.png") == OK)
	var phases_after_final_clear: Array = []
	var final_phase_observer = func(phase: int): phases_after_final_clear.append(phase)
	rounds.phase_changed.connect(final_phase_observer)
	final_settlement.continue_button.pressed.emit()
	assert(rounds.current_phase == rounds.Phase.FINAL_RESULT, "红孩儿战斗结算通过后应直接进入最终结算")
	assert(not phases_after_final_clear.has(rounds.Phase.SHOP), "红孩儿通关后不允许再跳转到仙铺")
	rounds.phase_changed.disconnect(final_phase_observer)
	final_settlement.queue_free()
	await process_frame

	if DisplayServer.get_name() != "headless":
		rounds.total_score = 42880
		var result_screen = load("res://scenes/ResultScreen.tscn").instantiate()
		root.add_child(result_screen)
		await process_frame
		result_screen.show_result()
		await create_timer(0.85).timeout
		assert(root.get_texture().get_image().save_png("/tmp/poker_result.png") == OK)
	print("UI_SMOKE_OK")
	quit(0)

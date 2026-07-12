extends SceneTree

const MOCK_ITEMS = [
	{"id":"artifact_jgb","display_name":"金箍棒","description":"固定增加倍率，稳定增伤","price":35,"rarity":0,"item_type":0,"effect_class":"JinGuBang"},
	{"id":"artifact_hyjj","display_name":"火眼金睛","description":"每战随机花色，匹配牌增加伤害","price":40,"rarity":0,"item_type":0,"effect_class":"HuoYanJinJing"},
	{"id":"nine_elixir","display_name":"九转金丹","description":"当次出牌伤害+25","price":8,"rarity":0,"item_type":1,"effect_class":"NineElixir"},
	{"id":"double_potion","display_name":"狂战药水","description":"当前战斗所有出牌倍率+3","price":15,"rarity":0,"item_type":1,"effect_class":"FrenzyPotion"},
	{"id":"mirror_reveal","display_name":"照妖镜","description":"白骨精战破除幻术，持续整场战斗","price":20,"rarity":1,"item_type":1,"effect_class":"MirrorReveal"},
	{"id":"quint_crit","display_name":"五连暴击","description":"当前战斗暴击率提升至50%","price":30,"rarity":1,"item_type":1,"effect_class":"QuintCrit"},
	{"id":"cloud_step","display_name":"筋斗云","description":"当前战斗手牌上限8→9张","price":25,"rarity":1,"item_type":1,"effect_class":"CloudStep"},
	{"id":"seventy_two","display_name":"七十二变","description":"随机复制1个法宝Lv1效果，永久生效","price":35,"rarity":1,"item_type":1,"effect_class":"SeventyTwo"},
]

func _initialize():
	call_deferred("_run")

func _run():
	var items = root.get_node("ItemManager")
	var rounds = root.get_node("RoundManager")
	var deck = root.get_node("DeckManager")
	var boss = root.get_node("BossSkillManager")
	for item in MOCK_ITEMS: items.register_item_resource(item)
	rounds.start_new_game()
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
	rounds.game_coins = 168
	rounds.total_score = 1260
	items.reset()
	deck.reset()
	boss.apply_skill(0, 2)
	boss.execute_skill_on_hand(deck.hand)
	items.jokers = [items.create_item_effect(MOCK_ITEMS[0]), items.create_item_effect(MOCK_ITEMS[1])]
	items.consumables = [items.create_item_effect(MOCK_ITEMS[2]), items.create_item_effect(MOCK_ITEMS[3]), items.create_item_effect(MOCK_ITEMS[4])]

	var board = load("res://scenes/GameBoard.tscn").instantiate()
	root.add_child(board)
	await process_frame
	board._refresh_all()
	await process_frame
	if DisplayServer.get_name() != "headless":
		var board_image = root.get_texture().get_image()
		assert(board_image.save_png("/tmp/poker_gameboard.png") == OK)
	var combat_frenzy = items.get_consumable_by_id("double_potion")
	board._on_consumable_used("double_potion", combat_frenzy, null)
	assert(items.active_round_consumables.has(combat_frenzy), "狂战药水应进入整场持续状态")
	var combat_mirror = items.get_consumable_by_id("mirror_reveal")
	board._on_consumable_used("mirror_reveal", combat_mirror, null)
	assert(boss.skill_suppressed, "照妖镜应整场压制白骨幻术")
	var combat_elixir = items.get_consumable_by_id("nine_elixir")
	board._on_consumable_used("nine_elixir", combat_elixir, null)
	assert(board._get_queued_consumable_ids() == ["nine_elixir"], "九转金丹应加入下一次出牌")
	board.queue_free()
	await process_frame

	rounds.last_cleared_round = 0
	rounds.last_cleared_blind = 2
	rounds.last_cleared_reward = 130
	var shop = load("res://scenes/Shop.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	shop._update_header()
	shop._on_shop_items_loaded(MOCK_ITEMS)
	shop._rebuild_owned_panel()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		var shop_image = root.get_texture().get_image()
		assert(shop_image.save_png("/tmp/poker_shop.png") == OK)
	print("UI_SMOKE_OK")
	quit(0)

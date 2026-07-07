# RoundManager.gd - Autoload 轮次/回合状态机
extends Node

enum Phase {
	MAIN_MENU,
	ROUND_START,
	PLAYING,
	SHOP,
	ROUND_END,
	GAME_OVER,
	FINAL_RESULT
}

signal phase_changed(new_phase: int)
signal score_updated(round_score: int, total_score: int)
signal round_failed(round_idx: int, blind_idx: int)
signal play_result_received(result: Dictionary)
signal boss_skill_activated(skill_name: String, params: Dictionary)
signal boss_skill_suppressed()

# 怪物名表: [round][blind] — 小怪/精英怪/大妖（按v3.1设计文档）
const MONSTER_NAMES = [
	["游魂", "骷髅将", "白骨精"],   # R1
	["黄毛貂", "小旋风", "黄风怪"],  # R2
	["火蚁兵", "火灵童", "红孩儿"],  # R3
]

# 精英怪被动效果（blind=1时触发，按v3.1设计文档）
const ELITE_SKILLS = [
	"骷髅将：每回合随机1张手牌不可选中",   # R1
	"小旋风：每回合1张手牌背面朝上",       # R2
	"火灵童：每回合第1次出牌伤害-25%",     # R3
]

var current_round: int  = 0
var current_blind: int  = 0
var plays_left:    int  = 4
var discards_left: int  = 5   # v3.1: 每怪5次换牌
var round_score:   int  = 0
var total_score:   int  = 0
var revive_count:  int  = 0
var game_coins:    int  = 0
var play_log:      Array = []
var current_phase: int  = Phase.MAIN_MENU
var _pending_next_round: bool = false  # 大妖通关后，商店关闭时推进到下一轮

# 门槛表（可被远程配置覆盖）
# v3.1: HP从旧值调整至新曲线
var thresholds: Array = [
	[300, 600, 1500],      # R1: 游魂/骷髅将/白骨精
	[1000, 2500, 6000],    # R2: 黄毛貂/小旋风/黄风怪
	[3500, 8000, 15000]    # R3: 火蚁兵/火灵童/红孩儿
]

# v3.1: 灵石奖励表（替代旧金币奖励）
var coin_rewards: Array = [
	[50, 80, 130],         # R1灵石
	[80, 130, 200],        # R2
	[130, 200, 300]        # R3
]

var max_revives: int = 3

func get_current_threshold() -> int:
	return thresholds[current_round][current_blind]

func get_current_blind_name() -> String:
	return MONSTER_NAMES[current_round][current_blind]

func get_current_monster_name() -> String:
	return MONSTER_NAMES[current_round][current_blind]

func get_current_elite_skill() -> String:
	if current_blind == 1:
		return ELITE_SKILLS[current_round]
	return ""

func get_current_boss_skill_name() -> String:
	if current_blind == 2:
		return BossSkillManager.SKILL_NAMES.get(BossSkillManager.current_skill, "")
	return ""

func get_current_enemy_skill_text() -> String:
	if current_blind == 2:
		var name = BossSkillManager.SKILL_NAMES.get(BossSkillManager.current_skill, "")
		var desc = BossSkillManager.SKILL_DESCRIPTIONS.get(BossSkillManager.current_skill, "")
		if BossSkillManager.skill_suppressed:
			return "👹 %s（已克制）" % name
		return "👹 %s：%s" % [name, desc]
	elif current_blind == 1:
		var pname = BossSkillManager.ELITE_PASSIVE_NAMES.get(BossSkillManager.current_elite_passive, "")
		var pdesc = BossSkillManager.ELITE_PASSIVE_DESCRIPTIONS.get(BossSkillManager.current_elite_passive, "")
		return "⚔️ %s：%s" % [pname, pdesc]
	return ""

func start_new_game():
	current_round = 0
	current_blind = 0
	plays_left    = 4
	discards_left = 5
	round_score   = 0
	total_score   = 0
	revive_count  = 0
	game_coins    = 0
	play_log.clear()
	DeckManager.reset()
	ItemManager.reset()
	_set_phase(Phase.PLAYING)

func _set_phase(p: int):
	current_phase = p
	phase_changed.emit(p)

func play_hand(selected_indices: Array, active_consumable_ids: Array) -> Dictionary:
	assert(plays_left > 0, "出牌次数已耗尽")

	var played_cards = DeckManager.play_cards(selected_indices)
	var remaining    = DeckManager.hand

	var hand_result = HandEvaluator.evaluate(played_cards)

	# 收集本次已激活道具效果对象（先收集，后计算，最后消耗）
	var active_items = []
	for id in active_consumable_ids:
		var item = ItemManager.get_consumable_by_id(id)
		if item:
			active_items.append(item)

	# 纯函数计算，不修改任何法宝/道具状态
	var score_result = ScoreCalculator.calculate(
		hand_result,
		ItemManager.get_active_joker_states(),
		active_items,
		remaining
	)

	# 计算完毕后道具消失
	for id in active_consumable_ids:
		ItemManager.consume_item(id)

	var gained = score_result.score
	round_score += gained
	total_score += gained
	plays_left  -= 1

	# 火灵童被动：首打出牌后消耗
	if BossSkillManager.is_first_play_nerfed():
		BossSkillManager.consume_first_play_nerf()

	play_log.append({
		"round": current_round,
		"blind": current_blind,
		"play_idx": 4 - plays_left - 1,
		"cards": played_cards.map(func(c): return c.serialize()),
		"consumables": active_consumable_ids,
		"snapshot": score_result.snapshot,
		"claimed": gained,
		"hand_name": hand_result.hand_name,
	})

	score_updated.emit(round_score, total_score)
	play_result_received.emit(score_result)

	# 不在此处推进阶段——由 UI 动画播完后调用 advance_after_play()
	var threshold = thresholds[current_round][current_blind]
	score_result["blind_cleared"] = (round_score >= threshold)
	score_result["out_of_plays"]  = (plays_left == 0 and round_score < threshold)

	return score_result

# UI 动画结束后调用，真正推进阶段
func advance_after_play(score_result: Dictionary):
	if score_result.get("blind_cleared", false):
		_on_blind_cleared()
	elif score_result.get("out_of_plays", false):
		round_failed.emit(current_round, current_blind)

func discard_cards(selected_indices: Array) -> bool:
	if discards_left <= 0: return false
	DeckManager.discard_and_draw(selected_indices)
	discards_left -= 1
	return true

func _on_blind_cleared():
	game_coins += coin_rewards[current_round][current_blind]
	ItemManager.on_round_end()

	if current_blind == 2:
		if current_round == 2:
			# 游戏通关 — 提交结果后进结算
			GameAPI.submit_result()
			_set_phase(Phase.FINAL_RESULT)
		else:
			# 大妖通关 → 先进商店 → 商店关闭后推进到下一轮
			_pending_next_round = true
			_set_phase(Phase.SHOP)
	else:
		current_blind += 1
		_reset_blind()
		_set_phase(Phase.SHOP)

func _reset_blind():
	round_score   = 0
	plays_left    = 4
	discards_left = 5  # v3.1: 每怪5次换牌
	DeckManager.reset()
	# v3.1: 敌方技能触发（大妖+精英怪）
	BossSkillManager.apply_skill(current_round, current_blind)
	BossSkillManager.execute_skill_on_hand(DeckManager.hand)

func revive():
	if revive_count >= max_revives: return
	revive_count += 1
	_reset_blind()
	_set_phase(Phase.PLAYING)

func can_revive() -> bool:
	return revive_count < max_revives

func go_to_main_menu():
	_set_phase(Phase.MAIN_MENU)

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

const MONSTER_TEXTURE_PATHS = [
	["res://assets/monsters/youhun.png", "res://assets/monsters/kuloujiang.png", "res://assets/monsters/baigujing.png"],
	["res://assets/monsters/huangmaodiao.png", "res://assets/monsters/xiaoxuanfeng.png", "res://assets/monsters/huangfengguai.png"],
	["res://assets/monsters/huoyibing.png", "res://assets/monsters/huolingtong.png", "res://assets/monsters/honghaier.png"],
]

# 三位大妖在第一阶段剩余血量不高于 30% 时进入狂暴第二阶段。
const BOSS_ENRAGED_TEXTURE_PATHS = [
	"res://assets/monsters/baigujing_enraged.png",
	"res://assets/monsters/huangfengguai_enraged.png",
	"res://assets/monsters/honghaier_enraged.png",
]

# 每一轮使用独立的战斗主题场景：白骨岭、黄风岭、火云洞。
const BATTLE_BACKGROUND_PATHS = [
	"res://assets/backgrounds/white-bone-ridge.png",
	"res://assets/backgrounds/yellow-wind-ridge.png",
	"res://assets/backgrounds/fire-cloud-cave.png",
]

const BOSS_ENRAGE_REMAINING_RATIO := 0.30
const BOSS_ENRAGED_MAX_HEALTH_MULTIPLIER := 1.50
const BOSS_ENRAGE_ACTION_BONUS := 4

# 精英怪被动效果（blind=1时触发，按v3.1设计文档）
const ELITE_SKILLS = [
	"骷髅将：每回合随机1张手牌不可选中",   # R1
	"小旋风：每回合1张手牌背面朝上",       # R2
	"火灵童：每回合第1次出牌伤害-25%",     # R3
]

var current_round: int  = 0
var current_blind: int  = 0
var plays_left:    int  = 4
var discards_left: int  = 4
var round_score:   int  = 0
var total_score:   int  = 0
var revive_count:  int  = 0
var game_coins:    int  = 0
var play_log:      Array = []
var current_phase: int  = Phase.MAIN_MENU
var _pending_next_round: bool = false  # 大妖通关后，商店关闭时推进到下一轮
# 兼容旧存档/旧流程；新流程会从红孩儿战斗结算页直接进入最终结算。
var _pending_final_result: bool = false
var last_cleared_round: int = -1
var last_cleared_blind: int = -1
var last_cleared_reward: int = 0
var boss_enraged: bool = false
# 狂暴触发时的累计伤害；第二阶段血量只计算此后的新增伤害。
var boss_enrage_score_start: int = 0

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
	var base_health: int = thresholds[current_round][current_blind]
	if current_blind == 2 and boss_enraged:
		return int(ceil(float(base_health) * BOSS_ENRAGED_MAX_HEALTH_MULTIPLIER))
	return base_health

func get_current_monster_health() -> int:
	var max_health := get_current_threshold()
	var phase_damage := round_score - boss_enrage_score_start if boss_enraged and current_blind == 2 else round_score
	return maxi(0, max_health - phase_damage)

func get_current_blind_name() -> String:
	return MONSTER_NAMES[current_round][current_blind]

func get_current_stage_label() -> String:
	const STAGE_NAMES = ["小兵", "精英", "大妖"]
	return "第%d轮 · %s" % [current_round + 1, STAGE_NAMES[current_blind]]

func get_current_monster_name() -> String:
	return MONSTER_NAMES[current_round][current_blind]

func is_current_boss_enraged() -> bool:
	return current_blind == 2 and boss_enraged

func _should_enter_boss_enrage() -> bool:
	if current_blind != 2 or boss_enraged:
		return false
	var base_health: int = thresholds[current_round][current_blind]
	return round_score >= int(ceil(float(base_health) * (1.0 - BOSS_ENRAGE_REMAINING_RATIO)))

func _enter_boss_enrage():
	if not _should_enter_boss_enrage():
		return
	boss_enraged = true
	boss_enrage_score_start = round_score
	plays_left += BOSS_ENRAGE_ACTION_BONUS
	discards_left += BOSS_ENRAGE_ACTION_BONUS

func get_current_monster_texture_path() -> String:
	if is_current_boss_enraged():
		return BOSS_ENRAGED_TEXTURE_PATHS[current_round]
	return MONSTER_TEXTURE_PATHS[current_round][current_blind]

func get_current_battle_background_path() -> String:
	return BATTLE_BACKGROUND_PATHS[clampi(current_round, 0, BATTLE_BACKGROUND_PATHS.size() - 1)]

func get_current_boss_phase_label() -> String:
	if current_blind != 2:
		return ""
	return "狂暴形态" if is_current_boss_enraged() else "初始形态"

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
			return "大妖 · %s（已克制）" % name
		if BossSkillManager.current_skill == BossSkillManager.BossSkill.HOLY_FIRE:
			return "大妖 · %s：仅【%s】可造成伤害" % [name, " / ".join(BossSkillManager.get_allowed_hand_names())]
		return "大妖 · %s：%s" % [name, desc]
	elif current_blind == 1:
		var pname = BossSkillManager.ELITE_PASSIVE_NAMES.get(BossSkillManager.current_elite_passive, "")
		var pdesc = BossSkillManager.ELITE_PASSIVE_DESCRIPTIONS.get(BossSkillManager.current_elite_passive, "")
		return "精英 · %s：%s" % [pname, pdesc]
	return ""

func start_new_game():
	current_round = 0
	current_blind = 0
	plays_left    = 4
	discards_left = 4
	round_score   = 0
	total_score   = 0
	revive_count  = 0
	game_coins    = 0
	play_log.clear()
	_pending_next_round = false
	_pending_final_result = false
	last_cleared_round = -1
	last_cleared_blind = -1
	last_cleared_reward = 0
	boss_enraged = false
	boss_enrage_score_start = 0
	DeckManager.reset()
	ItemManager.reset()
	BossSkillManager.reset()
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
	var active_items = ItemManager.get_active_round_consumables().duplicate()
	var applied_consumable_ids = active_items.map(func(item): return item.resource_data.get("id", ""))
	applied_consumable_ids.append_array(active_consumable_ids)
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

	# 红孩儿·三昧真火：非指定牌型伤害归零，但仍消耗一次出牌。
	if not BossSkillManager.is_hand_rank_allowed(hand_result.get("rank", -1)):
		score_result["blocked_by_boss"] = true
		score_result["score"] = 0
		score_result.get("steps", []).append({
			"type": "boss_block",
			"label": "三昧真火",
			"partial": 0,
			"delta": {},
		})

	var gained = score_result.score
	round_score += gained
	total_score += gained
	plays_left  -= 1
	var entered_boss_enrage := _should_enter_boss_enrage()
	if entered_boss_enrage:
		_enter_boss_enrage()

	# 火灵童被动：首打出牌后消耗
	if BossSkillManager.is_first_play_nerfed():
		BossSkillManager.consume_first_play_nerf()

	var current_play_index := 0
	for logged_play in play_log:
		if logged_play.get("round", -1) == current_round and logged_play.get("blind", -1) == current_blind:
			current_play_index += 1
	play_log.append({
		"round": current_round,
		"blind": current_blind,
		"play_idx": current_play_index,
		"cards": played_cards.map(func(c): return c.serialize()),
		"consumables": applied_consumable_ids,
		"snapshot": score_result.snapshot.duplicate(true),
		"steps": score_result.get("steps", []).duplicate(true),
		"chips": int(score_result.get("chips", 0)),
		"mult": float(score_result.get("mult", 1.0)),
		"special_mult": float(score_result.get("special_mult", 1.0)),
		"is_crit": bool(score_result.get("is_crit", false)),
		"crit_mult": float(score_result.get("crit_mult", 2.0)),
		"blocked_by_boss": bool(score_result.get("blocked_by_boss", false)),
		"claimed": gained,
		"hand_name": hand_result.hand_name,
	})

	score_updated.emit(round_score, total_score)
	play_result_received.emit(score_result)

	# 不在此处推进阶段——由 UI 动画播完后调用 advance_after_play()
	var current_health := get_current_monster_health()
	score_result["boss_enraged"] = entered_boss_enrage
	score_result["blind_cleared"] = current_health <= 0
	score_result["out_of_plays"]  = (plays_left == 0 and current_health > 0)

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
	# 伤害动画或按钮回调重复到达时，不能重复发放通关奖励。
	if current_phase == Phase.ROUND_END:
		return

	last_cleared_round = current_round
	last_cleared_blind = current_blind
	last_cleared_reward = coin_rewards[current_round][current_blind]
	game_coins += last_cleared_reward
	ItemManager.on_round_end()
	_pending_next_round = false
	_pending_final_result = false

	# 保留刚结束战斗的轮次、妖怪和伤害数据，交给结算页完整展示。
	# 玩家点击“通过”之后才准备下一场，避免结算页读到下一只妖怪。
	_set_phase(Phase.ROUND_END)

func continue_after_battle_settlement():
	if current_phase != Phase.ROUND_END:
		return

	var cleared_round := last_cleared_round
	var cleared_blind := last_cleared_blind
	if cleared_round < 0 or cleared_blind < 0:
		return

	# 红孩儿是最终关卡：从战斗结算直接进入本局最终结算，不再开放仙铺。
	if cleared_round == 2 and cleared_blind == 2:
		_pending_final_result = false
		_pending_next_round = false
		GameAPI.submit_result()
		_set_phase(Phase.FINAL_RESULT)
		return

	# 普通/精英战先准备下一只妖怪，再进入仙铺；离开仙铺即可直接开战。
	if cleared_blind < 2:
		current_round = cleared_round
		current_blind = cleared_blind + 1
		_reset_blind()
		_set_phase(Phase.SHOP)
		return

	# 前两轮大妖之后仍进入仙铺，关闭仙铺时再切换到下一轮。
	_pending_next_round = true
	_set_phase(Phase.SHOP)

func _reset_blind():
	ItemManager.on_round_end()
	round_score   = 0
	plays_left    = 4
	discards_left = 4
	boss_enraged = false
	boss_enrage_score_start = 0
	DeckManager.reset()
	# 每回合开始：通知法宝刷新随机属性（如火眼金睛随机花色）
	for joker in ItemManager.jokers:
		if joker.has_method("randomize_suit"):
			joker.randomize_suit()
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

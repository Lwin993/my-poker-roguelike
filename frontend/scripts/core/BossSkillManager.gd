# BossSkillManager.gd - Autoload 敌方技能状态机
# v3.1: 大妖技能 + 精英怪被动效果 + 克制道具系统
extends Node

signal boss_skill_activated(skill_name: String, params: Dictionary)
signal boss_skill_suppressed()

# ── 大妖技能枚举 ──
enum BossSkill {
	NONE,
	PHANTOM_CARDS,    # 白骨幻术：2张幻影牌(不可选)
	SANDSTORM,        # 风沙走石：3张背面朝上
	HOLY_FIRE,        # 三昧真火：仅2种牌型可伤害
}

# ── 精英怪被动枚举 ──
enum ElitePassive {
	NONE,
	LOCK_CARD,       # 骷髅将：每回合随机1张手牌不可选中
	FACE_DOWN,       # 小旋风：每回合1张手牌背面朝上
	FIRST_PLAY_NERF, # 火灵童：每回合第1次出牌伤害-25%
}

const SKILL_NAMES = {
	BossSkill.NONE: "",
	BossSkill.PHANTOM_CARDS: "白骨幻术",
	BossSkill.SANDSTORM: "风沙走石",
	BossSkill.HOLY_FIRE: "三昧真火",
}

const SKILL_DESCRIPTIONS = {
	BossSkill.PHANTOM_CARDS: "2张手牌变为幻影牌(不可选)",
	BossSkill.SANDSTORM: "3张手牌背面朝上(不可见)",
	BossSkill.HOLY_FIRE: "仅2种牌型可造成伤害",
}

const ELITE_PASSIVE_NAMES = {
	ElitePassive.NONE: "",
	ElitePassive.LOCK_CARD: "骷髅将",
	ElitePassive.FACE_DOWN: "小旋风",
	ElitePassive.FIRST_PLAY_NERF: "火灵童",
}

const ELITE_PASSIVE_DESCRIPTIONS = {
	ElitePassive.LOCK_CARD: "每回合随机1张手牌不可选中",
	ElitePassive.FACE_DOWN: "每回合1张手牌背面朝上",
	ElitePassive.FIRST_PLAY_NERF: "每回合第1次出牌伤害-25%",
}

# 克制道具ID → 克制的技能（仅大妖）
const COUNTER_ITEMS = {
	"mirror_reveal": BossSkill.PHANTOM_CARDS,
	"wind_calmer": BossSkill.SANDSTORM,
	"holy_dew": BossSkill.HOLY_FIRE,
}

# ── 大妖技能状态 ──
var current_skill: BossSkill = BossSkill.NONE
var phantom_cards: Array = []        # 幻影牌对象（排序安全）
var face_down_cards: Array = []      # 背面朝上牌对象（排序安全）
var allowed_hand_ranks: Array = []    # 允许的牌型code列表
var skill_suppressed: bool = false   # 克制道具生效中

# ── 精英怪被动状态 ──
var current_elite_passive: ElitePassive = ElitePassive.NONE
var elite_locked_cards: Array = []        # 精英怪锁定的牌对象（排序安全）
var elite_face_down_cards: Array = []     # 精英怪翻面的牌对象（排序安全）
var first_play_nerfed: bool = false       # 本回合第1次出牌是否被削弱

# 检查牌是否可选（同时考虑大妖幻影牌 + 精英怪锁定牌）
func is_card_selectable(card_index: int, hand: Array) -> bool:
	var card = hand[card_index] if card_index < hand.size() else null
	# 大妖幻影牌
	if current_skill == BossSkill.PHANTOM_CARDS and not skill_suppressed:
		if card and card in phantom_cards:
			return false
	# 精英怪锁定牌（v3.1: 克制道具也压制精英被动）
	if current_elite_passive == ElitePassive.LOCK_CARD and not skill_suppressed:
		if card and card in elite_locked_cards:
			return false
	return true

# 检查牌是否可见（同时考虑大妖翻面 + 精英怪翻面）
func is_card_visible(card_index: int) -> bool:
	var hand = DeckManager.hand
	var card = hand[card_index] if card_index < hand.size() else null
	# 大妖翻面
	if current_skill == BossSkill.SANDSTORM and not skill_suppressed:
		if card and card in face_down_cards:
			return false
	# 精英怪翻面（v3.1: 克制道具也压制精英被动）
	if current_elite_passive == ElitePassive.FACE_DOWN and not skill_suppressed:
		if card and card in elite_face_down_cards:
			return false
	return true

# 检查牌型是否被允许（考虑三昧真火限制）
func is_hand_rank_allowed(hand_rank: int) -> bool:
	if current_skill != BossSkill.HOLY_FIRE or skill_suppressed:
		return true
	return hand_rank in allowed_hand_ranks

# 检查当前出牌是否被精英怪削弱（火灵童首打-25%）
# v3.1: 克制道具也压制精英被动
func is_first_play_nerfed() -> bool:
	return current_elite_passive == ElitePassive.FIRST_PLAY_NERF and first_play_nerfed and not skill_suppressed

# 标记首打已消耗（出牌后调用）
func consume_first_play_nerf():
	first_play_nerfed = false

# 应用敌方技能（每回合开始由RoundManager._reset_blind调用）
func apply_skill(round: int, blind: int):
	reset()
	if blind == 2:
		# 大妖技能
		match round:
			0: current_skill = BossSkill.PHANTOM_CARDS
			1: current_skill = BossSkill.SANDSTORM
			2: current_skill = BossSkill.HOLY_FIRE
			_: current_skill = BossSkill.NONE
		if current_skill != BossSkill.NONE:
			boss_skill_activated.emit(SKILL_NAMES.get(current_skill, ""), _get_skill_params())
	elif blind == 1:
		# 精英怪被动
		match round:
			0: current_elite_passive = ElitePassive.LOCK_CARD
			1: current_elite_passive = ElitePassive.FACE_DOWN
			2: current_elite_passive = ElitePassive.FIRST_PLAY_NERF
			_: current_elite_passive = ElitePassive.NONE
		# 火灵童首打削弱立即生效
		if current_elite_passive == ElitePassive.FIRST_PLAY_NERF:
			first_play_nerfed = true
	# blind == 0（小兵）: 无技能

# 执行技能效果（在手牌生成后调用）
func execute_skill_on_hand(hand: Array):
	# 大妖技能
	if current_skill != BossSkill.NONE and not skill_suppressed:
		match current_skill:
			BossSkill.PHANTOM_CARDS:
				_mark_phantom_cards(hand)
			BossSkill.SANDSTORM:
				_mark_face_down_cards(hand)
			BossSkill.HOLY_FIRE:
				_select_allowed_hand_ranks()

	# 精英怪被动（v3.1: 克制道具压制后不再重新标记）
	if current_elite_passive != ElitePassive.NONE and not skill_suppressed:
		match current_elite_passive:
			ElitePassive.LOCK_CARD:
				_mark_elite_locked_card(hand)
			ElitePassive.FACE_DOWN:
				_mark_elite_face_down_card(hand)
			ElitePassive.FIRST_PLAY_NERF:
				pass  # 首打削弱在apply_skill时已标记，换牌不重置

func suppress_skill():
	if skill_suppressed:
		return
	skill_suppressed = true
	boss_skill_suppressed.emit()

# 检查消耗品是否克制当前大妖技能
func does_consumable_counter_skill(consumable_id: String) -> bool:
	if current_skill == BossSkill.NONE:
		return false
	var countered_skill = COUNTER_ITEMS.get(consumable_id, BossSkill.NONE)
	return countered_skill == current_skill

# 重置（新回合开始）
func reset():
	current_skill = BossSkill.NONE
	phantom_cards.clear()
	face_down_cards.clear()
	allowed_hand_ranks.clear()
	skill_suppressed = false
	current_elite_passive = ElitePassive.NONE
	elite_locked_cards.clear()
	elite_face_down_cards.clear()
	first_play_nerfed = false

# ---- 内部方法 ----

func _mark_phantom_cards(hand: Array):
	# 随机标记2张牌为幻影牌（存储卡牌对象，排序安全）
	var indices = range(hand.size())
	indices.shuffle()
	phantom_cards = [hand[indices[0]], hand[indices[1]]]

func _mark_face_down_cards(hand: Array):
	# 随机标记3张牌背面朝上（存储卡牌对象，排序安全）
	var indices = range(hand.size())
	indices.shuffle()
	face_down_cards = [hand[indices[0]], hand[indices[1]], hand[indices[2]]]

func _select_allowed_hand_ranks():
	# 从9种牌型中随机选2种
	var all_ranks = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	all_ranks.shuffle()
	allowed_hand_ranks = all_ranks.slice(0, 2)

func _mark_elite_locked_card(hand: Array):
	# 骷髅将：随机1张手牌不可选中（存储卡牌对象，排序安全）
	var indices = range(hand.size())
	indices.shuffle()
	elite_locked_cards = [hand[indices[0]]]

func _mark_elite_face_down_card(hand: Array):
	# 小旋风：随机1张手牌背面朝上（存储卡牌对象，排序安全）
	var indices = range(hand.size())
	indices.shuffle()
	elite_face_down_cards = [hand[indices[0]]]

func _get_skill_params() -> Dictionary:
	match current_skill:
		BossSkill.PHANTOM_CARDS:
			return {"phantom_count": 2, "phantom_cards": phantom_cards}
		BossSkill.SANDSTORM:
			return {"face_down_count": 3, "face_down_cards": face_down_cards}
		BossSkill.HOLY_FIRE:
			return {"allowed_ranks": allowed_hand_ranks}
		_:
			return {}

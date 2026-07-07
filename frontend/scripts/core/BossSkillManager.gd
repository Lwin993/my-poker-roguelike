# BossSkillManager.gd - Autoload 大妖技能状态机
# v3.1: 三大妖技能 + 克制道具系统
extends Node

signal boss_skill_activated(skill_name: String, params: Dictionary)
signal boss_skill_suppressed()

enum BossSkill {
	NONE,
	PHANTOM_CARDS,    # 白骨幻术：2张幻影牌(不可选)
	SANDSTORM,        # 风沙走石：3张背面朝上
	HOLY_FIRE,        # 三昧真火：仅2种牌型可伤害
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

# 克制道具ID → 克制的技能
const COUNTER_ITEMS = {
	"mirror_reveal": BossSkill.PHANTOM_CARDS,
	"wind_calmer": BossSkill.SANDSTORM,
	"holy_dew": BossSkill.HOLY_FIRE,
}

var current_skill: BossSkill = BossSkill.NONE
var phantom_indices: Array = []       # 幻影牌索引
var face_down_indices: Array = []     # 背面朝上索引
var allowed_hand_ranks: Array = []    # 允许的牌型code列表
var skill_suppressed: bool = false   # 克制道具生效中

# 检查牌是否可选（考虑幻影牌和翻面牌）
func is_card_selectable(card_index: int, hand: Array) -> bool:
	if current_skill == BossSkill.NONE or skill_suppressed:
		return true
	if card_index in phantom_indices:
		return false  # 幻影牌不可选
	return true

# 检查牌是否可见（考虑翻面牌）
func is_card_visible(card_index: int) -> bool:
	if current_skill == BossSkill.NONE or skill_suppressed:
		return true
	if card_index in face_down_indices:
		return false  # 背面朝上不可见
	return true

# 检查牌型是否被允许（考虑三昧真火限制）
func is_hand_rank_allowed(hand_rank: int) -> bool:
	if current_skill != BossSkill.HOLY_FIRE or skill_suppressed:
		return true
	return hand_rank in allowed_hand_ranks

# 应用大妖技能（每回合开始调用）
func apply_skill(round: int, blind: int):
	reset()
	if blind != 2:
		return  # 仅大妖(blind=2)回合触发

	match round:
		0: current_skill = BossSkill.PHANTOM_CARDS
		1: current_skill = BossSkill.SANDSTORM
		2: current_skill = BossSkill.HOLY_FIRE
		_: current_skill = BossSkill.NONE

	boss_skill_activated.emit(SKILL_NAMES.get(current_skill, ""), _get_skill_params())

# 执行技能效果（在手牌生成后调用）
func execute_skill_on_hand(hand: Array):
	if current_skill == BossSkill.NONE or skill_suppressed:
		return

	match current_skill:
		BossSkill.PHANTOM_CARDS:
			_mark_phantom_cards(hand)
		BossSkill.SANDSTORM:
			_mark_face_down_cards(hand)
		BossSkill.HOLY_FIRE:
			_select_allowed_hand_ranks()

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
	phantom_indices.clear()
	face_down_indices.clear()
	allowed_hand_ranks.clear()
	skill_suppressed = false

# ---- 内部方法 ----

func _mark_phantom_cards(hand: Array):
	# 随机标记2张牌为幻影牌
	var indices = range(hand.size())
	indices.shuffle()
	phantom_indices = indices.slice(0, 2)

func _mark_face_down_cards(hand: Array):
	# 随机标记3张牌背面朝上
	var indices = range(hand.size())
	indices.shuffle()
	face_down_indices = indices.slice(0, 3)

func _select_allowed_hand_ranks():
	# 从9种牌型中随机选2种
	var all_ranks = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	all_ranks.shuffle()
	allowed_hand_ranks = all_ranks.slice(0, 2)

func _get_skill_params() -> Dictionary:
	match current_skill:
		BossSkill.PHANTOM_CARDS:
			return {"phantom_count": 2, "phantom_indices": phantom_indices}
		BossSkill.SANDSTORM:
			return {"face_down_count": 3, "face_down_indices": face_down_indices}
		BossSkill.HOLY_FIRE:
			return {"allowed_ranks": allowed_hand_ranks}
		_:
			return {}

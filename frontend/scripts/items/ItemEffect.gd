# ItemEffect.gd - 道具效果基类
# v3.1: 支持 chips×mult 双维度系统
extends RefCounted

var resource_data: Dictionary = {}
var level: int = 1

# ---- 双维度效果接口 ----

# 被动效果：返回字典，支持以下键：
#   chip_add: float    — 增加chips（伤害加成），如火眼金睛按花色加chips
#   mult_add: float    — 增加mult（倍率加成），如金箍棒固定+倍率
#   crit_rate_add: float — 增加暴击率
#   crit_mult_add: float — 增加暴击倍率
#   special_mult: float — 特殊乘数（如人参果的概率×倍率）
#   mult_factor: float  — 倍率乘数（如斩妖剑×3，分身术×2）
func get_passive_modifiers(_hand_result: Dictionary) -> Dictionary:
	return {}

# 主动/消耗品效果：返回字典，支持以下键：
#   chip_add: float    — 增加chips
#   mult_add: float    — 增加mult
#   mult_factor: float — 倍率乘数
#   crit_rate_add: float
#   crit_mult_add: float
#   extra_plays: int   — 额外出牌次数
#   extra_discards: int — 额外换牌次数
#   hand_size_add: int  — 手牌上限增加
#   boss_suppress: bool — 是否压制大妖技能（克制道具）
func get_score_modifiers() -> Dictionary:
	return {}

# 是否回合持续（非消耗型）
func is_round_wide() -> bool:
	return false

# 是否消耗型（使用后消失）
func is_consumed() -> bool:
	return false

# 使用时机：
#   next_play — 选择后在下一次出牌结算
#   instant   — 点击后立即生效并消耗
#   round     — 点击后在当前怪物战持续生效
#   shop      — 仅能在仙铺使用
func get_use_timing() -> String:
	return "next_play"

func get_use_timing_label() -> String:
	match get_use_timing():
		"instant": return "立即生效"
		"round":   return "当前战斗持续"
		"shop":    return "仙铺使用"
	return "下次出牌"

func can_use_now() -> bool:
	return true

func get_unavailable_reason() -> String:
	return ""

# 升级费用
func get_upgrade_cost() -> int:
	return -1

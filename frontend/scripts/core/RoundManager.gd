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

const BLIND_NAMES = ["小盲", "大盲", "Boss"]

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

# 门槛表（可被远程配置覆盖）
var thresholds: Array = [
	[300, 800, 1500],
	[1500, 3000, 5000],
	[3500, 6000, 10000]
]

# 游戏积分奖励表
var coin_rewards: Array = [
	[30, 50, 80],
	[50, 80, 120],
	[80, 120, 180]
]

var max_revives: int = 3

func get_current_threshold() -> int:
	return thresholds[current_round][current_blind]

func get_current_blind_name() -> String:
	return BLIND_NAMES[current_blind]

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
	var active_items = []
	for id in active_consumable_ids:
		var item = ItemManager.get_consumable_by_id(id)
		if item:
			active_items.append(item)

	var score_result = ScoreCalculator.calculate(
		hand_result,
		ItemManager.get_active_joker_states(),
		active_items,
		remaining
	)

	var gained = score_result.score
	round_score += gained
	total_score += gained
	plays_left  -= 1

	for id in active_consumable_ids:
		ItemManager.consume_item(id)

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

	var threshold = thresholds[current_round][current_blind]
	if round_score >= threshold:
		await get_tree().create_timer(1.2).timeout
		_on_blind_cleared()
	elif plays_left == 0:
		round_failed.emit(current_round, current_blind)

	return score_result

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
			# 游戏通关
			GameAPI.submit_result()
			_set_phase(Phase.FINAL_RESULT)
		else:
			current_round += 1
			current_blind  = 0
			_reset_blind()
			_set_phase(Phase.ROUND_START)
	else:
		current_blind += 1
		_reset_blind()
		_set_phase(Phase.SHOP)

func _reset_blind():
	round_score   = 0
	plays_left    = 4
	discards_left = 4
	DeckManager.reset()

func revive():
	if revive_count >= max_revives: return
	revive_count += 1
	_reset_blind()
	_set_phase(Phase.PLAYING)

func can_revive() -> bool:
	return revive_count < max_revives

func go_to_main_menu():
	_set_phase(Phase.MAIN_MENU)

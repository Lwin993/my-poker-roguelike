# GameState.gd - Autoload 全局状态存档/读档
extends Node

const SAVE_PATH = "user://game_state.json"

func save_state():
	var state = {
		"session_id": GameAPI.session_id,
		"gold_coins": GameAPI.gold_coins,
		"current_round": RoundManager.current_round,
		"current_blind": RoundManager.current_blind,
		"round_score": RoundManager.round_score,
		"total_score": RoundManager.total_score,
		"game_coins": RoundManager.game_coins,
		"plays_left": RoundManager.plays_left,
		"discards_left": RoundManager.discards_left,
		"revive_count": RoundManager.revive_count,
		"deck": DeckManager.deck.map(func(c): return c.serialize()),
		"hand": DeckManager.hand.map(func(c): return c.serialize()),
		"discard_pile": DeckManager.discard_pile.map(func(c): return c.serialize()),
		"jokers": ItemManager.jokers.map(func(j): return {"id": j.resource_data.get("id", ""), "level": j.level}),
		"consumables": ItemManager.consumables.map(func(c): return c.resource_data.get("id", "")),
		"play_log": RoundManager.play_log,
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state))
		file.close()

func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return false
	var text = file.get_as_text()
	file.close()
	var state = JSON.parse_string(text)
	if state == null: return false
	_restore_from_dict(state)
	return true

func clear_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

func _restore_from_dict(state: Dictionary):
	GameAPI.session_id = state.get("session_id", 0)
	GameAPI.gold_coins = state.get("gold_coins", 100)
	RoundManager.current_round  = state.get("current_round", 0)
	RoundManager.current_blind  = state.get("current_blind", 0)
	RoundManager.round_score    = state.get("round_score", 0)
	RoundManager.total_score    = state.get("total_score", 0)
	RoundManager.game_coins     = state.get("game_coins", 0)
	RoundManager.plays_left     = state.get("plays_left", 4)
	RoundManager.discards_left  = state.get("discards_left", 5)  # v3.1: 每怪5次
	RoundManager.revive_count   = state.get("revive_count", 0)
	RoundManager.play_log       = state.get("play_log", [])

	# 恢复牌堆
	DeckManager.deck = _deserialize_cards(state.get("deck", []))
	DeckManager.hand = _deserialize_cards(state.get("hand", []))
	DeckManager.discard_pile = _deserialize_cards(state.get("discard_pile", []))

func _deserialize_cards(arr: Array) -> Array:
	var result = []
	for d in arr:
		result.append(DeckManager.Card.new(d.get("r", 1), d.get("s", 0)))
	return result

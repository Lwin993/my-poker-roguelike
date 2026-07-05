# RefreshTicket.gd — 刷新券：下次商店刷新免费
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_consumed() -> bool:
	return true

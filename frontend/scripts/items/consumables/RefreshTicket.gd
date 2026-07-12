# RefreshTicket.gd — 刷新券：下次商店刷新免费
extends "res://scripts/items/ItemEffect.gd"
func get_score_modifiers() -> Dictionary:
	return {}
func is_consumed() -> bool:
	return true
func get_use_timing() -> String:
	return "shop"
func can_use_now() -> bool:
	return false
func get_unavailable_reason() -> String:
	return "刷新券会在仙铺刷新时自动使用"

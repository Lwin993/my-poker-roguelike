# JSBridge.gd - Autoload JavaScriptBridge 封装（本地 Mock）
extends Node

signal revive_ad_completed
signal revive_friend_helped
signal token_received(token: String)

func request_revive_ad():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.GameBridge && window.GameBridge.showRewardedAd('revive')")
	else:
		# 本地 Mock：直接触发完成
		await get_tree().create_timer(0.5).timeout
		revive_ad_completed.emit()

func request_share_invite():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.GameBridge && window.GameBridge.shareInvite()")
	else:
		await get_tree().create_timer(0.3).timeout
		revive_friend_helped.emit()

func get_auth_token() -> String:
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("(window.GameBridge && window.GameBridge.getToken()) || ''")
	return "dev_token_local"

func dispatch(event: String, data_json: String):
	var data = JSON.parse_string(data_json) if data_json else {}
	match event:
		"ad_complete":   revive_ad_completed.emit()
		"ad_fail":       pass
		"friend_helped": revive_friend_helped.emit()
		"token_ready":   token_received.emit(data.get("token", ""))

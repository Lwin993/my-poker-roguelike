# GameAPI.gd - Autoload HTTP 请求封装（后端联调模式）
extends Node

var session_id: int = 0
var gold_coins: int = 0  # 外部金币（持久化，跨对局持有）
var _base_url: String = "http://localhost:8080"
var _auth_token: String = ""

# ── Signals ──
signal game_started(data: Dictionary)
signal result_submitted(data: Dictionary)
signal shop_items_loaded(items: Array)
signal buy_completed(data: Dictionary)
signal revive_prepared(data: Dictionary)
signal revive_completed(data: Dictionary)
signal wallet_balance_loaded(balance: int)
signal api_error(path: String, code: int, msg: String)

# ── HTTP Request Helpers ──
func _get_headers() -> PackedStringArray:
	var token = _auth_token
	if token == "":
		token = JSBridge.get_auth_token()
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % token,
	])
	return headers

func _http_post(path: String, body: Dictionary, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, code, _headers, body_bytes):
		if code < 200 or code >= 300:
			var err_text = body_bytes.get_string_from_utf8() if body_bytes else ""
			push_warning("HTTP %d from %s: %s" % [code, path, err_text])
			api_error.emit(path, code, err_text)
			callback.call({"code": -1, "msg": "HTTP_ERROR_%d" % code, "data": {}})
			http.queue_free()
			return
		var json_text = body_bytes.get_string_from_utf8()
		var parsed = JSON.parse_string(json_text)
		if parsed == null:
			parsed = {}
		callback.call(parsed)
		http.queue_free()
	)
	var json_body = JSON.stringify(body)
	var url = _base_url + path
	var err = http.request(url, _get_headers(), HTTPClient.METHOD_POST, json_body)
	if err != OK:
		push_error("HTTP POST request failed: %s (err=%d)" % [url, err])
		api_error.emit(path, err, "REQUEST_FAILED")
		callback.call({"code": -1, "msg": "REQUEST_FAILED", "data": {}})
		http.queue_free()

func _http_get(path: String, callback: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result, code, _headers, body_bytes):
		if code < 200 or code >= 300:
			var err_text = body_bytes.get_string_from_utf8() if body_bytes else ""
			push_warning("HTTP %d from %s: %s" % [code, path, err_text])
			api_error.emit(path, code, err_text)
			callback.call({"code": -1, "msg": "HTTP_ERROR_%d" % code, "data": {}})
			http.queue_free()
			return
		var json_text = body_bytes.get_string_from_utf8()
		var parsed = JSON.parse_string(json_text)
		if parsed == null:
			parsed = {}
		callback.call(parsed)
		http.queue_free()
	)
	var url = _base_url + path
	var err = http.request(url, _get_headers(), HTTPClient.METHOD_GET)
	if err != OK:
		push_error("HTTP GET request failed: %s (err=%d)" % [url, err])
		api_error.emit(path, err, "REQUEST_FAILED")
		callback.call({"code": -1, "msg": "REQUEST_FAILED", "data": {}})
		http.queue_free()

# ════════════════════════════════════════════════════════════════
# API: start_game → POST /api/game/start
# ════════════════════════════════════════════════════════════════
func start_game():
	_http_post("/api/game/start", {}, func(response: Dictionary):
		var data = response.get("data", {})
		session_id = int(data.get("session_id", 0))
		gold_coins = int(data.get("gold_coins", 0))
		# Load configs into ConfigLoader
		ConfigLoader.load_from_server(data)
		game_started.emit(data)
	)

# ════════════════════════════════════════════════════════════════
# API: submit_result → POST /api/game/submit_result
# ════════════════════════════════════════════════════════════════
func submit_result():
	_http_post("/api/game/submit_result", {"session_id": session_id}, func(response: Dictionary):
		var data = response.get("data", {})
		gold_coins = int(data.get("gold_coins", 0))
		result_submitted.emit(data)
	)

# ════════════════════════════════════════════════════════════════
# API: get_shop_items → GET /api/shop/list
# ════════════════════════════════════════════════════════════════
func get_shop_items(shop_node: int, refresh_count: int = 0) -> void:
	var url = "/api/shop/list?session_id=%d&shop_node=%d&refresh_count=%d" % [session_id, shop_node, refresh_count]
	_http_get(url, func(response: Dictionary):
		var data = response.get("data", {})
		var items = data.get("items", []) if data is Dictionary else []
		shop_items_loaded.emit(items)
	)

# ════════════════════════════════════════════════════════════════
# API: buy_item → POST /api/shop/buy
# ════════════════════════════════════════════════════════════════
func buy_item(item_id: String, shop_node: int) -> void:
	var body = {
		"session_id": session_id,
		"item_id": item_id,
		"shop_node": shop_node,
	}
	_http_post("/api/shop/buy", body, func(response: Dictionary):
		var data = response.get("data", {})
		buy_completed.emit(data)
	)

# ════════════════════════════════════════════════════════════════
# API: revive_prepare → POST /api/game/revive_prepare
# ════════════════════════════════════════════════════════════════
func revive_prepare() -> void:
	_http_post("/api/game/revive_prepare", {"session_id": session_id}, func(response: Dictionary):
		var data = response.get("data", {})
		revive_prepared.emit(data)
	)

# ════════════════════════════════════════════════════════════════
# API: revive → POST /api/game/revive
# ════════════════════════════════════════════════════════════════
func revive(ad_token: String) -> void:
	var body = {
		"session_id": session_id,
		"ad_token": ad_token,
	}
	_http_post("/api/game/revive", body, func(response: Dictionary):
		var data = response.get("data", {})
		revive_completed.emit(data)
	)

# ════════════════════════════════════════════════════════════════
# API: get_wallet_balance → GET /api/wallet/balance
# ════════════════════════════════════════════════════════════════
func get_wallet_balance() -> void:
	_http_get("/api/wallet/balance", func(response: Dictionary):
		var data = response.get("data", {})
		gold_coins = int(data.get("gold_coins", 0))
		wallet_balance_loaded.emit(gold_coins)
	)

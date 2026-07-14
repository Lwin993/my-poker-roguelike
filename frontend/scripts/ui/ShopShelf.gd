extends Control

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw():
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("2a1209"), true)
	# 暗色柜体与暖金内衬，让商品图标像真正摆在仙铺木格中。
	var inner := Rect2(9.0, 28.0, maxf(0.0, size.x - 18.0), maxf(0.0, size.y - 38.0))
	draw_rect(inner, Color("160b08"), true)
	for i in range(1, 3):
		var x := inner.position.x + inner.size.x * float(i) / 3.0
		draw_rect(Rect2(x - 3.0, inner.position.y, 6.0, inner.size.y), Color("6b3718"), true)
		draw_line(Vector2(x - 1.0, inner.position.y), Vector2(x - 1.0, inner.end.y), Color(0.86, 0.56, 0.25, 0.45), 1.0)
	var shelf_y := inner.position.y + inner.size.y * 0.5
	draw_rect(Rect2(inner.position.x - 5.0, shelf_y - 5.0, inner.size.x + 10.0, 13.0), Color("8a4a21"), true)
	draw_line(Vector2(inner.position.x - 4.0, shelf_y - 4.0), Vector2(inner.end.x + 4.0, shelf_y - 4.0), Color("d28a3e"), 2.0)
	# 两侧立柱和底部厚木梁。
	draw_rect(Rect2(2.0, 18.0, 12.0, size.y - 20.0), Color("7b3e1b"), true)
	draw_rect(Rect2(size.x - 14.0, 18.0, 12.0, size.y - 20.0), Color("7b3e1b"), true)
	draw_rect(Rect2(0.0, size.y - 13.0, size.x, 13.0), Color("9b5727"), true)
	draw_line(Vector2(2.0, size.y - 12.0), Vector2(size.x - 2.0, size.y - 12.0), Color("e1a04b"), 2.0)
	# 克制地画几条不规则木纹，避免货架像纯色面板。
	for i in range(7):
		var y := 35.0 + float(i) * 34.0
		if y < size.y - 15.0:
			draw_line(Vector2(18.0, y), Vector2(size.x - 18.0, y + sin(float(i)) * 3.0), Color(0.58, 0.29, 0.12, 0.22), 1.0)

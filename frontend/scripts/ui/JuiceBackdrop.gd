# JuiceBackdrop.gd — 扑克牌桌动态背景：暗色桌布、印刷光纹、漂浮筹码与爆发粒子
extends Control

@export_enum("menu", "battle", "shop", "result") var variant: String = "battle"

var _time := 0.0
var _particles: Array = []
var _flash_color := Color.TRANSPARENT

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	for i in range(28):
		_particles.append(_make_particle(Vector2(randf() * maxf(size.x, 480.0), randf() * maxf(size.y, 854.0))))

func _process(delta: float):
	_time += delta
	for p in _particles:
		p.pos += p.velocity * delta
		p.life -= delta
		if p.pos.y < -20.0 or p.pos.x < -30.0 or p.pos.x > size.x + 30.0 or p.life <= 0.0:
			_reset_particle(p)
	_flash_color.a = move_toward(_flash_color.a, 0.0, delta * 2.8)
	queue_redraw()

func burst(global_position: Vector2, color: Color = Color(1.0, 0.72, 0.1), count: int = 24):
	var local_position = global_position - self.global_position
	for i in range(count):
		var angle = randf() * TAU
		var speed = randf_range(90.0, 280.0)
		_particles.append({
			"pos": local_position,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"radius": randf_range(2.0, 6.0),
			"color": color.lightened(randf_range(0.0, 0.35)),
			"life": randf_range(0.45, 1.0),
			"max_life": 1.0,
		})

func flash(color: Color, strength: float = 0.28):
	_flash_color = color
	_flash_color.a = strength

func _draw():
	var palette = _get_palette()
	# 多层色带模拟纵向渐变，兼容 GL Compatibility 与 Web。
	for i in range(18):
		var t = float(i) / 17.0
		var band_color: Color = palette[0].lerp(palette[1], t)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / 17.0 + 2.0), band_color)

	var center = Vector2(size.x * 0.5, size.y * (0.34 if variant == "battle" else 0.28))
	var ray_color: Color = palette[2]
	for i in range(20):
		var a0 = _time * 0.035 + TAU * float(i) / 20.0
		var a1 = a0 + TAU / 44.0
		var length = maxf(size.x, size.y) * 0.82
		var points = PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * length, center + Vector2(cos(a1), sin(a1)) * length])
		draw_colored_polygon(points, Color(ray_color.r, ray_color.g, ray_color.b, 0.035 if i % 2 == 0 else 0.018))

	# 中心光晕与边缘装饰，保留纸牌游戏的印刷纹理与聚光感。
	for i in range(6, 0, -1):
		var radius = 34.0 + i * 42.0 + sin(_time * 1.6) * 4.0
		draw_circle(center, radius, Color(ray_color.r, ray_color.g, ray_color.b, 0.012 * i))
	draw_circle(Vector2(size.x * 0.08, size.y * 0.18), 86.0, Color(1.0, 0.18, 0.58, 0.07))
	draw_circle(Vector2(size.x * 0.92, size.y * 0.72), 120.0, Color(0.05, 0.88, 1.0, 0.06))

	for p in _particles:
		var alpha = clampf(p.life / maxf(p.max_life, 0.01), 0.0, 1.0)
		var c: Color = p.color
		c.a *= alpha * 0.8
		draw_circle(p.pos, p.radius, c)
		if p.radius > 3.5:
			draw_line(p.pos - Vector2(p.radius * 2.0, 0), p.pos + Vector2(p.radius * 2.0, 0), c, 1.0)
			draw_line(p.pos - Vector2(0, p.radius * 2.0), p.pos + Vector2(0, p.radius * 2.0), c, 1.0)

	# 轻微扫描线/网点感，让扁平卡牌和 Q 版角色处在同一视觉世界里。
	for y in range(0, int(size.y), 5):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.01, 0.04, 0.04, 0.055), 1.0)

	if _flash_color.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), _flash_color)

func _make_particle(at: Vector2) -> Dictionary:
	var colors = [Color(0.95,0.73,0.25,0.72), Color(0.20,0.78,0.67,0.60), Color(0.87,0.25,0.22,0.55)]
	return {
		"pos": at,
		"velocity": Vector2(randf_range(-10.0, 10.0), randf_range(-34.0, -12.0)),
		"radius": randf_range(1.0, 3.8),
		"color": colors.pick_random(),
		"life": randf_range(2.0, 8.0),
		"max_life": 8.0,
	}

func _reset_particle(p: Dictionary):
	p.pos = Vector2(randf() * maxf(size.x, 480.0), size.y + randf_range(0.0, 80.0))
	p.velocity = Vector2(randf_range(-12.0, 12.0), randf_range(-42.0, -16.0))
	p.life = randf_range(4.0, 9.0)
	p.max_life = p.life

func _get_palette() -> Array:
	match variant:
		"menu": return [Color("10062d"), Color("33105d"), Color("ff3b9d")]
		"shop": return [Color("071d3b"), Color("13245a"), Color("21e6ff")]
		"result": return [Color("2b071d"), Color("5a150d"), Color("ffd34a")]
		_: return [Color("06191b"), Color("12383b"), Color("35c6aa")]

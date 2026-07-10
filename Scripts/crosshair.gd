extends Control

var dynamic_spread: float = 0.0


var hitmarker_alpha: float = 0.0
var hitmarker_color: Color = Color(1, 1, 1, 1)

func _ready():

	var player = get_tree().get_first_node_in_group("player")

	if player:
		if player.has_signal("spread_changed"):
			player.spread_changed.connect(_on_spread_changed)


		if player.has_signal("on_hit"):
			player.on_hit.connect(_on_enemy_hit)
	else:
		push_error("Crosshair: Игрок не найден!")

func _process(delta):

	if hitmarker_alpha > 0:
		hitmarker_alpha -= delta * 5.0
		if hitmarker_alpha < 0:
			hitmarker_alpha = 0.0


	queue_redraw()

func _on_spread_changed(new_spread):
	dynamic_spread = new_spread * 400.0


func _on_enemy_hit(is_headshot: bool):
	hitmarker_alpha = 1.0
	if is_headshot:
		hitmarker_color = Color(1.0, 0.0, 0.0, 1.0)
	else:
		hitmarker_color = Color(1.0, 1.0, 1.0, 1.0)


func _draw():
	var center = size / 2.0

	var color = Global.crosshair_color
	var length = max(Global.crosshair_length, 1.0)
	var thick = max(Global.crosshair_thickness, 1.0)
	var gap = Global.crosshair_base_gap + dynamic_spread


	if Global.crosshair_dot:
		var dot_rect = Rect2(center - Vector2(thick / 2.0, thick / 2.0), Vector2(thick, thick))
		draw_rect(dot_rect, color)


	draw_line(center + Vector2(gap, 0), center + Vector2(gap + length, 0), color, thick)
	draw_line(center + Vector2( - gap, 0), center + Vector2( - gap - length, 0), color, thick)
	draw_line(center + Vector2(0, gap), center + Vector2(0, gap + length), color, thick)
	draw_line(center + Vector2(0, - gap), center + Vector2(0, - gap - length), color, thick)


	if hitmarker_alpha > 0:
		var hm_color = hitmarker_color
		hm_color.a = hitmarker_alpha

		var hm_gap = gap + 4.0
		var hm_len = 10.0
		var hm_thick = 2.0


		draw_line(center + Vector2(hm_gap, hm_gap), center + Vector2(hm_gap + hm_len, hm_gap + hm_len), hm_color, hm_thick)
		draw_line(center + Vector2( - hm_gap, - hm_gap), center + Vector2( - hm_gap - hm_len, - hm_gap - hm_len), hm_color, hm_thick)
		draw_line(center + Vector2(hm_gap, - hm_gap), center + Vector2(hm_gap + hm_len, - hm_gap - hm_len), hm_color, hm_thick)
		draw_line(center + Vector2( - hm_gap, hm_gap), center + Vector2( - hm_gap - hm_len, hm_gap + hm_len), hm_color, hm_thick)

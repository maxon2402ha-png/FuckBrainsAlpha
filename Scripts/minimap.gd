extends ColorRect

var room_size = 18.0
var margin = 4.0

var player_node: Node3D

const COLOR_NEON = Color(0.0, 1.0, 0.4)

func _ready():

	color = Color(0, 0, 0, 0)
	clip_contents = true


	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_shader = Shader.new()
	bg_shader.code = "\n\tshader_type canvas_item;\n\tvoid fragment() {\n\t\tvec2 uv = UV;\n\t\tfloat scanline = sin(uv.y * 150.0 + TIME * 5.0) * 0.04;\n\t\tfloat grid = max(step(0.95, fract(uv.x * 10.0)), step(0.95, fract(uv.y * 10.0))) * 0.1;\n\t\tvec3 grid_color = vec3(0.0, 1.0, 0.4) * grid;\n\t\tCOLOR = vec4(0.01, 0.02, 0.01, 0.85) + vec4(scanline) + vec4(grid_color, 0.0);\n\t}\n\t"









	var bg_mat = ShaderMaterial.new()
	bg_mat.shader = bg_shader
	bg.material = bg_mat
	bg.show_behind_parent = true
	add_child(bg)


	var border = ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = COLOR_NEON
	border.border_width = 3.0
	border.editor_only = false
	add_child(border)


	var title = Label.new()
	title.text = "[ РАДАР ]"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", COLOR_NEON)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.position = Vector2(8, 4)
	add_child(title)


	player_node = get_tree().get_first_node_in_group("player")

func _process(_delta):

	queue_redraw()


func is_adjacent_to_discovered(pos: Vector2) -> bool:
	var neighbors = [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]
	for dir in neighbors:
		if (pos + dir) in Global.discovered_rooms:
			return true
	return false

func _draw():
	if Global.map_layout.is_empty():
		return

	var center = size / 2.0


	for pos in Global.map_layout:
		var is_discovered = pos in Global.discovered_rooms
		var is_neighbor = is_adjacent_to_discovered(pos)


		if not is_discovered and not is_neighbor:
			continue

		var offset_grid = pos - Global.current_room_pos
		var draw_pos = center + (offset_grid * (room_size + margin)) - Vector2(room_size / 2.0, room_size / 2.0)
		var rect = Rect2(draw_pos, Vector2(room_size, room_size))


		if not Rect2(Vector2.ZERO, size).intersects(rect.grow(10)):
			continue

		var fill_color = Color(0.0, 0.0, 0.0, 0.0)
		var outline_color = Color(0.0, 0.0, 0.0, 0.0)
		var border_width = 1.0


		if not is_discovered:
			fill_color = Color(0.0, 0.1, 0.05, 0.5)
			outline_color = Color(0.0, 0.3, 0.1, 0.6)


			if pos == Global.boss_room_pos: outline_color = Color(0.6, 0.0, 0.0, 0.8)
			elif pos == Global.gold_room_pos: outline_color = Color(0.6, 0.5, 0.0, 0.8)
			elif pos == Global.shop_room_pos: outline_color = Color(0.0, 0.4, 0.6, 0.8)


		else:
			fill_color = Color(0.0, 0.2, 0.1, 0.8)
			outline_color = Color(0.0, 0.6, 0.2, 0.9)

			if pos == Global.boss_room_pos:
				fill_color = Color(0.5, 0.0, 0.0, 0.9)
				outline_color = Color(1.0, 0.2, 0.2, 1.0)
			elif pos == Global.gold_room_pos:
				fill_color = Color(0.5, 0.4, 0.0, 0.9)
				outline_color = Color(1.0, 0.8, 0.0, 1.0)
			elif pos == Global.shop_room_pos:
				fill_color = Color(0.0, 0.3, 0.5, 0.9)
				outline_color = Color(0.0, 0.8, 1.0, 1.0)

			if pos == Global.current_room_pos:
				fill_color = Color(0.0, 0.8, 0.3, 0.4)
				outline_color = COLOR_NEON
				border_width = 2.0

		draw_rect(rect, fill_color)
		draw_rect(rect, outline_color, false, border_width)


		if is_discovered:
			for dir in [Vector2(0, -1), Vector2(1, 0)]:
				if (pos + dir) in Global.discovered_rooms:
					var door_pos = center + (offset_grid * (room_size + margin))
					var door_rect = Rect2()
					if dir == Vector2(0, -1):
						door_rect = Rect2(door_pos.x - 4, draw_pos.y - margin, 8, margin)
					else:
						door_rect = Rect2(draw_pos.x + room_size, door_pos.y - 4, margin, 8)


					if Rect2(Vector2.ZERO, size).intersects(door_rect):
						draw_rect(door_rect, outline_color)


	if is_instance_valid(player_node):
		var yaw = player_node.global_rotation.y


		var p1 = center + Vector2(0, - room_size * 0.5).rotated( - yaw)
		var p2 = center + Vector2( - room_size * 0.35, room_size * 0.4).rotated( - yaw)
		var p3 = center + Vector2(0, room_size * 0.15).rotated( - yaw)
		var p4 = center + Vector2(room_size * 0.35, room_size * 0.4).rotated( - yaw)

		var points = PackedVector2Array([p1, p2, p3, p4])


		var colors = PackedColorArray([Color(0.0, 1.0, 0.4), Color(0.0, 0.8, 0.2), Color(0.0, 0.6, 0.1), Color(0.0, 0.8, 0.2)])


		var shadow = PackedVector2Array([p1 + Vector2(2, 2), p2 + Vector2(2, 2), p3 + Vector2(2, 2), p4 + Vector2(2, 2)])
		draw_polygon(shadow, PackedColorArray([Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.9)]))


		draw_polygon(points, colors)
		draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), Color(1.0, 1.0, 1.0, 0.8), 1.5)

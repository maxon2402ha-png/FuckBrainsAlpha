extends ColorRect


@onready var map_draw_area = $MapDrawArea
@onready var stats_label = $StatsPanel / MarginContainer / StatsLabel
@onready var items_grid = $ItemsPanel / MarginContainer / ItemsGrid
@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip / MarginContainer / Label


var room_size = 40.0
var margin = 10.0


var vhs_overlay: ColorRect
var pause_label: Label
var vhs_time = 0.0




var item_database = {
	"baby_oil": {
		"name": "Детское масло", 
		"desc": "Оставляет скользкий след при движении", 
		"scene": preload("res://Scenes/Item_Baby_Oil.tscn")
	}, 
	"mge_photo": {
		"name": "Фото МГЕ брата", 
		"desc": "+5 к Удаче. Синергия с броней!", 
		"scene": preload("res://Scenes/Item_MGE_Photo.tscn")
	}, 
	"chingis_eggs": {
		"name": "Три яйца Чингисхана", 
		"desc": "Множитель удачи: x3\nМаг. сопротивление: +3", 
		"scene": preload("res://Scenes/Item_Chingis_Eggs.tscn")
	}, 
	"plunger": {
		"name": "Вантуз", 
		"desc": "15% шанс выстрелить вантузом\nОглушает врага на 1.5 сек.", 
		"scene": preload("res://Scenes/Item_Plunger.tscn")
	}
}

func _ready():
	visible = false
	tooltip.visible = false
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_draw_area.draw.connect(_on_map_draw)

	visibility_changed.connect(_on_visibility_changed)


	_setup_vhs_pause_effect()




func _setup_vhs_pause_effect():

	vhs_overlay = ColorRect.new()
	vhs_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vhs_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vhs_overlay.z_index = 100
	add_child(vhs_overlay)

	var shader = Shader.new()
	shader.code = "\n\tshader_type canvas_item;\n\tuniform float time;\n\tuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;\n\n\tvoid fragment() {\n\t\tvec2 uv = SCREEN_UV;\n\t\t\n\t\t// Сорванный трекинг (Дрожание нижней части экрана)\n\t\tif (uv.y > 0.85) {\n\t\t\tuv.x += sin(uv.y * 150.0 + time * 15.0) * 0.015;\n\t\t}\n\t\t\n\t\t// Случайные горизонтальные полосы-глитчи\n\t\tif (fract(uv.y * 6.0 - time * 0.8) < 0.05) {\n\t\t\tuv.x += sin(time * 50.0) * 0.005;\n\t\t}\n\t\t\n\t\t// Хроматическая аберрация (расслоение RGB)\n\t\tfloat offset = 0.003 + sin(time * 10.0) * 0.001;\n\t\tfloat r = texture(screen_texture, uv + vec2(offset, 0.0)).r;\n\t\tfloat g = texture(screen_texture, uv).g;\n\t\tfloat b = texture(screen_texture, uv - vec2(offset, 0.0)).b;\n\t\t\n\t\t// Белый шум\n\t\tfloat noise = fract(sin(dot(uv + time, vec2(12.9898,78.233))) * 43758.5453);\n\t\t\n\t\t// Сканлайны (полосы кинескопа)\n\t\tfloat scanline = sin(uv.y * 800.0) * 0.04;\n\t\t\n\t\t// Накладываем больше шума вниз экрана\n\t\tfloat final_noise = (uv.y > 0.85) ? noise * 0.4 : noise * 0.15;\n\t\t\n\t\tvec3 color = vec3(r - scanline + final_noise, g - scanline + final_noise, b - scanline + final_noise);\n\t\t\n\t\t// Легкое обесцвечивание пленки\n\t\tfloat gray = dot(color, vec3(0.299, 0.587, 0.114));\n\t\tcolor = mix(color, vec3(gray), 0.3);\n\t\t\n\t\tCOLOR = vec4(color, 1.0);\n\t}\n\t"









































	var mat = ShaderMaterial.new()
	mat.shader = shader
	vhs_overlay.material = mat


	pause_label = Label.new()
	pause_label.text = "PAUSE ||"
	pause_label.add_theme_font_size_override("font_size", 64)
	pause_label.add_theme_color_override("font_color", Color.WHITE)
	pause_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	pause_label.add_theme_constant_override("shadow_offset_x", 4)
	pause_label.add_theme_constant_override("shadow_offset_y", 4)

	pause_label.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	pause_label.offset_left = -320
	pause_label.offset_top = 40
	pause_label.z_index = 101
	add_child(pause_label)

func _on_visibility_changed():
	if visible:

		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		update_stats_ui()
		update_items_ui()
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		tooltip.visible = false

func _process(delta):
	if visible:
		vhs_time += delta


		if vhs_overlay and vhs_overlay.material:
			vhs_overlay.material.set_shader_parameter("time", vhs_time)


		if pause_label:
			pause_label.visible = int(vhs_time * 2.0) % 2 == 0

		map_draw_area.queue_redraw()

		if tooltip.visible:
			var mouse_pos = get_global_mouse_position()
			tooltip.global_position = mouse_pos + Vector2(15, - tooltip.size.y - 10)




func is_adjacent_to_discovered(pos: Vector2) -> bool:
	var neighbors = [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]
	for dir in neighbors:
		if (pos + dir) in Global.discovered_rooms:
			return true
	return false

func _on_map_draw():
	if Global.map_layout.is_empty():
		return

	var center = map_draw_area.size / 2.0

	for pos in Global.map_layout:
		var is_discovered = pos in Global.discovered_rooms
		var is_neighbor = is_adjacent_to_discovered(pos)

		if not is_discovered and not is_neighbor:
			continue

		var offset_grid = pos - Global.current_room_pos
		var draw_pos = center + (offset_grid * (room_size + margin)) - Vector2(room_size / 2.0, room_size / 2.0)

		var rect_color = Color(0.5, 0.5, 0.5, 0.6)

		if not is_discovered:
			rect_color = Color(0.3, 0.3, 0.3, 0.3)
			if pos == Global.boss_room_pos:
				rect_color = Color(0.5, 0.1, 0.1, 0.5)
			elif pos == Global.gold_room_pos:
				rect_color = Color(0.5, 0.4, 0.1, 0.5)
			elif pos == Global.shop_room_pos:
				rect_color = Color(0.1, 0.4, 0.6, 0.5)
		else:
			rect_color = Color(0.6, 0.6, 0.6, 0.8)
			if pos == Global.boss_room_pos:
				rect_color = Color(0.9, 0.2, 0.2, 0.8)
			elif pos == Global.gold_room_pos:
				rect_color = Color(0.9, 0.8, 0.2, 0.8)
			elif pos == Global.shop_room_pos:
				rect_color = Color(0.2, 0.6, 1.0, 0.8)

		map_draw_area.draw_rect(Rect2(draw_pos, Vector2(room_size, room_size)), rect_color)

		if pos == Global.current_room_pos:
			var player_mark_pos = draw_pos + Vector2(room_size * 0.25, room_size * 0.25)
			var player_mark_size = Vector2(room_size * 0.5, room_size * 0.5)
			map_draw_area.draw_rect(Rect2(player_mark_pos, player_mark_size), Color(0.2, 1.0, 0.2, 1.0))




func update_stats_ui():
	var stats_text = "[ УРОВЕНЬ %d ]\n\n" % Global.current_level

	stats_text += "[ ВЫЖИВАЕМОСТЬ ]\n"
	stats_text += "Здоровье: %d\n" % Global.get_final_max_health()
	stats_text += "Броня (Физ. защ): %d\n" % Global.armor
	stats_text += "Маг. сопротивление: %d\n" % Global.magic_resist

	stats_text += "\n[ ПЕРЕМЕЩЕНИЕ ]\n"
	var player_node = get_tree().get_first_node_in_group("player")
	var walk_speed = player_node.base_walk_speed if player_node and is_instance_valid(player_node) else 6.0
	stats_text += "Скорость бега: %.1f\n" % Global.get_final_speed(walk_speed)

	stats_text += "\n[ СТРЕЛЬБА И ОРУЖИЕ ]\n"
	stats_text += "Множ. урона: x%.2f\n" % Global.damage_multiplier
	stats_text += "Скор. атаки: x%.2f\n" % Global.fire_rate_multiplier
	stats_text += "Скор. перезарядки: x%.2f\n" % Global.reload_speed_multiplier
	stats_text += "Размер магазина: x%.2f\n" % Global.magazine_size_multiplier
	stats_text += "Шанс крита: %d%%\n" % (Global.crit_chance * 100.0)
	stats_text += "Множ. крита: x%.1f\n" % Global.crit_damage_mult
	stats_text += "Точность: x%.2f\n" % Global.spread_multiplier
	stats_text += "Отдача: x%.2f\n" % Global.recoil_multiplier

	var has_effects = false
	var effects_text = "\n[ ОСОБЫЕ ЭФФЕКТЫ ]\n"
	if Global.get_final_friendly_chance() > 0:
		effects_text += "Шанс призыва друга: %d%%\n" % (Global.get_final_friendly_chance() * 100.0)
		has_effects = true
	if Global.plunger_chance > 0:
		effects_text += "Шанс выстрела вантузом: %d%%\n" % (Global.plunger_chance * 100.0)
		has_effects = true

	if has_effects:
		stats_text += effects_text

	stats_text += "\n[ ПРОЧЕЕ ]\n"
	stats_text += "Удача: %.1f\n" % Global.luck

	stats_label.text = stats_text




func update_items_ui():
	for child in items_grid.get_children():
		child.queue_free()

	for raw_item_id in Global.inventory.keys():
		var count = Global.inventory[raw_item_id]
		var item_id = raw_item_id

		var data = item_database.get(item_id)

		if data and data.has("scene"):
			var container = SubViewportContainer.new()
			container.custom_minimum_size = Vector2(80, 80)
			container.stretch = true

			container.mouse_filter = Control.MOUSE_FILTER_STOP

			container.mouse_entered.connect(_on_item_hovered.bind(data, count))
			container.mouse_exited.connect(_on_item_unhovered)

			var viewport = SubViewport.new()
			viewport.transparent_bg = true
			viewport.own_world_3d = true
			container.add_child(viewport)

			var cam = Camera3D.new()
			cam.look_at_from_position(Vector3(0, 0.5, 1.5), Vector3.ZERO)
			viewport.add_child(cam)

			var light = DirectionalLight3D.new()
			light.rotation_degrees = Vector3(-45, 45, 0)
			viewport.add_child(light)

			var model = data["scene"].instantiate()
			_disable_collision(model)
			viewport.add_child(model)

			if count > 1:
				var count_label = Label.new()
				count_label.text = "x" + str(count)
				count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)

				count_label.add_theme_font_size_override("font_size", 20)
				count_label.add_theme_color_override("font_color", Color.YELLOW)
				count_label.add_theme_color_override("font_outline_color", Color.BLACK)
				count_label.add_theme_constant_override("outline_size", 4)

				container.add_child(count_label)

			items_grid.add_child(container)

func _disable_collision(node):
	if node is CollisionShape3D:
		node.disabled = true
	for child in node.get_children():
		_disable_collision(child)

func _on_item_hovered(item_data, count):
	tooltip_label.text = "[ %s ]\nУ вас: %d шт.\n\n%s" % [item_data["name"], count, item_data["desc"]]
	tooltip.visible = true
	tooltip.z_index = 105
	tooltip.move_to_front()

func _on_item_unhovered():
	tooltip.visible = false

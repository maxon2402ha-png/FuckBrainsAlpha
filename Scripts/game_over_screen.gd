extends Control

var sys_time = 0.0
var item_spinners: Array[Node3D] = []
var dynamic_titles: Array[Label] = []


var theme_blue_light = Color(0.36, 0.64, 0.84)
var theme_blue_dim = Color(0.2, 0.4, 0.6)
var theme_highlight = Color(0.1, 0.25, 0.4, 0.6)
var theme_dark = Color(0.02, 0.02, 0.02)

var badtrip_shader: ShaderMaterial
var ui_root: MarginContainer
var stats_grid_labels: Array[Label] = []
var items_cards: Array[Control] = []

var ui_audio_player: AudioStreamPlayer
var camcorder_layer: CanvasLayer
var is_ui_built: bool = false

var sound_ui_hover = preload("res://Assets/Sound/navel.mp3")
var sound_ui_click = preload("res://Assets/Sound/najal.mp3")

func _ready():
	self.set_anchors_preset(Control.PRESET_FULL_RECT)

	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.bus = "SFX"
	ui_audio_player.max_polyphony = 10
	add_child(ui_audio_player)

	if is_visible_in_tree():
		_init_game_over()

	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if is_instance_valid(camcorder_layer):
		camcorder_layer.visible = self.visible

	if is_visible_in_tree() and not is_ui_built:
		_init_game_over()

func _init_game_over():
	is_ui_built = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_build_perfect_menu_style_ui()
	populate_3d_items()
	_do_aaa_entrance()

func _play_hover():
	if sound_ui_hover and ui_audio_player:
		ui_audio_player.stream = sound_ui_hover
		ui_audio_player.pitch_scale = 1.0
		ui_audio_player.play()

func _play_click():
	if sound_ui_click and ui_audio_player:
		ui_audio_player.stream = sound_ui_click
		ui_audio_player.pitch_scale = 1.0
		ui_audio_player.play()

func _process(delta):
	if not is_ui_built or not visible: return

	sys_time += delta
	if badtrip_shader:
		badtrip_shader.set_shader_parameter("u_time", sys_time)

	for spinner in item_spinners:
		if is_instance_valid(spinner):
			spinner.rotate_y(delta * 1.5)


	for label in dynamic_titles:
		if is_instance_valid(label) and randf() < 0.02:
			label.modulate.a = randf_range(0.3, 0.7)
			await get_tree().create_timer(0.05).timeout
			if is_instance_valid(label):
				label.modulate.a = 1.0




func _build_perfect_menu_style_ui():
	var bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	var shader = Shader.new()
	shader.code = "\n    shader_type canvas_item;\n    uniform float u_time;\n\n    void fragment() {\n        vec2 uv = SCREEN_UV;\n        uv.x += sin(uv.y * 10.0 + u_time) * 0.005;\n        vec3 bg = vec3(0.04, 0.0, 0.0);\n        vec3 blob_col = vec3(0.18, 0.0, 0.02);\n        \n        vec2 p1 = vec2(0.2 + sin(u_time * 0.1)*0.1, 0.4 + cos(u_time * 0.15)*0.1);\n        vec2 p2 = vec2(0.8 + cos(u_time * 0.2)*0.1, 0.6 + sin(u_time * 0.1)*0.1);\n        \n        vec2 uv1 = uv * vec2(1.0, 0.5); p1 *= vec2(1.0, 0.5);\n        vec2 uv2 = uv * vec2(0.5, 1.0); p2 *= vec2(0.5, 1.0);\n        \n        float blobs = smoothstep(0.4, 0.1, distance(uv1, p1)) + smoothstep(0.4, 0.1, distance(uv2, p2));\n        vec3 final_color = mix(bg, blob_col, clamp(blobs, 0.0, 1.0));\n        \n        float vignette = smoothstep(1.0, 0.2, distance(SCREEN_UV, vec2(0.5)));\n        final_color *= vignette;\n        \n        float pulse = sin(u_time * 3.0) * 0.5 + 0.5;\n        final_color.r += pulse * 0.05 * vignette;\n        \n        float glitch = step(0.98, fract(sin(u_time * 10.0) * 43758.5453));\n        final_color.r += glitch * 0.15;\n        \n        final_color -= sin(SCREEN_UV.y * 1200.0) * 0.015;\n        COLOR = vec4(final_color, 1.0);\n    }\n\t"































	badtrip_shader = ShaderMaterial.new()
	badtrip_shader.shader = shader
	bg_rect.material = badtrip_shader

	_build_camcorder_hud()

	ui_root = MarginContainer.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_theme_constant_override("margin_left", 150)
	ui_root.add_theme_constant_override("margin_top", 100)
	ui_root.add_theme_constant_override("margin_right", 150)
	ui_root.add_theme_constant_override("margin_bottom", 100)
	add_child(ui_root)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 60)
	ui_root.add_child(main_vbox)

	var title_vbox = VBoxContainer.new()
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(title_vbox)

	var title1 = Label.new()
	title1.text = "FUCK BRAINS"
	title1.add_theme_font_size_override("font_size", 75)
	title1.add_theme_color_override("font_color", theme_blue_light)
	title1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title1.rotation_degrees = -3.0
	title1.pivot_offset = Vector2(810, 40)
	title_vbox.add_child(title1)
	dynamic_titles.append(title1)

	var title2 = Label.new()
	title2.text = "[ SYS.FATAL_ERROR ]"
	title2.add_theme_font_size_override("font_size", 28)
	title2.add_theme_color_override("font_color", theme_blue_dim)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(title2)
	dynamic_titles.append(title2)

	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 100)
	main_vbox.add_child(content_hbox)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.custom_minimum_size = Vector2(450, 0)
	stats_vbox.add_theme_constant_override("separation", 25)
	content_hbox.add_child(stats_vbox)

	var stats_header = Label.new()
	stats_header.text = "> RUN_REPORT"
	stats_header.add_theme_font_size_override("font_size", 28)
	stats_header.add_theme_color_override("font_color", theme_blue_dim)
	stats_vbox.add_child(stats_header)

	var r_time = Global.run_time if "run_time" in Global else 0.0
	var m = int(r_time) / 60
	var s = int(r_time) % 60
	var run_time_str = "%02d:%02d" % [m, s]
	_add_stat_row(stats_vbox, "ВРЕМЯ В СИСТЕМЕ", run_time_str)

	var rooms_count = Global.discovered_rooms.size() if "discovered_rooms" in Global else 0
	var items_count = Global.collected_items.size() if "collected_items" in Global else 0
	var earned_crystals = int(Global.score / 10.0) if "score" in Global else 0
	var total_score = Global.score if "score" in Global else 0

	stats_grid_labels.append(_add_stat_row(stats_vbox, "КОМНАТ ПРОЙДЕНО", str(rooms_count), false, true))
	stats_grid_labels.append(_add_stat_row(stats_vbox, "СОБРАНО ПРЕДМЕТОВ", str(items_count), false, true))
	stats_grid_labels.append(_add_stat_row(stats_vbox, "РУБЛИКОВ ЗАЛУТАНО", str(earned_crystals), false, true))

	var spacer = Control.new();spacer.custom_minimum_size.y = 20;stats_vbox.add_child(spacer)
	stats_grid_labels.append(_add_stat_row(stats_vbox, "ИТОГОВЫЙ СЧЕТ", str(total_score), true, true))

	var items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", 25)
	content_hbox.add_child(items_vbox)

	var items_header = Label.new()
	items_header.text = "> RETRIEVED_DATA"
	items_header.add_theme_font_size_override("font_size", 28)
	items_header.add_theme_color_override("font_color", theme_blue_dim)
	items_vbox.add_child(items_header)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	items_vbox.add_child(scroll)

	var items_grid = GridContainer.new()
	items_grid.name = "ItemsGrid"
	items_grid.columns = 6
	items_grid.add_theme_constant_override("h_separation", 20)
	items_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(items_grid)

	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_hbox.add_theme_constant_override("separation", 60)
	main_vbox.add_child(buttons_hbox)

	var btn_restart = Button.new()
	_style_main_menu_single_button(btn_restart, "ПЕРЕЗАПУСК")
	btn_restart.pressed.connect( func():
		_play_click()
		_on_restart_pressed()
	)
	buttons_hbox.add_child(btn_restart)

	var btn_menu = Button.new()
	_style_main_menu_single_button(btn_menu, "ВЫХОД")
	btn_menu.pressed.connect( func():
		_play_click()
		_on_menu_pressed()
	)
	buttons_hbox.add_child(btn_menu)

func _add_stat_row(parent: Control, lbl_text: String, val_text: String, is_highlight: bool = false, store_for_anim: bool = false) -> Label:
	var hb = HBoxContainer.new()
	var t1 = Label.new()
	t1.text = lbl_text
	t1.add_theme_font_size_override("font_size", 24)
	t1.add_theme_color_override("font_color", theme_blue_dim if not is_highlight else theme_blue_light)
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(t1)

	var t2 = Label.new()
	t2.text = "[ 0 ]" if store_for_anim else "[ " + val_text + " ]"
	t2.add_theme_font_size_override("font_size", 26)
	t2.add_theme_color_override("font_color", theme_blue_light if not is_highlight else Color.WHITE)
	if store_for_anim:
		t2.set_meta("target_val", int(val_text))
	hb.add_child(t2)
	parent.add_child(hb)
	return t2




func _style_main_menu_single_button(btn: Button, main_text: String) -> void :
	btn.text = ""
	btn.custom_minimum_size = Vector2(300, 60)
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var text_lbl = Label.new()
	text_lbl.text = main_text
	text_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.add_theme_font_size_override("font_size", 30)
	text_lbl.add_theme_color_override("font_color", theme_blue_light)
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(text_lbl)

	var hover_bg = ColorRect.new()
	hover_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hover_bg.color = theme_highlight
	hover_bg.visible = false
	hover_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hover_bg)
	btn.move_child(hover_bg, 0)

	btn.mouse_entered.connect( func():
		_play_hover()
		if btn.has_meta("shake_tween"):
			var st = btn.get_meta("shake_tween")
			if is_instance_valid(st): st.kill()
		if btn.has_meta("pulse_tween"):
			var pt = btn.get_meta("pulse_tween")
			if is_instance_valid(pt): pt.kill()

		hover_bg.visible = true
		text_lbl.add_theme_color_override("font_color", Color.WHITE)

		var shake_tween = create_tween()
		for j in range(4):
			shake_tween.tween_property(btn, "position:x", btn.position.x + randf_range(-5.0, 5.0), 0.03)
			shake_tween.tween_property(btn, "position:x", btn.position.x, 0.03)
		btn.set_meta("shake_tween", shake_tween)

		var pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(hover_bg, "color:a", 0.7, 0.1)
		pulse_tween.tween_property(hover_bg, "color:a", 0.4, 0.1)
		btn.set_meta("pulse_tween", pulse_tween)
	)

	btn.mouse_exited.connect( func():
		hover_bg.visible = false
		text_lbl.add_theme_color_override("font_color", theme_blue_light)

		if btn.has_meta("shake_tween"):
			var st = btn.get_meta("shake_tween")
			if is_instance_valid(st): st.kill()
			btn.remove_meta("shake_tween")

		if btn.has_meta("pulse_tween"):
			var pt = btn.get_meta("pulse_tween")
			if is_instance_valid(pt): pt.kill()
			btn.remove_meta("pulse_tween")
	)




func populate_3d_items():
	var grid = ui_root.find_child("ItemsGrid", true, false)
	if not grid: return

	var collected = []
	if Global.get("collected_items") != null:
		collected = Global.collected_items

	if collected.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "NO_DATA_FOUND"
		empty_lbl.add_theme_color_override("font_color", theme_blue_dim)
		empty_lbl.add_theme_font_size_override("font_size", 20)
		grid.add_child(empty_lbl)
		return

	var item_counts = {}
	for item in collected:
		if item_counts.has(item): item_counts[item] += 1
		else: item_counts[item] = 1

	for item_name in item_counts.keys():
		var count = item_counts[item_name]

		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(80, 80)
		var card_style = StyleBoxEmpty.new()
		card.add_theme_stylebox_override("panel", card_style)

		card.scale = Vector2.ZERO
		card.pivot_offset = Vector2(40, 40)
		items_cards.append(card)

		var vp_cont = SubViewportContainer.new()
		vp_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
		vp_cont.stretch = true
		card.add_child(vp_cont)

		var vp = SubViewport.new()
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.size = Vector2i(80, 80)
		vp_cont.add_child(vp)

		var cam = Camera3D.new()
		cam.fov = 40.0
		cam.look_at_from_position(Vector3(0, 0.8, 2.8), Vector3.ZERO)

		var env = Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = theme_blue_light
		env.ambient_light_energy = 1.0
		cam.environment = env
		vp.add_child(cam)

		var dir_light = DirectionalLight3D.new()
		dir_light.rotation_degrees = Vector3(-30, 45, 0)
		dir_light.light_color = Color(0.8, 0.9, 1.0)
		dir_light.light_energy = 1.5
		vp.add_child(dir_light)

		var spinner = Node3D.new()
		vp.add_child(spinner)
		item_spinners.append(spinner)

		var item_scene = _find_item_scene(item_name)
		var model_node = null
		if item_scene:
			model_node = item_scene.instantiate()
			model_node.process_mode = Node.PROCESS_MODE_DISABLED
			model_node.scale = Vector3(1.2, 1.2, 1.2)
			model_node.position = Vector3(0, -0.2, 0)
		else:
			model_node = MeshInstance3D.new()
			var box = BoxMesh.new();box.size = Vector3(0.6, 0.6, 0.6)
			var mat = StandardMaterial3D.new();mat.albedo_color = theme_blue_light
			box.material = mat
			model_node.mesh = box

		spinner.add_child(model_node)

		if count > 1:
			var count_label = Label.new()
			count_label.text = "x" + str(count)
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			count_label.add_theme_font_size_override("font_size", 16)
			count_label.add_theme_color_override("font_color", Color.WHITE)
			count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count_label.position = Vector2(-2, -2)
			card.add_child(count_label)

		grid.add_child(card)

func _find_item_scene(item_name: String) -> PackedScene:
	var search_name = item_name.replace("_", "").to_lower()
	for pool_item in Global.item_pool:
		var path = pool_item[0].resource_path.to_lower().replace("_", "")
		if search_name in path:
			return pool_item[0]
	return null




func _do_aaa_entrance():
	ui_root.modulate.a = 0.0

	var entrance_tween = create_tween()
	entrance_tween.tween_property(ui_root, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

	var valid_stats = 0
	for lbl in stats_grid_labels:
		if lbl.has_meta("target_val"): valid_stats += 1

	if valid_stats > 0:
		var count_tween = create_tween().set_parallel(true)
		for lbl in stats_grid_labels:
			if lbl.has_meta("target_val"):
				var target = lbl.get_meta("target_val")
				count_tween.tween_method(_animate_number_label.bind(lbl), 0, target, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	if items_cards.size() > 0:
		var cascade_tween = create_tween()
		for i in range(items_cards.size()):
			var card = items_cards[i]
			cascade_tween.tween_property(card, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			cascade_tween.tween_interval(0.05)

func _animate_number_label(val: int, lbl: Label):
	lbl.text = "[ " + str(val) + " ]"




func _build_camcorder_hud():
	camcorder_layer = CanvasLayer.new()
	camcorder_layer.layer = 5
	camcorder_layer.visible = self.visible
	add_child(camcorder_layer)

	var camcorder_hud = Control.new()
	camcorder_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	camcorder_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camcorder_layer.add_child(camcorder_hud)

	var rec_box = HBoxContainer.new()
	rec_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rec_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rec_box.position = Vector2(-120, 40)
	rec_box.add_theme_constant_override("separation", 10)
	camcorder_hud.add_child(rec_box)

	var rec_circle = Panel.new()
	rec_circle.custom_minimum_size = Vector2(20, 20)
	rec_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var circle_style = StyleBoxFlat.new()
	circle_style.bg_color = Color.RED
	circle_style.corner_radius_top_left = 100;circle_style.corner_radius_top_right = 100
	circle_style.corner_radius_bottom_left = 100;circle_style.corner_radius_bottom_right = 100
	rec_circle.add_theme_stylebox_override("panel", circle_style)
	rec_box.add_child(rec_circle)

	var blink_tween = create_tween().set_loops()
	blink_tween.tween_property(rec_circle, "modulate:a", 0.0, 0.5)
	blink_tween.tween_property(rec_circle, "modulate:a", 1.0, 0.5)

	var rec_label = Label.new()
	rec_label.text = "FAIL"
	rec_label.add_theme_font_size_override("font_size", 26)
	rec_label.add_theme_color_override("font_color", Color.RED)
	rec_box.add_child(rec_label)

	var batt_container = HBoxContainer.new()
	batt_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	batt_container.position = Vector2(40, 40)
	batt_container.add_theme_constant_override("separation", 10)
	camcorder_hud.add_child(batt_container)

	var batt_graphic = Control.new()
	batt_graphic.custom_minimum_size = Vector2(60, 26)
	batt_container.add_child(batt_graphic)

	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0, 0, 0, 0)
	border_style.border_width_left = 2;border_style.border_width_right = 2;border_style.border_width_top = 2;border_style.border_width_bottom = 2
	border_style.border_color = Color.RED
	border_style.corner_radius_top_left = 2;border_style.corner_radius_bottom_left = 2

	var batt_panel = Panel.new()
	batt_panel.add_theme_stylebox_override("panel", border_style)
	batt_panel.size = Vector2(54, 26)
	batt_graphic.add_child(batt_panel)

	var batt_tip = ColorRect.new();batt_tip.color = Color.RED;batt_tip.position = Vector2(54, 8);batt_tip.size = Vector2(4, 10);batt_graphic.add_child(batt_tip)

	var batt_text = Label.new()
	batt_text.text = "0%"
	batt_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	batt_text.add_theme_font_size_override("font_size", 24)
	batt_text.add_theme_color_override("font_color", Color.RED)
	batt_container.add_child(batt_text)

	var loop_tween = create_tween().set_loops()
	loop_tween.tween_property(batt_container, "modulate:a", 0.2, 0.4)
	loop_tween.tween_property(batt_container, "modulate:a", 1.0, 0.4)




func _on_restart_pressed():
	Global.reset_run()
	if has_node("/root/LoadingScreen"):
		LoadingScreen.change_scene("res://Scenes/level_generator.tscn", "SYS.REBOOT_INITIATED...")
	else:
		get_tree().change_scene_to_file("res://Scenes/level_generator.tscn")

func _on_menu_pressed():
	Global.reset_run()
	if has_node("/root/LoadingScreen"):
		LoadingScreen.change_scene("res://Scenes/main_menu.tscn", "CONNECTION_TERMINATED...")
	else:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

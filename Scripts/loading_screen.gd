extends CanvasLayer

@onready var bg = $Background
@onready var text_label = $Background / TextLabel
@onready var progress_label = $Background / ProgressLabel

var is_loading = false
var time_passed = 0.0
var current_target_scene: String = ""
var load_progress: float = 0.0
var ready_to_switch: bool = false
var load_requested: bool = false
var min_load_time: float = 1.5
var is_exiting_to_menu: bool = false

var base_offsets = {
	"text": {"left": 0.0, "right": 0.0, "top": 40.0, "bottom": 100.0}, 
	"prog": {"left": 40.0, "right": -40.0, "top": 120.0, "bottom": -200.0}, 
	"bar": {"left": 0.0, "right": 0.0, "top": 0.0, "bottom": 0.0}
}

var viewport_height: float = 1080.0


var bar_container: Control
var bar_graphic: Control
var bar_label: Label

var bar_max_width: float = 700.0
var bar_height: float = 35.0

var current_bar_type: int = 0
var visual_progress_smooth: float = 0.0
var last_drawn_progress: float = -1.0

var current_theme_color: Color
var complementary_color: Color
var madness_level: float = 1.0
var active_anim_type: int = 0
var text_anim_type: int = 0
var decipher_text: String = ""

var last_text_tick: int = -1
var shader_cache: Dictionary = {}

var spinner_frames = ["|", "/", "-", "\\", "X", "+", "§", "Ø", "Æ", "H"]
var corrupt_chars = ["X", "0", "1", "@", "#", "$", "%", "&", "▓", "▒", "░", "█", "┼", "╫", "≠", "╟", "◘"]
var binary_chars = ["0", "1", "0", "1", "_", "-", " "]

var loading_words = ["CORRUPTING", "DECRYPTING", "PURGING", "UPLOADING", "ASSIMILATING", "INJECTING", "COMPILING", "ERASING"]
var current_load_word = ""

var vhs_overlay: ColorRect
var vhs_mat: ShaderMaterial
var ascii_glitch_timer: Timer




var ascii_arts_extended = [
"""
         ▓▓▓▓▓▓▓▓▓▓
       ▓▓▓▓▒▒▒▒▒▒▒▒▓▓▓▓
     ▓▓▓▒▒▒░░░░░░░░▒▒▒▓▓▓
    ▓▓▒▒░░████░░████░░▒▒▓▓
   ▓▓▒░░░█████░░█████░░░▒▓▓
   ▓▒░░░░░░░░░░░░░░░░░░░░▒▓
   ▓▒░░░░▓▓▓▓▓▓▓▓▓▓▓▓░░░░▒▓
   ▓▓▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▓▓
    ▓▓▓▒░░CORE_DUMP░░▒▓▓▓
      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
       ██ ██ ██ ██ ██
""", 
"""
 [SYSTEM_ERROR_v.9]
 ░░▒▒▓▓██████▓▓▒▒░░
0110[CRITICAL]10100
 ▒▒█   HALT   █▒▒
▓▓██  OVERLOAD ██▓▓
 ▒▒█  FAILURE  █▒▒
1001[MEMORY_LEAK]11
 ░░▒▒▓▓██████▓▓▒▒░░
      [REBOOT]
  ... ... ... ...
""", 
"""
   .------------------.
  / [HUMAN_ASSET]      \\
 |  STATUS: TERMINATED  |
  \\_   _ _ _ _ _ _    _/
     / / / / / / / /
   █▓▒░░░░░░░░░░░░▒▓█
   █▓▒░  DATA_LOSS ░▒▓█
   █▓▒░░░░░░░░░░░░▒▓█
     \\_\\_\\_\\_\\_\\_\\_\\
           [0xFF]
""", 
"""
0x00000000:  FF FF FF FF FF FF FF FF  ........  [MEMORY_BLEED]
0x00000008:  48 45 4C 50 20 4D 45 00  HELP ME.  _-_-_-_-_-_-_-

    .▄▄ ·  ▄· ▄▌.▄▄ · ▄▄▄▄▄▄▄▄  ▄▄▄ . ▄▄▌  
    ▐█ ▀. ▐█▪██▌▐█ ▀. •██  ▀▄ █·▀▄.▀· ██•  
    ▄▀▀▀█▄▐█▌▐█▪▄▀▀▀█▄ ▐█.▪▐▀▀▄ ▐▀▀▪▄ ██▪  
    ▐█▄▪▐█ ▐█▀·.▐█▄▪▐█ ▐█▌·▐█•█▌▐█▄▄▌ ▐█▌▐▌
     ▀▀▀▀   ▀ •  ▀▀▀▀  ▀▀▀ .▀  ▀ ▀▀▀  .▀▀▀ 

============================================================
#%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@
$#@!   SYSTEM ARCHITECTURE COMPROMISED // CORTEX BURN   !@#$
#%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@!%&@
============================================================
> AWAITING DIRECTIVE... _
""", 
"""
   ._________________.
   | [SYS] FATAL     |
   |-----------------|
   | > USER: DEAD    |
   | > HOPE: 0%      |
   |_________________|
      |___________|
""", 
"""
    @ @ @ @ @ @
   @           @
  @   ▓ ▓ ▓ ▓   @
 @   ▓       ▓   @
  @   ▓ ▓ ▓ ▓   @
   @           @
    @ @ @ @ @ @
""", 
"\n     11010101\n    10██████01\n   11██░░░░██11\n   00████████00\n   01██0000██10\n    1101101101\n"







]

var exit_ascii_art = "\n    .-------.  \n   /  OFF    \\ \n  |    | |    |  \n   \\   \\_/   /   \n    '-------'  \n"







var base_phrases = [
	"> СИНХРОНИЗАЦИЯ НЕЙРО-ПРОТОКОЛОВ...", 
	"> ИЗВЛЕЧЕНИЕ ДАННЫХ ИЗ ПАМЯТИ...", 
	"> СЕКТОР НЕСТАБИЛЕН. ПОПЫТКА СВЯЗИ...", 
	"> ВЗЛОМ ОБОЛОЧКИ ПРОТИВНИКА...", 
	"> ПОИСК ВЫЖИВШИХ (ОШИБКА 404)...", 
	"> АНАЛИЗ БИОМЕТРИИ (КРОВЬ В СИСТЕМЕ)...", 
	"> ЗАГРУЗКА ПУСТОТЫ...", 
	"> КАЛИБРОВКА ОПТИЧЕСКОГО НЕРВА...", 
	"> СТИРАНИЕ ЧЕЛОВЕЧНОСТИ...", 
	"> ВНИМАНИЕ: УТЕЧКА ПАМЯТИ..."
]

var exit_phrases = [
	"> ЭКСТРЕННОЕ ОТКЛЮЧЕНИЕ СИСТЕМЫ...", 
	"> РАЗРЫВ НЕЙРОСЕТЕВОГО КОНТУРА...", 
	"> СТИРАНИЕ ВРЕМЕННЫХ ДАННЫХ ВЫЖИВАНИЯ...", 
	"> ОЧИСТКА БЛОКОВ ПАМЯТИ..."
]

func _ready():
	layer = 128
	bg.modulate.a = 0.0
	bg.color = Color.BLACK
	visible = false

	text_label.visible = false

	viewport_height = get_viewport().get_visible_rect().size.y


	text_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	progress_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	_apply_offsets(text_label, base_offsets["text"])
	_apply_offsets(progress_label, base_offsets["prog"])

	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var sys_font = SystemFont.new()
	sys_font.font_names = PackedStringArray(["Courier New", "Consolas", "Monospace"])
	progress_label.add_theme_font_override("font", sys_font)
	progress_label.add_theme_font_size_override("font_size", 22)

	_hide_scrollbars(self)
	_setup_vhs_shader()
	_setup_graphical_bar()

	ascii_glitch_timer = Timer.new()
	add_child(ascii_glitch_timer)
	ascii_glitch_timer.timeout.connect(_on_ascii_glitch)

func _hide_scrollbars(node: Node):
	if node is ScrollContainer:
		node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		node.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	elif node is RichTextLabel:
		node.scroll_active = false

	for child in node.get_children():
		_hide_scrollbars(child)

func _setup_graphical_bar():
	bar_container = Control.new()
	bg.add_child(bar_container)

	bar_graphic = Control.new()
	bar_graphic.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_graphic.draw.connect(_on_bar_draw)
	bar_container.add_child(bar_graphic)

	bar_label = Label.new()
	bar_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_label.add_theme_font_size_override("font_size", 28)

	bar_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	bar_label.add_theme_constant_override("shadow_offset_x", 4)
	bar_label.add_theme_constant_override("shadow_offset_y", 4)
	bar_container.add_child(bar_label)


func _apply_offsets(node: Control, offsets: Dictionary, drift_x: float = 0.0, drift_y: float = 0.0):
	node.offset_left = offsets["left"] + drift_x
	node.offset_right = offsets["right"] + drift_x
	node.offset_top = offsets["top"] + drift_y
	node.offset_bottom = offsets["bottom"] + drift_y

func _setup_vhs_shader():
	vhs_overlay = ColorRect.new()
	vhs_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vhs_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(vhs_overlay)
	bg.move_child(vhs_overlay, 0)
	vhs_mat = ShaderMaterial.new()
	vhs_overlay.material = vhs_mat

func _apply_background_shader():
	var shader = Shader.new()
	var shader_logic = ""

	match active_anim_type % 10:
		0: shader_logic = "float line_pos = (uv.x + uv.y) * 4.0 - u_movement; float stripe = step(0.85, fract(line_pos)); color_out = mix(bg_color, theme_color, stripe);"
		1: shader_logic = "float wave = sin(uv.y * 10.0 + u_movement) * 0.1; float stripe = step(0.5, fract(uv.x * 5.0 + wave)); color_out = mix(bg_color, theme_color, stripe * 0.5);"
		2: shader_logic = "vec2 grid_uv = floor(uv * 20.0); float grid_noise = fract(sin(grid_uv.x + grid_uv.y + floor(u_movement)) * 43758.54); float block = step(0.9 - (madness * 0.02), grid_noise); color_out = mix(bg_color, theme_color, block * 0.4);"
		3: shader_logic = "float noise_st = fract(sin(uv.x * uv.y + TIME) * 43758.54); float noise_fine = step(0.95, noise_st); color_out = mix(bg_color, theme_color, noise_fine * 0.2);"
		4: shader_logic = "vec2 g = floor(uv * vec2(50.0, 10.0)); float rain = fract(sin(dot(g, vec2(12.9898, 78.233)) + u_movement) * 43758.54); color_out = mix(bg_color, theme_color, step(0.9, rain) * fract(uv.y * 10.0 - u_movement * 2.0));"
		5: shader_logic = "vec2 grid = fract(uv * 8.0 + sin(u_movement)); float hex = step(0.5, max(abs(grid.x - 0.5), abs(grid.y - 0.5))); color_out = mix(bg_color, theme_color, hex * 0.2);"
		6: shader_logic = "float w1 = sin(uv.x * 30.0 + u_movement * 2.0); float w2 = sin(uv.y * 30.0 - u_movement * 2.0); float moire = step(0.8, fract(w1 + w2)); color_out = mix(bg_color, theme_color, moire * 0.2);"
		7: shader_logic = "float y_glitch = step(0.95, fract(sin(uv.y * 50.0 + floor(u_movement * 10.0)) * 43758.5)); color_out = mix(bg_color, theme_color, y_glitch * 0.3);"
		8: shader_logic = "float noise = fract(sin(dot(uv + floor(u_movement * 10.0), vec2(12.9898,78.233))) * 43758.5453); color_out = mix(bg_color, theme_color, step(0.8, noise) * 0.3);"
		9: shader_logic = "vec2 grid = fract(uv * vec2(20.0, 2.0)); float wave = sin(uv.x * 10.0 + u_movement) * 0.5 + 0.5; float eq = step(grid.y, wave); color_out = mix(bg_color, theme_color, eq * step(0.1, grid.x) * 0.3);"
		_: shader_logic = "vec2 grid_uv = floor(uv * 20.0); float grid_noise = fract(sin(grid_uv.x + grid_uv.y + floor(u_movement)) * 43758.54); float block = step(0.9 - (madness * 0.02), grid_noise); color_out = mix(bg_color, theme_color, block * 0.4);"

	shader.code = """
	shader_type canvas_item;
	uniform vec3 theme_color;
	uniform float madness;
	uniform float u_processed_time;
	uniform float u_movement;
	uniform float u_glitch_shift;

	float random(vec2 uv) { return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123); }

	void fragment() {
		vec2 raw_uv = SCREEN_UV;
		if (fract(sin(dot(vec2(u_processed_time * 0.01, floor(raw_uv.y * 10.0)), vec2(12.9898, 78.233))) * 43758.5453) > 0.98 - (madness * 0.01)) {
			raw_uv.x += 0.08 * sin(u_processed_time * 20.0);
		}
		raw_uv.x += u_glitch_shift;
		
		vec2 uv = floor(raw_uv * vec2(320.0, 240.0)) / vec2(320.0, 240.0);
		
		float grain = step(0.75, random(uv * u_processed_time)) * 0.2;
		float bg_noise = step(0.95, fract(sin(dot(uv.xy + u_processed_time * 0.01, vec2(12.9898, 78.233))) * 43758.5453));
		vec3 bg_color = vec3(0.0) + bg_noise * theme_color * 0.3; 
		float scanline = step(0.5, fract(SCREEN_UV.y * 240.0)) * 0.4;
		
		vec3 color_out = vec3(0.0);
		""" + shader_logic + "\n\t\t\n\t\tcolor_out += grain;\n\t\tcolor_out -= scanline; \n\t\tcolor_out = floor(color_out * 5.0) / 5.0;\n\t\t\n\t\tCOLOR = vec4(color_out, 1.0);\n\t}\n\t"








	vhs_mat.shader = shader

func _hash_gd(n: float) -> float:
	var res = sin(n) * 43758.5453123
	return res - floor(res)

func _generate_random_bar_settings():
	current_load_word = loading_words.pick_random()
	current_bar_type = randi() % 2

	bar_max_width = randf_range(500.0, 800.0)
	bar_height = 40.0

	bar_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)

	var bottom_margin = randf_range(100.0, 150.0)


	base_offsets["bar"]["left"] = - bar_max_width / 2.0
	base_offsets["bar"]["right"] = bar_max_width / 2.0
	base_offsets["bar"]["top"] = - bottom_margin - bar_height
	base_offsets["bar"]["bottom"] = - bottom_margin

	_apply_offsets(bar_container, base_offsets["bar"])

	bar_label.add_theme_color_override("font_color", Color.WHITE)
	visual_progress_smooth = 0.0
	last_drawn_progress = -1.0

func change_scene(target_scene: String, custom_text: String = ""):
	visible = true
	is_loading = true
	time_passed = 0.0
	load_progress = 0.0
	visual_progress_smooth = 0.0
	ready_to_switch = false
	load_requested = false
	current_target_scene = target_scene
	is_exiting_to_menu = target_scene.contains("main_menu")

	if Global.get("active_anim_type") != null and Global.active_anim_type != -1:
		active_anim_type = Global.active_anim_type
	else:
		active_anim_type = randi() % 20

	var color_palettes = [
		Color("#ff003c"), Color("#39ff14"), Color("#0ff0fc"), 
		Color("#ffea00"), Color("#7a04eb"), Color("#ff7b00")
	]
	current_theme_color = color_palettes.pick_random()
	if is_exiting_to_menu:
		current_theme_color = Color(0.3, 0.3, 0.3)

	madness_level = randf_range(1.0, 3.0)
	if is_exiting_to_menu: madness_level = 0.5

	_apply_background_shader()
	vhs_mat.set_shader_parameter("theme_color", Vector3(current_theme_color.r, current_theme_color.g, current_theme_color.b))
	vhs_mat.set_shader_parameter("madness", madness_level)

	progress_label.add_theme_color_override("font_color", current_theme_color)
	progress_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	progress_label.add_theme_constant_override("shadow_offset_x", 4)
	progress_label.add_theme_constant_override("shadow_offset_y", 4)

	_generate_random_bar_settings()


	var final_text = ascii_arts_extended.pick_random() + "\n\n"
	if is_exiting_to_menu:
		final_text += "=== [ ПРОЦЕДУРА ЗАВЕРШЕНИЯ ] ===\n\n"
		final_text += "> НЕ ОБНАРУЖЕН СИГНАЛ ДЛЯ ПОДКЛЮЧЕНИЯ, ПЕРЕХОД В АВТОНОМНЫЙ РЕЖИМ...\n\n"
		var phrase_count = randi_range(2, 3)
		for i in range(phrase_count): final_text += exit_phrases.pick_random() + "\n"
		final_text += "\n[ ДИРЕКТИВА: ВОЗВРАТ В ОСНОВНУЮ ОБОЛОЧКУ ]"
	else:
		var curr_lvl = Global.current_level if Global.get("current_level") != null else 1
		if curr_lvl <= 5:
			final_text += "=== [ ТЕКУЩИЙ УРОВЕНЬ ОБЪЕКТА: ЭТАЖ %d ] ===\n\n" % (6 - curr_lvl)
		else:
			final_text += "=== [ КРИТИЧЕСКАЯ ГЛУБИНА: ЯДРО ] ===\n\n"

		final_text += "> НЕ ОБНАРУЖЕН СИГНАЛ ДЛЯ ПОДКЛЮЧЕНИЯ, ПЕРЕХОД В АВТОНОМНЫЙ РЕЖИМ...\n\n"
		if custom_text != "":
			final_text += "> " + custom_text.replace("> ", "") + "\n"
		else:

			for i in range(randi_range(2, 4)): final_text += base_phrases.pick_random() + "\n"
		final_text += "\n[ ЦЕЛЕВАЯ ДИРЕКТИВА: " + target_scene.get_file().get_basename().to_upper() + " ]"

	progress_label.text = final_text
	progress_label.visible_characters = 0

	var type_tween = create_tween()
	type_tween.tween_property(progress_label, "visible_characters", final_text.length(), 1.0)

	var bg_tween = create_tween()
	bg_tween.tween_property(bg, "modulate:a", 1.0, 0.2)

	ascii_glitch_timer.start(0.1)

	ResourceLoader.load_threaded_request(current_target_scene)
	load_requested = true
	await get_tree().create_timer(min_load_time).timeout
	ready_to_switch = true

func _on_ascii_glitch():
	ascii_glitch_timer.wait_time = randf_range(0.05, 0.3) / clamp(madness_level, 1.0, 3.0)
	if randf() > 0.6:
		progress_label.modulate.a = [0.1, 0.4, 0.8, 1.0].pick_random()
		if randf() > 0.7:
			progress_label.add_theme_color_override("font_color", [Color.WHITE, current_theme_color, Color.BLACK].pick_random())
	else:
		progress_label.modulate.a = 1.0
		progress_label.add_theme_color_override("font_color", current_theme_color)

func _process(delta):
	if not is_loading: return
	time_passed += delta

	if current_target_scene != "" and load_requested:
		var progress_array = []
		var status = ResourceLoader.load_threaded_get_status(current_target_scene, progress_array)

		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			load_progress = progress_array[0]
		elif status == ResourceLoader.THREAD_LOAD_LOADED:
			load_progress = 1.0
			if ready_to_switch:
				ready_to_switch = false
				call_deferred("_switch_to_loaded_scene")
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			is_loading = false
			visible = false
			load_requested = false

	if vhs_mat:
		var time_step = floor(time_passed * 12.0) / 12.0
		if randf() > 0.98: time_step -= randf_range(0.1, 0.3)
		var p_time = time_step
		var move = p_time * 0.8 + floor(sin(p_time * 2.0) * 5.0) / 5.0

		vhs_mat.set_shader_parameter("u_processed_time", p_time)
		vhs_mat.set_shader_parameter("u_movement", move)

		var row_id = floor(get_viewport().get_visible_rect().size.y * 0.5 * (10.0 + madness_level * 2.0))
		var glitch_trigger = _hash_gd(row_id + p_time * (2.0 + madness_level * 0.5))
		var glitch_shift = 0.0
		if glitch_trigger > (1.0 - madness_level * 0.02):
			glitch_shift = (randf() - 0.5) * (0.3 * madness_level)
		vhs_mat.set_shader_parameter("u_glitch_shift", glitch_shift)

	var target_progress = min(1.0, (time_passed / min_load_time) * 0.3 + load_progress * 0.7)
	var step_size = 0.05
	var snapped_target = floor(target_progress / step_size) * step_size

	if visual_progress_smooth < snapped_target:
		visual_progress_smooth = snapped_target

	_process_graphical_bar()
	_update_glitch_drifts()


func _update_glitch_drifts():
	var step_time = floor(time_passed * 12.0)
	var trigger = _hash_gd(step_time + madness_level)

	var drift_x = 0.0
	var drift_y = 0.0

	if trigger > 0.85:
		drift_x = floor((randf() - 0.5) * 20.0 * madness_level)
		drift_y = floor((randf() - 0.5) * 10.0 * madness_level)

	_apply_offsets(text_label, base_offsets["text"], - drift_x, drift_y)
	_apply_offsets(progress_label, base_offsets["prog"], drift_x, drift_y)
	_apply_offsets(bar_container, base_offsets["bar"], drift_x * 0.5, drift_y)

func _process_graphical_bar():
	if bar_graphic and abs(visual_progress_smooth - last_drawn_progress) > 0.001:
		last_drawn_progress = visual_progress_smooth
		bar_graphic.queue_redraw()

	var curr_percent = int(visual_progress_smooth * 100.0)
	var scrambled_word = current_load_word

	var current_text_tick = int(time_passed * 15.0)
	if madness_level > 1.5 and current_text_tick % 3 == 0:
		if randf() < 0.1:
			scrambled_word = ""
			for i in range(current_load_word.length()):
				scrambled_word += corrupt_chars[randi() % corrupt_chars.size()] if randf() < 0.3 else current_load_word[i]

	bar_label.text = "[ %s %d%% ]" % [scrambled_word, curr_percent]

func _on_bar_draw():
	if not bar_graphic: return

	var w = bar_max_width
	var h = bar_height
	var p = visual_progress_smooth
	var c_fill = current_theme_color
	var shadow_offset = Vector2(8, 8)

	bar_graphic.draw_rect(Rect2(shadow_offset.x, shadow_offset.y, w, h), Color.BLACK)
	bar_graphic.draw_rect(Rect2(0, 0, w, h), Color.BLACK)

	var fill_w = w * p

	if current_bar_type == 0:
		bar_graphic.draw_rect(Rect2(0, 0, fill_w, h), c_fill)
	else:
		var segments = 25
		var seg_w = w / float(segments)
		for i in range(segments):
			if float(i) / float(segments) < p:
				bar_graphic.draw_rect(Rect2(i * seg_w, 0, seg_w - 4.0, h), c_fill)

	var border_pts = PackedVector2Array([
		Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h), Vector2(0, 0)
	])
	bar_graphic.draw_polyline(border_pts, c_fill, 4.0)

func _switch_to_loaded_scene() -> void :
	ascii_glitch_timer.stop()
	var loaded_scene = ResourceLoader.load_threaded_get(current_target_scene)
	get_tree().change_scene_to_packed(loaded_scene)
	current_target_scene = ""
	load_requested = false

	var tween_out = create_tween()
	tween_out.tween_property(bg, "modulate:a", 0.0, 0.2)
	await tween_out.finished

	is_loading = false
	visible = false

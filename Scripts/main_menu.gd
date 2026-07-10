extends Control


var hover_sound = preload("res://Assets/Music/AmbientG.mp3")


var ui_audio_player: AudioStreamPlayer
var sound_ui_hover = preload("res://Assets/Sound/navel.mp3")
var sound_ui_click = preload("res://Assets/Sound/najal.mp3")




@onready var menu_buttons: Control = $MenuButtons
@onready var settings_panel: Control = $SettingsPanel
@onready var loadout_panel: Control = $LoadoutPanel

@onready var play_button: Button = $MenuButtons / PlayButton
@onready var loadout_button: Button = $MenuButtons / LoadoutButton
@onready var settings_button: Button = $MenuButtons / SettingsButton
@onready var quit_button: Button = $MenuButtons / QuitButton

@onready var close_settings_button: Button = find_child("CloseButton", true, false) as Button




@onready var sens_slider: Slider = find_child("SensSlider", true, false) as Slider
@onready var sens_value_label: Label = sens_slider.get_parent().get_node("LabelValue") if sens_slider else null

@onready var vhs_toggle: CheckButton = find_child("VHSToggle", true, false) as CheckButton
@onready var style_option: OptionButton = find_child("StyleOption", true, false) as OptionButton
@onready var noise_slider: Slider = find_child("NoiseSlider", true, false) as Slider
@onready var rgb_slider: Slider = find_child("RGBSlider", true, false) as Slider
@onready var vhs_intensity_slider: Slider = find_child("VHSIntensitySlider", true, false) as Slider

@onready var stats_format_toggle: CheckButton = find_child("StatsFormatToggle", true, false) as CheckButton


var damage_numbers_toggle: CheckButton

@onready var color_picker: ColorPickerButton = find_child("ColorPickerButton", true, false) as ColorPickerButton
@onready var length_slider: Slider = find_child("LengthSlider", true, false) as Slider
@onready var length_value_label: Label = length_slider.get_parent().get_node("LabelValue") if length_slider else null
@onready var gap_slider: Slider = find_child("GapSlider", true, false) as Slider
@onready var gap_value_label: Label = gap_slider.get_parent().get_node("LabelValue") if gap_slider else null
@onready var thickness_slider: Slider = find_child("ThicknessSlider", true, false) as Slider
@onready var thickness_value_label: Label = thickness_slider.get_parent().get_node("LabelValue") if thickness_slider else null
@onready var crosshair_preview: Control = find_child("CrosshairPreview", true, false) as Control

@onready var master_slider: Slider = find_child("MasterSlider", true, false) as Slider
@onready var master_value_label: Label = master_slider.get_parent().get_node("LabelValue") if master_slider else null
@onready var music_slider: Slider = find_child("MusicSlider", true, false) as Slider
@onready var music_value_label: Label = music_slider.get_parent().get_node("LabelValue") if music_slider else null
@onready var sfx_slider: Slider = find_child("SFXSlider", true, false) as Slider
@onready var sfx_value_label: Label = sfx_slider.get_parent().get_node("LabelValue") if sfx_slider else null

@onready var bind_list: Control = find_child("BindList", true, false) as Control
@onready var res_option: OptionButton = find_child("ResOption", true, false) as OptionButton
@onready var window_option: OptionButton = find_child("WindowOption", true, false) as OptionButton
@onready var aa_option: OptionButton = find_child("AAOption", true, false) as OptionButton
@onready var quality_option: OptionButton = find_child("QualityOption", true, false) as OptionButton
@onready var brightness_slider: Slider = find_child("BrightnessSlider", true, false) as Slider
@onready var vsync_check: CheckButton = find_child("VSyncCheck", true, false) as CheckButton


var action_translations: Dictionary = {
	"move_forward": "ВПЕРЕД", "move_back": "НАЗАД", "move_left": "ВЛЕВО", "move_right": "ВПРАВО", 
	"jump": "ПРЫЖОК", "crouch": "ПРИСЕСТЬ", "sprint": "БЕГ", "reload": "ПЕРЕЗАРЯДКА", "interact": "ВЗАИМОДЕЙСТВИЕ"
}
var listening_action: String = ""
var listening_button: Button = null

var resolutions: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(800, 600)]

var vhs_time: float = 0.0
var bg_shader_mat: ShaderMaterial
var camcorder_hud: Control
var stylized_ui_panel: Control




var weapons_db: Dictionary = {
	"pistol": {"name": "ПИСТОЛЕТ M1911", "dmg": 12, "ammo": 15, "fire_rate": 0.25, "reload": 1.5, "recoil": "НИЗКАЯ", "scene": null}, 
	"rifle": {"name": "ШТУРМОВАЯ ВИНТОВКА", "dmg": 7, "ammo": 40, "fire_rate": 0.12, "reload": 2.2, "recoil": "СРЕДНЯЯ", "scene": null}, 
	"shotgun": {"name": "ПОМПОВЫЙ ДРОБОВИК", "dmg": 10, "ammo": 8, "fire_rate": 1.0, "reload": 3.0, "recoil": "ВЫСОКАЯ", "scene": null}
}

var perks_db: Dictionary = {
	"none": {"name": "БЕЗ ПЕРКА", "desc": "ИГРАТЬ БЕЗ БОНУСОВ", "lore": "СТАНДАРТНАЯ ЭКИПИРОВКА.", "color": Color(0.3, 0.3, 0.3)}, 
	"friendly_spawn": {"name": "ДРУЖЕЛЮБНЫЙ ЗОМБИ", "desc": "ШАНС 5% НА СПАВН\nСОЮЗНИКА.", "lore": "ОН ПОМНИТ ТЕБЯ.", "color": Color(0.3, 0.8, 0.3)}, 
	"magic_dmg_boost": {"name": "МАГИЧЕСКАЯ ПУЛЯ", "desc": "УВЕЛИЧИВАЕТ ВЕСЬ МАГ.\nУРОН НА 5.", "lore": "ОСТАТКИ ЭКСПЕРИМЕНТОВ.", "color": Color(0.8, 0.2, 0.9)}
}

var skills_db: Dictionary = {
	"health": {"name": "Макс. Здоровье", "base_cost": 15}, "damage": {"name": "Урон Оружия", "base_cost": 20}, 
	"speed": {"name": "Скорость Бега", "base_cost": 10}, "fire_rate": {"name": "Скорострельность", "base_cost": 15}, 
	"crit_chance": {"name": "Шанс Крита", "base_cost": 15}, "crit_damage": {"name": "Урон Крита", "base_cost": 20}, 
	"armor": {"name": "Броня (Защита)", "base_cost": 25}, "luck": {"name": "Удача", "base_cost": 30}, 
	"accuracy": {"name": "Точность", "base_cost": 15}, "recoil": {"name": "Контроль отдачи", "base_cost": 15}, 
	"melee_damage": {"name": "Урон ближнего боя", "base_cost": 10}, "reload_speed": {"name": "Скорость перезарядки", "base_cost": 20}, 
	"magazine_size": {"name": "Размер магазина", "base_cost": 25}
}
var max_skill_level: int = 10
var unlock_milestones: Dictionary = {}

var loadout_tabs: Array[Control] = []
var weapon_spinners: Array[Node3D] = []
var current_unlock_spinner: Node3D = null
var money_header_label: Label
var current_loadout_tab: int = 0

var wpn_btns: Dictionary = {}
var prk_btns: Dictionary = {}
var skl_btns: Dictionary = {}
var skl_lbls: Dictionary = {}

var dynamic_titles: Array[Label] = []


var current_theme_color: Color
var madness_level: float = 1.0
var active_anim_type: int = 0
var current_ascii_art_index: int = 0

var ascii_arts = [
"""
     .:::::.     
    :::::::::    
   ::       ::   
   :: 0   0 ::   
   ::   ^   ::   
    :: ... ::    
     :::::::     
""", 
"""
    /\\     /\\    
   /  \\___/  \\   
  (   o   o   )  
   \\   w   /   
    \\_______/    
""", 
"""
   +-------+   
   | [SYS] |   
   | F A I |   
   | L E D |   
   +-------+   
""", 
"""
   \\\\|||||//   
  --       --  
  -- (O_O) --  
  --   _   --  
   //|||||\\\\   
""", 
"""
      _..._      
    /       \\    
   |  X   X  |   
   |    ^    |   
   |  #####  |   
    \\_______/    
""", 
"""
       /!\\       
      / ! \\      
     /  !  \\     
    /___!___\\    
""", 
"""
   .---------.   
  /           \\  
 |  ( @ ) ( @ ) | 
  \\           /  
   '---------'   
""", 
"""
    [=======]    
    | O   O |    
    |_______|    
""", 
"""
  \\_       _/  
   \\_     _/   
     \\_ _/     
      | |      
      |_|      
""", 
"""
   .:*~*:._.:*~*:.
   | ERROR 404 |
   | NOT FOUND |
   ':._.:*~*:._.:'
""", 
"""
    _.---._    
  .'       '.  
  |  O   O  |  
  |  \\___/  |  
   '.     .'   
     `---`     
""", 
"""
   [WARNING]   
   |||||||||   
   [ CRIT! ]   
""", 
"""
    /\\_/\\      
   ( o.o )     
    > ^ <      
""", 
"""
   --.   .--   
  |  `-'  |  
  | (o) (o) |  
   `-.   .-`   
     | | |     
""", 
"""
 1010  0101    
 0101  1010    
 1010  0101    
""", 
"""
  .-------.    
  | >_    |    
  |       |    
  '-------'    
""", 
"""
   _______     
  |  ___  |    
  | |   | |    
  | |___| |    
  |_______|    
""", 
"""
   \\ \\ | / /   
  - - ( ) - -  
   / / | \\ \\   
""", 
"""
   .-------.   
  (  ABORT  )  
   '-------'   
""", 
"\n      _____      \n    /       \\    \n  | () () |    \n   \\  ^  /     \n    |||||      \n"






]

func _play_ambient_hover():
	var ap = AudioStreamPlayer.new()
	ap.stream = hover_sound
	ap.volume_db = -10.0
	ap.bus = "SFX"
	add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

func _ready() -> void :
	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.bus = "SFX"
	ui_audio_player.max_polyphony = 10
	add_child(ui_audio_player)

	if Global.has_method("play_menu_music"):
		Global.play_menu_music()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	settings_panel.visible = false
	loadout_panel.visible = false
	menu_buttons.visible = true


	self.set_anchors_preset(Control.PRESET_TOP_LEFT)
	self.size = Vector2(1920.0, 1080.0)
	self.pivot_offset = Vector2.ZERO

	settings_panel.rotation_degrees = 0.0
	loadout_panel.rotation_degrees = 0.0


	get_viewport().size_changed.connect(_on_window_resized)

	_connect_signals_to_hover()

	if play_button and not play_button.pressed.is_connected(_on_play_button_pressed): play_button.pressed.connect(_on_play_button_pressed)
	if loadout_button and not loadout_button.pressed.is_connected(_on_loadout_button_pressed): loadout_button.pressed.connect(_on_loadout_button_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed): settings_button.pressed.connect(_on_settings_button_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_button_pressed): quit_button.pressed.connect(_on_quit_button_pressed)
	if close_settings_button and not close_settings_button.pressed.is_connected(_on_close_panels): close_settings_button.pressed.connect(_on_close_panels)

	if sens_slider: sens_slider.value_changed.connect(_on_sens_changed)
	if color_picker: color_picker.color_changed.connect(_on_color_changed)
	if length_slider: length_slider.value_changed.connect(_on_length_changed)
	if gap_slider: gap_slider.value_changed.connect(_on_gap_changed)
	if thickness_slider: thickness_slider.value_changed.connect(_on_thickness_changed)
	if master_slider: master_slider.value_changed.connect(_on_master_changed)
	if music_slider: music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider: sfx_slider.value_changed.connect(_on_sfx_changed)

	if crosshair_preview:
		if not crosshair_preview.draw.is_connected(_on_preview_draw):
			crosshair_preview.draw.connect(_on_preview_draw)
		crosshair_preview.queue_redraw()

	_connect_graphics_signals()

	setup_graphics_settings()
	update_ui_from_global()
	build_keybind_list()

	_remove_old_labels(self)

	_generate_random_menu_theme()
	_setup_generative_background()

	_stylize_main_menu_buttons()
	_stylize_settings_window()


	_create_damage_toggle_ui()

	_apply_manhunt_theme_recursive(settings_panel)
	_build_advanced_loadout_ui()

	_connect_sounds_to_all_buttons(self)


	_on_window_resized()


	visibility_changed.connect( func():
		if visible:
			update_ui_from_global()
	)

	if play_button:
		play_button.grab_focus()


func _on_window_resized() -> void :
	var vp_size = get_viewport_rect().size
	self.scale = vp_size / Vector2(1920.0, 1080.0)

	if is_instance_valid(settings_panel): settings_panel.pivot_offset = Vector2(1920.0, 1080.0) / 2.0
	if is_instance_valid(loadout_panel): loadout_panel.pivot_offset = Vector2(1920.0, 1080.0) / 2.0

func _connect_sounds_to_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			if not child.mouse_entered.is_connected(_play_hover):
				child.mouse_entered.connect(_play_hover)
			if not child.pressed.is_connected(_play_click):
				child.pressed.connect(_play_click)

		if child.get_child_count() > 0:
			_connect_sounds_to_all_buttons(child)

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

func _paralyze_model(node: Node) -> void :
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node.has_method("set_physics_process"): node.set_physics_process(false)
	if node.has_method("set_process"): node.set_process(false)
	if node.has_method("set_process_input"): node.set_process_input(false)
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		node.stream = null
	if node is RigidBody3D:
		node.freeze = true
	for child in node.get_children():
		_paralyze_model(child)

func _connect_signals_to_hover():
	var btns = [play_button, loadout_button, settings_button, quit_button, close_settings_button]
	for b in btns:
		if b and not b.mouse_entered.is_connected(_play_ambient_hover):
			b.mouse_entered.connect(_play_ambient_hover)

func _remove_old_labels(node: Node) -> void :
	for child in node.get_children():
		if child is Label and child.text.to_upper() == "FUCK BRAINS":
			child.queue_free()
		elif child.get_child_count() > 0:
			_remove_old_labels(child)

func _get_pinned_theme() -> Dictionary:
	if FileAccess.file_exists("user://pinned_theme.json"):
		var file = FileAccess.open("user://pinned_theme.json", FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var data = JSON.parse_string(text)
			if typeof(data) == TYPE_DICTIONARY:
				if data.has("color_html"):
					data["color"] = Color(data["color_html"])
				return data
	return {}

func _save_pinned_theme(data: Dictionary) -> void :
	var save_data = data.duplicate()
	if save_data.has("color"):
		save_data["color_html"] = save_data["color"].to_html()
		save_data.erase("color")

	var file = FileAccess.open("user://pinned_theme.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))

func _clear_pinned_theme() -> void :
	var file = FileAccess.open("user://pinned_theme.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"is_pinned": false}))

func _generate_random_menu_theme():
	var pinned = _get_pinned_theme()
	if pinned.get("is_pinned", false):
		current_theme_color = pinned.get("color", Color(0.8, 0.1, 0.1))
		madness_level = pinned.get("madness", 2.0)
		active_anim_type = int(pinned.get("anim_type", 0))
		current_ascii_art_index = int(pinned.get("art_index", 0)) % ascii_arts.size()
	else:

		var color_palettes = [
			Color("#ff003c"), 
			Color("#39ff14"), 
			Color("#0ff0fc"), 
			Color("#ff00ff"), 
			Color("#ffea00"), 
			Color("#7a04eb"), 
			Color("#ff7b00"), 
			Color("#00ff41"), 
			Color("#ff007f"), 
			Color("#c0ff00"), 
			Color("#00ffff"), 
			Color("#ffb000"), 
			Color("#8a2be2"), 
			Color("#ff4500"), 
			Color("#adff2f"), 
			Color("#ff1493")
		]
		current_theme_color = color_palettes[randi() % color_palettes.size()]
		madness_level = randf_range(1.0, 10.0)

		if Global.get("active_anim_type") != null and Global.active_anim_type != -1:
			active_anim_type = Global.active_anim_type
		else:
			active_anim_type = randi() % 20

		current_ascii_art_index = randi() % ascii_arts.size()

func _setup_generative_background() -> void :
	var bg_layer: CanvasLayer = CanvasLayer.new()
	bg_layer.layer = -1
	add_child(bg_layer)

	var bg_shader: ColorRect = ColorRect.new()
	bg_shader.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_shader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_layer.add_child(bg_shader)

	var shader: Shader = Shader.new()
	var shader_logic = ""

	match active_anim_type:
		0: shader_logic = "float line_pos = (uv.x + uv.y) * 4.0 - u_movement; float stripe = step(0.85, fract(line_pos)); color_out = mix(bg_color, theme_color, stripe);"
		1: shader_logic = "float wave = sin(uv.y * 10.0 + u_movement) * 0.1; float stripe = step(0.5, fract(uv.x * 5.0 + wave)); color_out = mix(bg_color, theme_color, stripe * 0.5);"
		2: shader_logic = "float dist = distance(uv, vec2(0.5, 0.5)); float pulse = sin(dist * 20.0 - u_movement * 5.0); float ring = step(0.9, pulse); color_out = mix(bg_color, theme_color, ring * 0.3);"
		3: shader_logic = "vec2 grid_uv = floor(uv * 20.0); float grid_noise = fract(sin(grid_uv.x + grid_uv.y + floor(u_movement)) * 43758.54); float block = step(0.9 - (madness * 0.02), grid_noise); color_out = mix(bg_color, theme_color, block * 0.4);"
		4: shader_logic = "float noise_st = fract(sin(uv.x * uv.y + TIME) * 43758.54); float noise_fine = step(0.95, noise_st); color_out = mix(bg_color, theme_color, noise_fine * 0.2);"
		5: shader_logic = "vec2 p = uv - 0.5; float r = length(p); float a = atan(p.y, p.x); float tunnel = sin(10.0/(r+0.01) + u_movement * 2.0) * sin(5.0*a); tunnel = step(0.0, tunnel); color_out = mix(bg_color, theme_color, tunnel * 0.15);"
		6: shader_logic = "float x = uv.x * 10.0 + u_movement; float y = uv.y * 10.0 + u_movement; float plasma = sin(x) + sin(y) + sin(x+y) + sin(sqrt(x*x+y*y)); plasma = step(1.0, plasma); color_out = mix(bg_color, theme_color, plasma * 0.2);"
		7: shader_logic = "float d = length(fract(uv * 10.0 + u_movement) - 0.5); float dots = step(0.3, d); color_out = mix(bg_color, theme_color, (1.0 - dots) * 0.3);"
		8: shader_logic = "vec2 g = floor(uv * vec2(50.0, 10.0)); float rain = fract(sin(dot(g, vec2(12.9898, 78.233)) + u_movement) * 43758.54); color_out = mix(bg_color, theme_color, step(0.9, rain) * fract(uv.y * 10.0 - u_movement * 2.0));"
		9: shader_logic = "vec2 c = uv - 0.5; float r = length(c); float a = atan(c.y, c.x); float sweep = step(fract(a / 6.28 - u_movement), 0.1) * step(r, 0.4); color_out = mix(bg_color, theme_color, sweep * 0.4);"
		10: shader_logic = "vec2 grid = fract(uv * 8.0 + sin(u_movement)); float hex = step(0.5, max(abs(grid.x - 0.5), abs(grid.y - 0.5))); color_out = mix(bg_color, theme_color, hex * 0.2);"
		11: shader_logic = "float w1 = sin(uv.x * 30.0 + u_movement * 2.0); float w2 = sin(uv.y * 30.0 - u_movement * 2.0); float moire = step(0.8, fract(w1 + w2)); color_out = mix(bg_color, theme_color, moire * 0.2);"
		12: shader_logic = "float y_glitch = step(0.95, fract(sin(uv.y * 50.0 + floor(u_movement * 10.0)) * 43758.5)); color_out = mix(bg_color, theme_color, y_glitch * 0.3);"
		13: shader_logic = "float d1 = length(uv - vec2(0.3 + sin(u_movement)*0.2, 0.5)); float d2 = length(uv - vec2(0.7 - cos(u_movement)*0.2, 0.5)); float metaball = 0.02/d1 + 0.02/d2; color_out = mix(bg_color, theme_color, step(0.3, metaball) * 0.3);"
		14: shader_logic = "float lines = step(0.5, sin((uv.x + uv.y) * 50.0 + u_movement * 5.0)); color_out = mix(bg_color, theme_color, lines * 0.15);"
		15: shader_logic = "float cx = uv.x - 0.5; float cy = uv.y - 0.5; float angle = atan(cy, cx); float rays = step(0.5, sin(angle * 20.0 + u_movement * 3.0)); color_out = mix(bg_color, theme_color, rays * 0.15);"
		16: shader_logic = "float circle = fract(length(uv - 0.5) * 10.0 - u_movement); color_out = mix(bg_color, theme_color, step(0.8, circle) * 0.3);"
		17: shader_logic = "float noise = fract(sin(dot(uv + floor(u_movement * 10.0), vec2(12.9898,78.233))) * 43758.5453); color_out = mix(bg_color, theme_color, step(0.8, noise) * 0.3);"
		18: shader_logic = "vec2 grid = fract(uv * vec2(20.0, 2.0)); float wave = sin(uv.x * 10.0 + u_movement) * 0.5 + 0.5; float eq = step(grid.y, wave); color_out = mix(bg_color, theme_color, eq * step(0.1, grid.x) * 0.3);"
		19: shader_logic = "float r = length(uv - 0.5); float a = atan(uv.y - 0.5, uv.x - 0.5); float spiral = sin(r * 20.0 - u_movement * 5.0 + a * 5.0); color_out = mix(bg_color, theme_color, step(0.0, spiral) * 0.2);"
		_: shader_logic = "float line_pos = (uv.x + uv.y) * 4.0 - u_movement; float stripe = step(0.85, fract(line_pos)); color_out = mix(bg_color, theme_color, stripe);"


	shader.code = """
	shader_type canvas_item;
	uniform vec3 theme_color;
	uniform float madness;
	uniform float u_processed_time;
	uniform float u_movement;
	uniform float u_glitch_shift;

	float random(vec2 uv) {
		return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
	}

	void fragment() {
		vec2 raw_uv = SCREEN_UV;
		
		// Жесткий разрыв экрана (Tearing) при высоком madness
		if (fract(sin(dot(vec2(u_processed_time * 0.01, floor(raw_uv.y * 10.0)), vec2(12.9898, 78.233))) * 43758.5453) > 0.98 - (madness * 0.01)) {
			raw_uv.x += 0.08 * sin(u_processed_time * 20.0);
		}
		raw_uv.x += u_glitch_shift;
		
		// 💥 Пикселизация координат (эмуляция низкого разрешения для фона)
		vec2 uv = floor(raw_uv * vec2(320.0, 240.0)) / vec2(320.0, 240.0);
		
		// Резкий, квантованный шум (step вместо умножения)
		float grain = step(0.75, random(uv * u_processed_time)) * 0.2;
		
		// Черный фон с редкими битыми пикселями
		float bg_noise = step(0.95, fract(sin(dot(uv.xy + u_processed_time * 0.01, vec2(12.9898, 78.233))) * 43758.5453));
		vec3 bg_color = vec3(0.0) + bg_noise * theme_color * 0.3; 
		
		// Жесткие черные сканлайны (каждая вторая строка - черная)
		float scanline = step(0.5, fract(SCREEN_UV.y * 240.0)) * 0.4;
		
		vec3 color_out = vec3(0.0);
		""" + shader_logic + "\n\t\t\n\t\tcolor_out += grain;\n\t\tcolor_out -= scanline; // Накладываем жесткие полосы\n\t\t\n\t\t// 💥 Постеризация (ограничиваем цвета как на 8/16-битных консолях)\n\t\tcolor_out = floor(color_out * 5.0) / 5.0;\n\t\t\n\t\tCOLOR = vec4(color_out, 1.0);\n\t}\n\t"











	bg_shader_mat = ShaderMaterial.new()
	bg_shader_mat.shader = shader
	bg_shader_mat.set_shader_parameter("theme_color", Vector3(current_theme_color.r, current_theme_color.g, current_theme_color.b))
	bg_shader_mat.set_shader_parameter("madness", madness_level)
	bg_shader.material = bg_shader_mat

	var art_lbl = Label.new()
	art_lbl.text = ascii_arts[current_ascii_art_index]
	art_lbl.add_theme_font_size_override("font_size", 42)
	var shadow_col = current_theme_color;shadow_col.a = 0.2
	art_lbl.add_theme_color_override("font_color", shadow_col)
	art_lbl.set_anchors_preset(Control.PRESET_CENTER)
	art_lbl.position = Vector2(500, 200)
	art_lbl.rotation_degrees = randf_range(-15, 15)

	add_child(art_lbl)
	move_child(art_lbl, 0)


	var base_art_pos = art_lbl.position
	var glitch_timer = Timer.new()
	glitch_timer.autostart = true
	glitch_timer.wait_time = 0.1
	add_child(glitch_timer)

	glitch_timer.timeout.connect( func():
		glitch_timer.wait_time = randf_range(0.05, 0.3) / clamp(madness_level, 1.0, 3.0)
		if randf() > 0.6:

			art_lbl.modulate.a = [0.1, 0.4, 0.8, 1.0].pick_random()
			art_lbl.position = base_art_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			if randf() > 0.7:
				art_lbl.add_theme_color_override("font_color", [Color.WHITE, current_theme_color, Color.BLACK].pick_random())
		else:

			art_lbl.modulate.a = 0.2
			art_lbl.position = base_art_pos
			art_lbl.add_theme_color_override("font_color", shadow_col)
	)



	camcorder_hud = Control.new()
	camcorder_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	camcorder_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(camcorder_hud)

	var rec_box = HBoxContainer.new()
	rec_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	rec_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rec_box.position = Vector2(-120, 40)
	rec_box.add_theme_constant_override("separation", 10)
	rec_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camcorder_hud.add_child(rec_box)

	var rec_circle = Panel.new()
	rec_circle.custom_minimum_size = Vector2(20, 20)
	rec_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rec_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var circle_style = StyleBoxFlat.new()
	circle_style.bg_color = current_theme_color
	circle_style.corner_radius_top_left = 100
	circle_style.corner_radius_top_right = 100
	circle_style.corner_radius_bottom_left = 100
	circle_style.corner_radius_bottom_right = 100
	rec_circle.add_theme_stylebox_override("panel", circle_style)
	rec_box.add_child(rec_circle)

	var blink_tween = create_tween().set_loops()

	blink_tween.tween_property(rec_circle, "modulate:a", 0.0, 0.01)
	blink_tween.tween_interval(0.5)
	blink_tween.tween_property(rec_circle, "modulate:a", 1.0, 0.01)
	blink_tween.tween_interval(0.5)

	var rec_label = Label.new()
	rec_label.text = "ЗАПИСЬ"
	rec_label.add_theme_font_size_override("font_size", 26)
	rec_label.add_theme_color_override("font_color", current_theme_color)
	rec_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	rec_label.add_theme_constant_override("shadow_offset_x", 2)
	rec_label.add_theme_constant_override("shadow_offset_y", 2)
	rec_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rec_box.add_child(rec_label)

	var date_time_vbox = VBoxContainer.new()
	date_time_vbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	date_time_vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	date_time_vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	date_time_vbox.position = Vector2(-40, -40)
	date_time_vbox.alignment = BoxContainer.ALIGNMENT_END
	date_time_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camcorder_hud.add_child(date_time_vbox)

	var time_label = Label.new()
	time_label.text = "PM 10:48"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 24)
	time_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	time_label.add_theme_constant_override("shadow_offset_x", 2)
	time_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	date_time_vbox.add_child(time_label)

	var date_label = Label.new()
	date_label.text = "НОЯ 18\n2003"
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	date_label.add_theme_font_size_override("font_size", 24)
	date_label.add_theme_color_override("font_color", Color.WHITE)
	date_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	date_label.add_theme_constant_override("shadow_offset_x", 2)
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	date_time_vbox.add_child(date_label)


	var batt_container = HBoxContainer.new()
	batt_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	batt_container.position = Vector2(40, 40)
	batt_container.add_theme_constant_override("separation", 10)
	camcorder_hud.add_child(batt_container)

	var batt_graphic = Control.new()
	batt_graphic.custom_minimum_size = Vector2(60, 26)
	batt_container.add_child(batt_graphic)

	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color.BLACK
	border_style.border_width_left = 2
	border_style.border_width_right = 2
	border_style.border_width_top = 2
	border_style.border_width_bottom = 2
	border_style.border_color = Color.WHITE
	border_style.anti_aliasing = false

	var batt_panel = Panel.new()
	batt_panel.add_theme_stylebox_override("panel", border_style)
	batt_panel.size = Vector2(54, 26)
	batt_graphic.add_child(batt_panel)

	var batt_tip = ColorRect.new()
	batt_tip.color = Color.WHITE
	batt_tip.position = Vector2(54, 8)
	batt_tip.size = Vector2(4, 10)
	batt_graphic.add_child(batt_tip)

	var batt_fill = ColorRect.new()
	batt_fill.color = current_theme_color
	batt_fill.position = Vector2(3, 3)
	batt_fill.size = Vector2(0, 20)
	batt_graphic.add_child(batt_fill)

	var batt_text = Label.new()
	batt_text.text = "0%"
	batt_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	batt_text.add_theme_font_size_override("font_size", 24)
	batt_text.add_theme_color_override("font_color", Color.WHITE)
	batt_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	batt_container.add_child(batt_text)

	var target_charge = randi_range(7, 100)
	var max_fill_width = 48.0
	var target_width = (target_charge / 100.0) * max_fill_width

	var batt_tween = create_tween().set_parallel(true)
	batt_tween.tween_property(batt_fill, "size:x", target_width, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.5)
	batt_tween.tween_method( func(val: float): batt_text.text = str(int(val)) + "%", 0.0, float(target_charge), 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.5)


	if target_charge <= 20:
		var loop_tween = create_tween().set_loops()
		batt_fill.color = Color.RED
		border_style.border_color = Color.RED
		batt_tip.color = Color.RED
		batt_text.add_theme_color_override("font_color", Color.RED)
		loop_tween.tween_property(batt_container, "modulate:a", 0.2, 0.01)
		loop_tween.tween_interval(0.4)
		loop_tween.tween_property(batt_container, "modulate:a", 1.0, 0.01)
		loop_tween.tween_interval(0.4)



	var pin_btn = Button.new()
	camcorder_hud.add_child(pin_btn)

	pin_btn.custom_minimum_size = Vector2(250, 45)
	pin_btn.size = Vector2(250, 45)
	pin_btn.anchor_left = 0.0;pin_btn.anchor_top = 1.0
	pin_btn.anchor_right = 0.0;pin_btn.anchor_bottom = 1.0
	pin_btn.offset_left = 40;pin_btn.offset_top = -85
	pin_btn.offset_right = 290;pin_btn.offset_bottom = -40

	var pinned_data = _get_pinned_theme()
	var is_pinned = pinned_data.get("is_pinned", false)

	pin_btn.text = "[X] ТЕМА ЗАКРЕПЛЕНА" if is_pinned else "[ ] ЗАКРЕПИТЬ ТЕМУ"
	pin_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var flat_style = StyleBoxFlat.new()
	flat_style.bg_color = Color.BLACK
	flat_style.border_width_left = 4;flat_style.border_width_right = 4
	flat_style.border_width_top = 4;flat_style.border_width_bottom = 4
	flat_style.border_color = current_theme_color
	flat_style.anti_aliasing = false

	var hover_style = flat_style.duplicate()
	hover_style.bg_color = current_theme_color

	pin_btn.add_theme_stylebox_override("normal", flat_style)
	pin_btn.add_theme_stylebox_override("hover", hover_style)
	pin_btn.add_theme_stylebox_override("pressed", hover_style)
	pin_btn.add_theme_stylebox_override("focus", flat_style)

	var txt_col = Color.WHITE if is_pinned else current_theme_color
	pin_btn.add_theme_color_override("font_color", txt_col)
	pin_btn.add_theme_color_override("font_hover_color", Color.BLACK)
	pin_btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	pin_btn.add_theme_font_size_override("font_size", 20)
	pin_btn.add_theme_color_override("font_shadow_color", Color.BLACK)
	pin_btn.add_theme_constant_override("shadow_offset_x", 2)
	pin_btn.add_theme_constant_override("shadow_offset_y", 2)

	pin_btn.pressed.connect( func():
		_play_click()
		var current_pinned_data = _get_pinned_theme()
		var currently_pinned = current_pinned_data.get("is_pinned", false)
		currently_pinned = !currently_pinned

		if currently_pinned:
			_save_pinned_theme({"is_pinned": true, "color": current_theme_color, "madness": madness_level, "anim_type": active_anim_type, "art_index": current_ascii_art_index})
			pin_btn.text = "[X] ТЕМА ЗАКРЕПЛЕНА"
			pin_btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			_clear_pinned_theme()
			pin_btn.text = "[ ] ЗАКРЕПИТЬ ТЕМУ"
			pin_btn.add_theme_color_override("font_color", current_theme_color)
	)

func _hash_gd(n: float) -> float:
	var res = sin(n) * 43758.5453123
	return res - floor(res)

func _stylize_main_menu_buttons() -> void :
	var btn_refs = [
		{"btn": play_button, "icon": ">", "text": "ИГРАТЬ"}, 
		{"btn": loadout_button, "icon": ">", "text": "СНАРЯЖЕНИЕ"}, 
		{"btn": settings_button, "icon": ">", "text": "НАСТРОЙКИ"}, 
		{"btn": quit_button, "icon": ">", "text": "ВЫХОД"}
	]

	for data in btn_refs:
		if data["btn"] and data["btn"].get_parent():
			data["btn"].get_parent().remove_child(data["btn"])

	if menu_buttons:
		menu_buttons.visible = false
		menu_buttons.process_mode = Node.PROCESS_MODE_DISABLED

	stylized_ui_panel = Control.new()
	add_child(stylized_ui_panel)
	stylized_ui_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stylized_ui_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var menu_rotation = randf_range(-6.0, 6.0)


	var menu_wrapper = Control.new()
	menu_wrapper.set_anchors_preset(Control.PRESET_CENTER_RIGHT)

	menu_wrapper.offset_left = -550
	menu_wrapper.offset_top = -200
	menu_wrapper.offset_right = -100
	menu_wrapper.offset_bottom = 200
	menu_wrapper.rotation_degrees = menu_rotation
	stylized_ui_panel.add_child(menu_wrapper)

	var title_lbl = Label.new()
	title_lbl.text = "ВЫШИБИ МОЗГИ"
	title_lbl.add_theme_font_size_override("font_size", 72)
	title_lbl.add_theme_color_override("font_color", current_theme_color)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_lbl.offset_top = -100
	menu_wrapper.add_child(title_lbl)
	_apply_crt_twitch_to_label(title_lbl)

	var y_step = 75
	for i in range(btn_refs.size()):
		var data = btn_refs[i]
		var btn = data["btn"]
		if not btn: continue

		menu_wrapper.add_child(btn)


		btn.anchor_left = 0.0;btn.anchor_right = 1.0
		btn.anchor_top = 0.0;btn.anchor_bottom = 0.0
		btn.offset_left = 0
		btn.offset_right = 0
		btn.offset_top = i * y_step
		btn.offset_bottom = (i * y_step) + 65

		btn.set_meta("base_x", btn.position.x)

		_style_main_menu_single_button(btn, data["icon"], data["text"])



func _apply_crt_twitch_to_label(lbl: Label) -> void :
	if lbl.has_meta("twit") and is_instance_valid(lbl.get_meta("twit")): return

	var original_pos = lbl.position
	var base_x = lbl.position.x



	var twitch_timer = Timer.new()
	add_child(twitch_timer)
	twitch_timer.wait_time = randf_range(0.02, 0.08)
	twitch_timer.start()

	lbl.set_meta("twit", twitch_timer)

	twitch_timer.timeout.connect( func():
		lbl.modulate.a = randf_range(0.6, 1.0)


		var chance = randf()
		if chance < 0.05:
			lbl.position.x = base_x + randf_range(-25.0, 25.0)
			lbl.modulate = Color("#ff0000")
		elif chance < 0.1:
			lbl.position.x = base_x + randf_range(-15.0, 15.0)
			lbl.modulate = Color("#ffff00")
		elif chance < 0.15:
			lbl.modulate = Color("#00ffff")
		else:
			lbl.position.x = base_x + randf_range(-4.0, 4.0)
			lbl.modulate = Color.WHITE





		lbl.position.y = original_pos.y + randf_range(-2.0, 2.0)
	)

func _style_main_menu_single_button(btn: Button, icon_text: String, main_text: String) -> void :
	btn.text = ""
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var hover_bg = ColorRect.new()
	hover_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hover_bg.color = current_theme_color
	hover_bg.visible = false
	hover_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hover_bg)
	btn.move_child(hover_bg, 0)

	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 15)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = icon_text
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 36)
	icon_lbl.add_theme_color_override("font_color", current_theme_color.lerp(Color.GRAY, 0.5))
	icon_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	icon_lbl.add_theme_constant_override("shadow_offset_x", 3)
	icon_lbl.add_theme_constant_override("shadow_offset_y", 3)
	hbox.add_child(icon_lbl)

	var text_lbl = Label.new()
	text_lbl.text = main_text
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.add_theme_font_size_override("font_size", 42)
	text_lbl.add_theme_color_override("font_color", Color.WHITE)
	text_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	text_lbl.add_theme_constant_override("shadow_offset_x", 3)
	text_lbl.add_theme_constant_override("shadow_offset_y", 3)
	hbox.add_child(text_lbl)


	var twitch_timer = Timer.new()
	twitch_timer.wait_time = 0.05
	btn.add_child(twitch_timer)

	var on_focus = func():
		_play_click()
		hover_bg.visible = true
		icon_lbl.add_theme_color_override("font_color", Color.BLACK)
		icon_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		text_lbl.add_theme_color_override("font_color", Color.BLACK)
		text_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		icon_lbl.text = ">"

		if not btn.has_meta("base_x"):
			btn.set_meta("base_x", btn.position.x)

		twitch_timer.start()
		if not twitch_timer.timeout.is_connected(btn.get_meta("twitch_func")):
			twitch_timer.timeout.connect(btn.get_meta("twitch_func"))

	var on_unfocus = func():
		hover_bg.visible = false
		icon_lbl.add_theme_color_override("font_color", current_theme_color.lerp(Color.GRAY, 0.5))
		icon_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		text_lbl.add_theme_color_override("font_color", Color.WHITE)
		text_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		icon_lbl.text = icon_text

		twitch_timer.stop()
		if btn.has_meta("base_x"):
			btn.position.x = btn.get_meta("base_x")


	var twitch_func = func():
		if hover_bg.visible:
			var base_x = btn.get_meta("base_x")

			if randf() > 0.7:
				btn.position.x = base_x + randf_range(15.0, 35.0)
			else:
				btn.position.x = base_x + randf_range(5.0, 15.0)

	btn.set_meta("twitch_func", twitch_func)


	btn.mouse_entered.connect( func(): btn.grab_focus())

	btn.focus_entered.connect(on_focus)
	btn.focus_exited.connect(on_unfocus)

func _apply_bad_trip_hover_to_button(btn: Button, _icon_text: String = "", _main_text: String = "", font_sz: int = 28) -> void :
	if btn.has_meta("bad_trip"): return
	btn.set_meta("bad_trip", true)

	var initial_clean = btn.text if btn.text != "" else _main_text
	initial_clean = initial_clean.trim_prefix("> ").trim_prefix("■ ").trim_prefix(">").strip_edges()
	btn.text = initial_clean

	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", font_sz)


	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.BLACK)
	btn.add_theme_color_override("font_pressed_color", Color.BLACK)
	btn.add_theme_color_override("font_focus_color", Color.BLACK)

	btn.add_theme_color_override("font_shadow_color", Color.BLACK)
	btn.add_theme_constant_override("shadow_offset_x", 2)
	btn.add_theme_constant_override("shadow_offset_y", 2)

	var empty_style = StyleBoxEmpty.new()

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = current_theme_color
	hover_style.anti_aliasing = false

	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_stylebox_override("focus", hover_style)

	var target_node = btn
	if btn.get_parent() and btn.get_parent().name.begins_with("BtnWrapper"):
		target_node = btn.get_parent()
		target_node.clip_contents = false

	var twitch_timer = Timer.new()
	twitch_timer.wait_time = 0.05
	btn.add_child(twitch_timer)

	var on_focus = func():
		_play_click()
		btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))

		var current_clean = btn.text.trim_prefix("> ").trim_prefix("■ ").trim_prefix(">").strip_edges()
		if btn.has_meta("clean_text"): current_clean = btn.get_meta("clean_text")
		btn.text = "> " + current_clean

		if not target_node.has_meta("base_x"):
			target_node.set_meta("base_x", target_node.position.x)

		twitch_timer.start()
		if not twitch_timer.timeout.is_connected(btn.get_meta("twitch_func")):
			twitch_timer.timeout.connect(btn.get_meta("twitch_func"))

	var on_unfocus = func():
		btn.add_theme_color_override("font_shadow_color", Color.BLACK)

		var clean = btn.text.trim_prefix("> ").trim_prefix("■ ").trim_prefix(">").strip_edges()
		if btn.has_meta("clean_text"): clean = btn.get_meta("clean_text")
		btn.text = clean

		twitch_timer.stop()
		if target_node.has_meta("base_x"):
			target_node.position.x = target_node.get_meta("base_x")


	var twitch_func = func():
		if btn.has_focus() or btn.is_hovered():
			var base_x = target_node.get_meta("base_x")
			target_node.position.x = base_x + randf_range(2.0, 8.0)

	btn.set_meta("twitch_func", twitch_func)


	btn.mouse_entered.connect( func(): btn.grab_focus())

	btn.focus_entered.connect(on_focus)
	btn.focus_exited.connect(on_unfocus)

func _stylize_settings_window() -> void :
	settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	settings_panel.add_child(bg)
	settings_panel.move_child(bg, 0)


	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	settings_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)


	var title_node = settings_panel.find_child("Title*", true, false) as Label
	if not title_node:
		title_node = Label.new()
		title_node.name = "TitleLabel"
		settings_panel.add_child(title_node)

	var t_parent = title_node.get_parent()
	if t_parent and t_parent != vbox: t_parent.remove_child(title_node)
	vbox.add_child(title_node)

	title_node.top_level = false
	title_node.text = " /// СИСТЕМНЫЕ НАСТРОЙКИ "
	title_node.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	title_node.add_theme_font_size_override("font_size", 48)
	title_node.add_theme_color_override("font_color", Color.BLACK)
	var title_bg = StyleBoxFlat.new()
	title_bg.bg_color = current_theme_color
	title_bg.anti_aliasing = false
	title_bg.shadow_color = Color.BLACK
	title_bg.shadow_offset = Vector2(8, 8)
	title_node.add_theme_stylebox_override("normal", title_bg)

	if not title_node.has_meta("styled"):
		_apply_crt_twitch_to_label(title_node)
		title_node.set_meta("styled", true)


	var tabs = _find_node_by_class(settings_panel, "TabContainer") as TabContainer
	if tabs:
		var tabs_parent = tabs.get_parent()
		if tabs_parent and tabs_parent != vbox: tabs_parent.remove_child(tabs)
		vbox.add_child(tabs)

		tabs.top_level = false
		tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL

		if not tabs.has_meta("styled_tabs"):
			for i in range(tabs.get_tab_count()):
				var old_title = tabs.get_tab_title(i)
				var clean_title = old_title.trim_prefix("/ ").trim_prefix("/").trim_prefix("[").trim_suffix("]").strip_edges()
				tabs.set_tab_title(i, "[ " + clean_title.to_upper() + " ]")
			tabs.set_meta("styled_tabs", true)

			tabs.tab_changed.connect( func(_tab_idx):
				_play_click()
				if tabs.has_meta("anim_tween"):
					var tw = tabs.get_meta("anim_tween")
					if is_instance_valid(tw): tw.kill()

				var anim_tween = create_tween()
				tabs.set_meta("anim_tween", anim_tween)

				tabs.modulate.a = 0.0
				anim_tween.tween_interval(0.03)
				anim_tween.tween_property(tabs, "modulate:a", 0.5, 0.01)
				anim_tween.tween_interval(0.02)
				anim_tween.tween_property(tabs, "modulate:a", 0.1, 0.01)
				anim_tween.tween_interval(0.02)
				anim_tween.tween_property(tabs, "modulate:a", 1.0, 0.01)
			)


	var close_btn = settings_panel.find_child("CloseButton*", true, false) as Button
	if close_btn:
		var btn_parent = close_btn.get_parent()
		if btn_parent and btn_parent != vbox: btn_parent.remove_child(close_btn)

		var footer = HBoxContainer.new()
		footer.alignment = BoxContainer.ALIGNMENT_END
		vbox.add_child(footer)
		footer.add_child(close_btn)

		close_btn.top_level = false
		close_btn.text = "ВЕРНУТЬСЯ"
		close_btn.custom_minimum_size = Vector2(350, 70)

		_apply_bad_trip_hover_to_button(close_btn, "", "ВЕРНУТЬСЯ", 36)

func _find_node_by_class(parent: Node, target_class: String) -> Node:
	for child in parent.get_children():
		if child.is_class(target_class): return child
		var found = _find_node_by_class(child, target_class)
		if found: return found
	return null

func _apply_manhunt_theme_recursive(node: Node) -> void :
	if node == menu_buttons or node == stylized_ui_panel: return

	if (node is Panel or node is PanelContainer) and not node.has_theme_stylebox_override("panel") and not node is ScrollContainer:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
		style.border_width_left = 4;style.border_width_top = 4
		style.border_width_right = 4;style.border_width_bottom = 4
		style.border_color = current_theme_color
		style.anti_aliasing = false

		style.shadow_color = Color.BLACK
		style.shadow_size = 0
		style.shadow_offset = Vector2(8, 8)
		style.content_margin_left = 30;style.content_margin_right = 30
		style.content_margin_top = 30;style.content_margin_bottom = 30
		node.add_theme_stylebox_override("panel", style)

	if node is TabContainer:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
		panel_style.border_width_left = 6;panel_style.border_width_right = 6
		panel_style.border_width_bottom = 6;panel_style.border_width_top = 6
		panel_style.border_color = current_theme_color
		panel_style.anti_aliasing = false
		node.add_theme_stylebox_override("panel", panel_style)

		var tab_sel = StyleBoxFlat.new()
		tab_sel.bg_color = current_theme_color
		tab_sel.border_width_left = 4;tab_sel.border_width_right = 4;tab_sel.border_width_top = 4
		tab_sel.border_color = current_theme_color
		tab_sel.anti_aliasing = false
		tab_sel.content_margin_left = 30;tab_sel.content_margin_right = 30
		tab_sel.content_margin_top = 15;tab_sel.content_margin_bottom = 15
		node.add_theme_stylebox_override("tab_selected", tab_sel)

		var tab_unsel = StyleBoxFlat.new()
		tab_unsel.bg_color = Color.BLACK
		tab_unsel.border_width_left = 4;tab_unsel.border_width_right = 4;tab_unsel.border_width_top = 4
		tab_unsel.border_color = current_theme_color.lerp(Color.BLACK, 0.6)
		tab_unsel.anti_aliasing = false
		tab_unsel.content_margin_left = 25;tab_unsel.content_margin_right = 25
		tab_unsel.content_margin_top = 15;tab_unsel.content_margin_bottom = 10
		node.add_theme_stylebox_override("tab_unselected", tab_unsel)


		var tab_hover = StyleBoxFlat.new()
		tab_hover.bg_color = Color(0.05, 0.05, 0.05, 1.0)
		tab_hover.border_width_left = 4;tab_hover.border_width_right = 4;tab_hover.border_width_top = 4
		tab_hover.border_color = current_theme_color
		tab_hover.anti_aliasing = false
		tab_hover.content_margin_left = 25;tab_hover.content_margin_right = 25
		tab_hover.content_margin_top = 15;tab_hover.content_margin_bottom = 10
		node.add_theme_stylebox_override("tab_hovered", tab_hover)

		node.add_theme_color_override("font_selected_color", Color.BLACK)
		node.add_theme_color_override("font_unselected_color", current_theme_color.lerp(Color.WHITE, 0.5))

		node.add_theme_color_override("font_hovered_color", Color.WHITE)
		node.add_theme_font_size_override("font_size", 28)

	if node is Label and not node.name == "TitleLabel":
		node.add_theme_font_size_override("font_size", 24)
		node.add_theme_color_override("font_shadow_color", Color.BLACK)
		node.add_theme_constant_override("shadow_offset_x", 3)
		node.add_theme_constant_override("shadow_offset_y", 3)

		var txt = node.text.to_upper()
		node.add_theme_color_override("font_color", Color.WHITE)

		var clean_txt = txt.trim_prefix("> ").trim_prefix("■ ").trim_prefix(">").strip_edges()
		if node.get_parent() != stylized_ui_panel and not clean_txt.begins_with("[") and not clean_txt.is_valid_float() and not "%" in clean_txt:
			if node.name.contains("Label") and not node.name.contains("Value"):
				if not node.has_meta("styled"):
					node.text = "■ " + clean_txt
					node.set_meta("styled", true)

	if node is Button and node.get_parent() != stylized_ui_panel and not node is OptionButton and not node is ColorPickerButton and not node is CheckButton:
		if not node.has_meta("bad_trip") and not node.has_meta("no_bad_trip") and node.text != "":
			var original_text = node.text
			_apply_bad_trip_hover_to_button(node, "", original_text, 24)

	if node is HSlider or node is VSlider:
		var slider_bg = StyleBoxFlat.new()
		slider_bg.bg_color = Color.BLACK
		slider_bg.border_width_left = 2;slider_bg.border_width_right = 2
		slider_bg.border_width_top = 2;slider_bg.border_width_bottom = 2
		slider_bg.border_color = current_theme_color.lerp(Color.BLACK, 0.3)
		slider_bg.expand_margin_top = 8;slider_bg.expand_margin_bottom = 8
		slider_bg.anti_aliasing = false
		node.add_theme_stylebox_override("slider", slider_bg)

		var slider_fill = StyleBoxFlat.new()
		slider_fill.bg_color = current_theme_color
		slider_fill.expand_margin_top = 8;slider_fill.expand_margin_bottom = 8
		slider_fill.anti_aliasing = false
		node.add_theme_stylebox_override("grabber_area", slider_fill)
		node.add_theme_stylebox_override("grabber_area_highlight", slider_fill)

		var img: Image = Image.create_empty(16, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		node.add_theme_icon_override("grabber", tex)
		node.add_theme_icon_override("grabber_highlight", tex)

	if node is OptionButton:
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color.BLACK
		btn_style.border_width_left = 4;btn_style.border_width_right = 4
		btn_style.border_width_top = 4;btn_style.border_width_bottom = 4
		btn_style.border_color = current_theme_color

		btn_style.shadow_color = Color.BLACK
		btn_style.shadow_size = 0
		btn_style.shadow_offset = Vector2(4, 4)
		btn_style.content_margin_left = 15;btn_style.content_margin_right = 15
		btn_style.content_margin_top = 8;btn_style.content_margin_bottom = 8
		btn_style.anti_aliasing = false
		node.add_theme_stylebox_override("normal", btn_style)

		var hover_style = btn_style.duplicate()
		hover_style.bg_color = current_theme_color
		node.add_theme_stylebox_override("hover", hover_style)
		node.add_theme_stylebox_override("pressed", hover_style)

		node.add_theme_color_override("font_color", current_theme_color)
		node.add_theme_color_override("font_hover_color", Color.BLACK)
		node.add_theme_color_override("font_pressed_color", Color.BLACK)
		node.add_theme_color_override("font_focus_color", Color.BLACK)
		node.add_theme_font_size_override("font_size", 22)
		node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))

	if node is CheckButton:
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_color_override("font_hover_color", current_theme_color)
		node.add_theme_color_override("font_pressed_color", current_theme_color)
		node.add_theme_color_override("font_shadow_color", Color.BLACK)

		var img_off = Image.create_empty(28, 28, false, Image.FORMAT_RGBA8)
		img_off.fill(Color(0.15, 0.15, 0.15, 1.0))
		var tex_off = ImageTexture.create_from_image(img_off)
		var img_on = Image.create_empty(28, 28, false, Image.FORMAT_RGBA8)
		img_on.fill(current_theme_color)
		var tex_on = ImageTexture.create_from_image(img_on)

		node.add_theme_icon_override("checked", tex_on)
		node.add_theme_icon_override("unchecked", tex_off)

	if node is Button and node.has_meta("no_bad_trip"):
		var flat_style = StyleBoxFlat.new()
		flat_style.bg_color = Color.BLACK
		flat_style.border_width_left = 4;flat_style.border_width_right = 4
		flat_style.border_width_top = 4;flat_style.border_width_bottom = 4
		flat_style.border_color = current_theme_color
		flat_style.anti_aliasing = false
		node.add_theme_stylebox_override("normal", flat_style)
		var hover_style = flat_style.duplicate()
		hover_style.bg_color = current_theme_color
		node.add_theme_stylebox_override("hover", hover_style)
		node.add_theme_stylebox_override("pressed", hover_style)
		node.add_theme_stylebox_override("focus", hover_style)

		node.add_theme_color_override("font_color", current_theme_color)
		node.add_theme_color_override("font_hover_color", Color.BLACK)
		node.add_theme_color_override("font_pressed_color", Color.BLACK)
		node.add_theme_color_override("font_focus_color", Color.BLACK)
		node.add_theme_font_size_override("font_size", 22)
		node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))

	for child: Node in node.get_children():
		_apply_manhunt_theme_recursive(child)





func _process(delta: float) -> void :
	vhs_time += delta

	if bg_shader_mat:

		var time_step = floor(vhs_time * 12.0) / 12.0


		if randf() > 0.98: time_step -= randf_range(0.1, 0.3)

		var p_time = time_step

		var move = p_time * 0.8 + floor(sin(p_time * 2.0) * 5.0) / 5.0

		bg_shader_mat.set_shader_parameter("u_processed_time", p_time)
		bg_shader_mat.set_shader_parameter("u_movement", move)

		var row_id = floor(get_viewport().get_visible_rect().size.y * 0.5 * (10.0 + madness_level * 2.0))
		var glitch_trigger = _hash_gd(row_id + p_time * (2.0 + madness_level * 0.5))
		var glitch_shift = 0.0

		if glitch_trigger > (1.0 - madness_level * 0.02):
			glitch_shift = (randf() - 0.5) * (0.3 * madness_level)
		bg_shader_mat.set_shader_parameter("u_glitch_shift", glitch_shift)


	for label in dynamic_titles:
		if is_instance_valid(label) and label.visible:
			if randf() < (0.04 * madness_level):

				label.modulate.a = [0.0, 0.4, 1.0].pick_random()

				if label.has_meta("base_x"):
					label.position.x = label.get_meta("base_x") + randf_range(-10, 10)

				await get_tree().create_timer(randf_range(0.02, 0.08)).timeout
				if is_instance_valid(label):
					label.modulate.a = 1.0
					if label.has_meta("base_x"):
						label.position.x = label.get_meta("base_x")

	if loadout_panel.visible:
		for spinner: Node3D in weapon_spinners:
			if is_instance_valid(spinner):

				var stepped_time = floor(vhs_time * 6.0) / 6.0
				spinner.rotation.y = stepped_time * 3.0

	if is_instance_valid(current_unlock_spinner):
		current_unlock_spinner.rotate_y(delta * 2.5)

func _perform_glitch_show(panel: Control) -> void :
	if camcorder_hud: camcorder_hud.visible = false
	if stylized_ui_panel: stylized_ui_panel.visible = false

	panel.scale = Vector2.ONE
	panel.modulate.a = 0.0
	panel.visible = true


	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.3, 0.05)
	tween.tween_property(panel, "modulate:a", 0.8, 0.05)
	tween.tween_property(panel, "modulate:a", 0.1, 0.05)
	tween.tween_property(panel, "modulate:a", 1.0, 0.05)

func _on_loadout_button_pressed() -> void :
	_perform_glitch_show(loadout_panel)
	var return_btns = loadout_panel.find_children("*", "Button", true, false)
	if return_btns.size() > 0:
		return_btns[0].grab_focus()

func _on_play_button_pressed() -> void :
	if Global.has_method("fade_out_music"):
		Global.fade_out_music()

	if Global.has_method("reset_run"):
		Global.reset_run()

	if has_node("/root/LoadingScreen"):
		LoadingScreen.change_scene("res://Scenes/level_generator.tscn", "> SYS.LOADING...")
	else:
		get_tree().change_scene_to_file("res://Scenes/level_generator.tscn")

func _on_settings_button_pressed() -> void :
	update_ui_from_global()
	setup_graphics_settings()
	_perform_glitch_show(settings_panel)
	if close_settings_button:
		close_settings_button.grab_focus()

func _on_quit_button_pressed() -> void :
	get_tree().quit()

func _on_close_panels() -> void :
	if Global.has_method("save_settings"):
		Global.save_settings()


	var close_tween = create_tween().set_parallel(true)
	close_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.1)
	close_tween.tween_property(loadout_panel, "modulate:a", 0.0, 0.1)

	await close_tween.finished
	settings_panel.visible = false
	loadout_panel.visible = false

	if camcorder_hud: camcorder_hud.visible = true
	if stylized_ui_panel: stylized_ui_panel.visible = true

	if play_button:
		play_button.grab_focus()

func _build_advanced_loadout_ui() -> void :
	loadout_tabs.clear()
	weapon_spinners.clear()
	wpn_btns.clear()
	prk_btns.clear()
	skl_btns.clear()
	skl_lbls.clear()

	var items_to_remove = []
	for lbl in dynamic_titles:
		if lbl.text.begins_with("/"): items_to_remove.append(lbl)
	for lbl in items_to_remove:
		dynamic_titles.erase(lbl)

	for child: Node in loadout_panel.get_children(): child.queue_free()

	loadout_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	loadout_panel.add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	loadout_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)


	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	var title_node = Label.new()
	title_node.text = " /// БАЗА СНАРЯЖЕНИЯ "
	title_node.add_theme_font_size_override("font_size", 48)
	title_node.add_theme_color_override("font_color", Color.BLACK)
	var title_bg = StyleBoxFlat.new()
	title_bg.bg_color = current_theme_color
	title_bg.anti_aliasing = false
	title_bg.shadow_color = Color.BLACK
	title_bg.shadow_offset = Vector2(8, 8)
	title_node.add_theme_stylebox_override("normal", title_bg)
	header_hbox.add_child(title_node)
	_apply_crt_twitch_to_label(title_node)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	money_header_label = Label.new()
	money_header_label.add_theme_color_override("font_color", current_theme_color)
	money_header_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	money_header_label.add_theme_constant_override("shadow_offset_x", 3)
	money_header_label.add_theme_constant_override("shadow_offset_y", 3)
	money_header_label.add_theme_font_size_override("font_size", 36)
	header_hbox.add_child(money_header_label)

	var tabs_hbox = HBoxContainer.new()
	tabs_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(tabs_hbox)

	var tab_names: Array[String] = ["/ ОРУЖИЕ /", "/ МОДУЛИ /", "/ УЛУЧШЕНИЯ /"]
	for i: int in range(tab_names.size()):
		var t_btn: Button = Button.new()
		t_btn.text = tab_names[i]
		t_btn.custom_minimum_size = Vector2(250, 60)
		tabs_hbox.add_child(t_btn)
		_apply_bad_trip_hover_to_button(t_btn, "", tab_names[i], 28)
		t_btn.pressed.connect( func() -> void : _switch_loadout_tab(i))

	var content_panel = MarginContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_panel)

	var scroll_w: ScrollContainer = ScrollContainer.new()
	scroll_w.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid_w: GridContainer = GridContainer.new()
	grid_w.columns = 2
	grid_w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_w.add_theme_constant_override("h_separation", 40)
	grid_w.add_theme_constant_override("v_separation", 40)
	scroll_w.add_child(grid_w)
	content_panel.add_child(scroll_w)
	loadout_tabs.append(scroll_w)
	_build_weapons_tab(grid_w)

	var scroll_p: ScrollContainer = ScrollContainer.new()
	scroll_p.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid_p: GridContainer = GridContainer.new()
	grid_p.columns = 3
	grid_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_p.add_theme_constant_override("h_separation", 40)
	grid_p.add_theme_constant_override("v_separation", 40)
	scroll_p.add_child(grid_p)
	content_panel.add_child(scroll_p)
	loadout_tabs.append(scroll_p)
	_build_perks_tab(grid_p)

	var scroll_s: ScrollContainer = ScrollContainer.new()
	scroll_s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid_s: GridContainer = GridContainer.new()
	grid_s.columns = 3
	grid_s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_s.add_theme_constant_override("h_separation", 40)
	grid_s.add_theme_constant_override("v_separation", 40)
	scroll_s.add_child(grid_s)
	content_panel.add_child(scroll_s)
	loadout_tabs.append(scroll_s)
	_build_skills_tab(grid_s)


	var footer_hbox = HBoxContainer.new()
	footer_hbox.alignment = BoxContainer.ALIGNMENT_END
	main_vbox.add_child(footer_hbox)

	var btn_back = Button.new()
	btn_back.text = "ВЕРНУТЬСЯ"
	btn_back.custom_minimum_size = Vector2(350, 70)
	footer_hbox.add_child(btn_back)
	_apply_bad_trip_hover_to_button(btn_back, "", "ВЕРНУТЬСЯ", 36)
	btn_back.pressed.connect(_on_close_panels)

	_update_loadout_state()
	_switch_loadout_tab(current_loadout_tab)

func _update_loadout_state() -> void :
	update_money_label()


	for w_id in weapons_db.keys():
		if wpn_btns.has(w_id):
			var txt = "В РУКАХ" if Global.selected_weapon == w_id else "ВЗЯТЬ"
			wpn_btns[w_id].text = txt
			if wpn_btns[w_id].has_meta("clean_text"):
				wpn_btns[w_id].set_meta("clean_text", txt)

	for p_id in perks_db.keys():
		if prk_btns.has(p_id):
			var txt = "АКТИВЕН" if Global.selected_starting_perk == p_id else "УСТАНОВИТЬ"
			prk_btns[p_id].text = txt
			if prk_btns[p_id].has_meta("clean_text"):
				prk_btns[p_id].set_meta("clean_text", txt)

	for s_id in skills_db.keys():
		var data = skills_db[s_id]
		var current_lvl = Global.meta_upgrades.get(s_id, 0) as int
		var cost = data["base_cost"] + (current_lvl * data["base_cost"])

		if skl_lbls.has(s_id):
			var bars = ""
			for j in range(max_skill_level):
				bars += "■" if j < current_lvl else "."
			skl_lbls[s_id].text = "УРОВЕНЬ: [" + bars + "]"

		if skl_btns.has(s_id):
			var btn = skl_btns[s_id]
			if current_lvl >= max_skill_level:
				btn.text = "МАКСИМУМ"
				btn.disabled = true
				if btn.has_meta("clean_text"): btn.set_meta("clean_text", "МАКСИМУМ")
			else:
				var txt = "УЛУЧШИТЬ: " + str(cost)
				btn.text = txt
				btn.disabled = (Global.meta_crystals < cost)
				if btn.has_meta("clean_text"): btn.set_meta("clean_text", txt)

func _switch_loadout_tab(index: int) -> void :
	current_loadout_tab = index
	_play_click()


	var anim_tween = create_tween()
	loadout_panel.modulate.a = 0.1
	anim_tween.tween_property(loadout_panel, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE)

	for i: int in range(loadout_tabs.size()):
		if is_instance_valid(loadout_tabs[i]):
			loadout_tabs[i].visible = (i == index)

func update_money_label() -> void :
	if money_header_label and is_instance_valid(money_header_label):
		money_header_label.text = "РуБлИкИ: " + str(Global.meta_crystals)

func _apply_pulsing_border(card: PanelContainer) -> void :
	card.mouse_entered.connect( func():
		_play_ambient_hover()
		var style = card.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = Color.WHITE
			style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	)
	card.mouse_exited.connect( func():
		var style = card.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = current_theme_color
			style.bg_color = Color.BLACK
	)

func _build_weapons_tab(parent_grid: GridContainer) -> void :
	for w_id: String in weapons_db.keys():
		var data: Dictionary = weapons_db[w_id] as Dictionary
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL


		var unique_style = StyleBoxFlat.new()
		unique_style.bg_color = Color(0.0, 0.0, 0.0, 0.95)
		unique_style.border_width_left = 4;unique_style.border_width_right = 4
		unique_style.border_width_top = 4;unique_style.border_width_bottom = 4
		unique_style.border_color = current_theme_color
		unique_style.anti_aliasing = false

		unique_style.shadow_color = Color.BLACK
		unique_style.shadow_size = 0
		unique_style.shadow_offset = Vector2(8, 8)

		unique_style.content_margin_left = 20;unique_style.content_margin_right = 20
		unique_style.content_margin_top = 20;unique_style.content_margin_bottom = 20
		card.add_theme_stylebox_override("panel", unique_style)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card.add_child(card_vbox)
		var top_hbox: HBoxContainer = HBoxContainer.new()
		top_hbox.add_theme_constant_override("separation", 25)
		card_vbox.add_child(top_hbox)

		var image_panel = PanelContainer.new()
		image_panel.custom_minimum_size = Vector2(200, 150)
		image_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		top_hbox.add_child(image_panel)

		var vp_container: SubViewportContainer = SubViewportContainer.new()
		vp_container.stretch = true
		vp_container.custom_minimum_size = Vector2(200, 150)
		image_panel.add_child(vp_container)

		var viewport: SubViewport = SubViewport.new()
		viewport.transparent_bg = true
		viewport.own_world_3d = true
		viewport.size = Vector2(200, 150)
		vp_container.add_child(viewport)

		var cam_filter = Panel.new()
		cam_filter.set_anchors_preset(Control.PRESET_FULL_RECT)
		cam_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var p_style = StyleBoxFlat.new()
		var f_col = current_theme_color;f_col.a = 0.15
		p_style.bg_color = f_col
		cam_filter.add_theme_stylebox_override("panel", p_style)
		image_panel.add_child(cam_filter)

		var cam_lbl = Label.new()
		cam_lbl.text = "■ КАМ_0" + str(w_id.hash() % 9 + 1) + " // ЗАПИСЬ"
		cam_lbl.add_theme_font_size_override("font_size", 14)
		cam_lbl.add_theme_color_override("font_color", current_theme_color)
		cam_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		cam_lbl.add_theme_constant_override("shadow_offset_x", 2)
		cam_lbl.add_theme_constant_override("shadow_offset_y", 2)
		cam_lbl.position = Vector2(5, 5)
		cam_filter.add_child(cam_lbl)

		var rec_tween = create_tween().set_loops()
		rec_tween.tween_property(cam_lbl, "modulate:a", 0.0, 0.01)
		rec_tween.tween_interval(0.5)
		rec_tween.tween_property(cam_lbl, "modulate:a", 1.0, 0.01)
		rec_tween.tween_interval(0.5)

		var cam: Camera3D = Camera3D.new()
		cam.look_at_from_position(Vector3(0, 0.2, 1.5), Vector3.ZERO)
		var env: Environment = Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.8, 0.8, 0.8)
		env.ambient_light_energy = 1.0
		cam.environment = env
		viewport.add_child(cam)
		var light: DirectionalLight3D = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-30, 45, 0)
		viewport.add_child(light)

		var has_model: bool = false
		if data.has("scene") and data["scene"] != null:
			var scene_res: Variant = data["scene"]
			if typeof(scene_res) == TYPE_STRING:
				scene_res = load(scene_res as String)
				data["scene"] = scene_res
			if scene_res is PackedScene:
				var spinner: Node3D = Node3D.new()
				viewport.add_child(spinner)
				var model: Node3D = (scene_res as PackedScene).instantiate() as Node3D
				_paralyze_model(model)
				spinner.add_child(model)
				weapon_spinners.append(spinner)
				has_model = true

		if not has_model:
			var center_box = CenterContainer.new()
			center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
			var error_lbl: Label = Label.new()
			error_lbl.text = "НЕТ СИГНАЛА"
			error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			error_lbl.add_theme_color_override("font_color", current_theme_color)
			error_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
			center_box.add_child(error_lbl)
			image_panel.add_child(center_box)

		var stats_vbox: VBoxContainer = VBoxContainer.new()
		stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		top_hbox.add_child(stats_vbox)

		var title: Label = Label.new()
		title.text = "■ " + (data["name"] as String).to_upper()
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_color_override("font_shadow_color", Color.BLACK)
		title.add_theme_constant_override("shadow_offset_x", 3)
		title.add_theme_constant_override("shadow_offset_y", 3)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats_vbox.add_child(title)

		var stats_grid = GridContainer.new()
		stats_grid.columns = 2
		stats_grid.add_theme_constant_override("h_separation", 15)
		stats_vbox.add_child(stats_grid)

		var ammo_val = data["ammo"] as int
		var recoil_str = data["recoil"] as String

		var add_row = func(lbl_text: String, val_text: String):
			var l = Label.new()
			l.text = lbl_text
			l.custom_minimum_size.x = 140
			l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			l.add_theme_color_override("font_shadow_color", Color.BLACK)
			var v = Label.new()
			v.text = val_text
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_theme_color_override("font_color", current_theme_color)
			v.add_theme_color_override("font_shadow_color", Color.BLACK)
			stats_grid.add_child(l)
			stats_grid.add_child(v)

		add_row.call("ПАТРОНЫ:", str(ammo_val))
		add_row.call("ОТДАЧА:", recoil_str)

		var btn_wrapper = Control.new()
		btn_wrapper.name = "BtnWrapper"
		btn_wrapper.custom_minimum_size = Vector2(0, 50)
		btn_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_wrapper.clip_contents = true

		var btn: Button = Button.new()
		btn_wrapper.add_child(btn)
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		wpn_btns[w_id] = btn
		_apply_bad_trip_hover_to_button(btn, "", "ВЗЯТЬ", 24)

		btn.pressed.connect( func() -> void :
			Global.selected_weapon = w_id
			if Global.has_method("save_settings"): Global.save_settings()
			_update_loadout_state()
		)
		card_vbox.add_child(btn_wrapper)
		parent_grid.add_child(card)
		_apply_pulsing_border(card)

func _build_perks_tab(parent_grid: GridContainer) -> void :
	for p_id: String in perks_db.keys():
		var data: Dictionary = perks_db[p_id] as Dictionary

		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(320, 200)

		var unique_style = StyleBoxFlat.new()
		unique_style.bg_color = Color(0.0, 0.0, 0.0, 0.95)
		unique_style.border_width_left = 4;unique_style.border_width_right = 4
		unique_style.border_width_top = 4;unique_style.border_width_bottom = 4
		unique_style.border_color = current_theme_color
		unique_style.anti_aliasing = false

		unique_style.shadow_color = Color.BLACK
		unique_style.shadow_size = 0
		unique_style.shadow_offset = Vector2(8, 8)

		unique_style.content_margin_left = 20;unique_style.content_margin_right = 20
		unique_style.content_margin_top = 20;unique_style.content_margin_bottom = 20
		card.add_theme_stylebox_override("panel", unique_style)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_theme_constant_override("separation", 20)
		card.add_child(card_vbox)

		var top_hbox: HBoxContainer = HBoxContainer.new()
		top_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		top_hbox.add_theme_constant_override("separation", 20)
		card_vbox.add_child(top_hbox)

		var icon_bg = Panel.new()
		icon_bg.custom_minimum_size = Vector2(64, 64)
		icon_bg.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var i_style = StyleBoxFlat.new()
		i_style.bg_color = data["color"] as Color
		i_style.border_width_bottom = 4
		i_style.border_color = Color(0, 0, 0)
		i_style.anti_aliasing = false
		icon_bg.add_theme_stylebox_override("panel", i_style)
		top_hbox.add_child(icon_bg)

		var title_vbox: VBoxContainer = VBoxContainer.new()
		title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_vbox.add_theme_constant_override("separation", 5)
		top_hbox.add_child(title_vbox)

		var title: Label = Label.new()
		title.text = "■ " + (data["name"] as String).to_upper()
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_color_override("font_shadow_color", Color.BLACK)
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_vbox.add_child(title)

		var desc: Label = Label.new()
		desc.text = (data["desc"] as String).to_upper()
		desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		desc.add_theme_color_override("font_shadow_color", Color.BLACK)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_vbox.add_child(desc)

		var btn_wrapper = Control.new()
		btn_wrapper.name = "BtnWrapper"
		btn_wrapper.custom_minimum_size = Vector2(0, 50)
		btn_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_wrapper.size_flags_vertical = Control.SIZE_SHRINK_END
		btn_wrapper.clip_contents = true

		var btn: Button = Button.new()
		btn_wrapper.add_child(btn)
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		prk_btns[p_id] = btn
		_apply_bad_trip_hover_to_button(btn, "", "УСТАНОВИТЬ", 24)

		btn.pressed.connect( func() -> void :
			Global.selected_starting_perk = p_id
			if Global.has_method("save_meta_data"): Global.save_meta_data()
			_update_loadout_state()
		)

		card_vbox.add_child(btn_wrapper)
		parent_grid.add_child(card)
		_apply_pulsing_border(card)

func _build_skills_tab(parent_grid: GridContainer) -> void :
	for s_id: String in skills_db.keys():
		var data: Dictionary = skills_db[s_id] as Dictionary

		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(320, 160)

		var unique_style = StyleBoxFlat.new()
		unique_style.bg_color = Color(0.0, 0.0, 0.0, 0.95)
		unique_style.border_width_left = 4;unique_style.border_width_right = 4
		unique_style.border_width_top = 4;unique_style.border_width_bottom = 4
		unique_style.border_color = current_theme_color
		unique_style.anti_aliasing = false

		unique_style.shadow_color = Color.BLACK
		unique_style.shadow_size = 0
		unique_style.shadow_offset = Vector2(8, 8)

		unique_style.content_margin_left = 20;unique_style.content_margin_right = 20
		unique_style.content_margin_top = 20;unique_style.content_margin_bottom = 20
		card.add_theme_stylebox_override("panel", unique_style)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_theme_constant_override("separation", 15)
		card.add_child(card_vbox)

		var title: Label = Label.new()
		title.text = "■ " + (data["name"] as String).to_upper()
		title.add_theme_color_override("font_color", Color.WHITE)
		title.add_theme_color_override("font_shadow_color", Color.BLACK)
		title.add_theme_constant_override("shadow_offset_x", 2)
		title.add_theme_constant_override("shadow_offset_y", 2)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_vbox.add_child(title)

		var lvl_lbl: Label = Label.new()
		lvl_lbl.add_theme_color_override("font_color", current_theme_color)
		lvl_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		lvl_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(lvl_lbl)

		var btn_wrapper = Control.new()
		btn_wrapper.name = "BtnWrapper"
		btn_wrapper.custom_minimum_size = Vector2(250, 50)
		btn_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_wrapper.size_flags_vertical = Control.SIZE_SHRINK_END
		btn_wrapper.clip_contents = true

		var btn: Button = Button.new()
		btn_wrapper.add_child(btn)
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		skl_lbls[s_id] = lvl_lbl
		skl_btns[s_id] = btn
		_apply_bad_trip_hover_to_button(btn, "", "УЛУЧШИТЬ", 24)

		btn.pressed.connect( func() -> void :
			var current_lvl: int = Global.meta_upgrades.get(s_id, 0) as int
			var cost: int = (data["base_cost"] as int) + (current_lvl * (data["base_cost"] as int))
			if Global.meta_crystals >= cost:
				Global.meta_crystals -= cost
				Global.meta_upgrades[s_id] += 1
				if Global.has_method("save_meta_data"): Global.save_meta_data()
				_update_loadout_state()
		)

		card_vbox.add_child(btn_wrapper)
		parent_grid.add_child(card)
		_apply_pulsing_border(card)

func _show_unlock_popup(data: Dictionary) -> void :
	var popup = CanvasLayer.new()
	popup.layer = 200
	add_child(popup)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.0, 0.0, 0.0)
	popup.add_child(bg)

	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center_container)

	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	v_box.add_theme_constant_override("separation", 30)
	center_container.add_child(v_box)

	var title = Label.new()
	title.text = ">>> " + data["msg"] + " <<<"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", current_theme_color)
	v_box.add_child(title)

	var viewport_container = SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(400, 400)
	viewport_container.stretch = true
	v_box.add_child(viewport_container)

	var viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.size = Vector2(400, 400)
	viewport_container.add_child(viewport)

	var cam = Camera3D.new()
	cam.look_at_from_position(Vector3(0, 0.5, 2.0), Vector3.ZERO)
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 1.5
	cam.environment = env
	viewport.add_child(cam)

	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, 45, 0)
	viewport.add_child(light)

	var model_node = null

	if data["type"] == "item":
		var scene_path = "res://Scenes/Item_" + data["id"].capitalize().replace("_", "") + ".tscn"
		if data["id"] == "speed_syringe": scene_path = "res://Scenes/Item_Syringe.tscn"

		if ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			model_node = scene.instantiate()

	if not model_node:
		model_node = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.8, 0.8, 0.8)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.8, 0.8)
		box.material = mat
		model_node.mesh = box

	_paralyze_model(model_node)

	var spinner = Node3D.new()
	spinner.add_child(model_node)
	viewport.add_child(spinner)
	current_unlock_spinner = spinner

	var item_name_label = Label.new()
	item_name_label.text = "[ " + data["name"] + " ]"
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name_label.add_theme_font_size_override("font_size", 36)
	v_box.add_child(item_name_label)

	var btn_close = Button.new()
	btn_close.text = "ACCEPT"
	btn_close.custom_minimum_size = Vector2(300, 60)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_bad_trip_hover_to_button(btn_close, "", "ACCEPT", 32)
	v_box.add_child(btn_close)

	btn_close.pressed.connect( func():
		popup.queue_free()
		current_unlock_spinner = null
		_update_loadout_state()
	)

	var tween = create_tween()
	tween.tween_property(bg, "color:a", 0.95, 0.5)

	var sound = AudioStreamPlayer.new()
	popup.add_child(sound)
	sound.play()

func build_keybind_list() -> void :
	if not bind_list: return
	for child: Node in bind_list.get_children(): child.queue_free()
	for action: String in Global.keybinds.keys():
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		var label: Label = Label.new()
		label.text = "> " + action_translations.get(action, action.to_upper())
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		var btn: Button = Button.new()
		var keycode: int = Global.keybinds[action] as int
		btn.text = "[ " + OS.get_keycode_string(keycode).to_upper() + " ]"
		btn.custom_minimum_size = Vector2(150, 40)
		btn.set_meta("no_bad_trip", true)
		btn.pressed.connect(_on_bind_button_pressed.bind(action, btn))
		row.add_child(label)
		row.add_child(btn)
		bind_list.add_child(row)

func _on_bind_button_pressed(action_name: String, btn: Button) -> void :
	if listening_button: listening_button.text = "[ " + OS.get_keycode_string(Global.keybinds[listening_action] as int).to_upper() + " ]"
	listening_action = action_name;listening_button = btn
	btn.text = "[ НАЖМИТЕ КЛАВИШУ ]"
	btn.release_focus()

func _input(event: InputEvent) -> void :
	if listening_action != "" and event is InputEventKey:
		if event.pressed:
			var new_key: int = event.physical_keycode
			if new_key != KEY_ESCAPE:
				Global.keybinds[listening_action] = new_key
				Global.apply_keybinds()
				if Global.has_method("save_settings"):
					Global.save_settings()

			listening_button.text = "[ " + OS.get_keycode_string(Global.keybinds[listening_action] as int).to_upper() + " ]"
			listening_action = ""
			listening_button = null

			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		if settings_panel.visible or loadout_panel.visible:
			_on_close_panels()
			get_viewport().set_input_as_handled()

func _connect_graphics_signals() -> void :
	if res_option and not res_option.item_selected.is_connected(_on_resolution_selected): res_option.item_selected.connect(_on_resolution_selected)
	if window_option and not window_option.item_selected.is_connected(_on_window_selected): window_option.item_selected.connect(_on_window_selected)
	if noise_slider and not noise_slider.value_changed.is_connected(_on_noise_changed): noise_slider.value_changed.connect(_on_noise_changed)
	if rgb_slider and not rgb_slider.value_changed.is_connected(_on_rgb_changed): rgb_slider.value_changed.connect(_on_rgb_changed)
	if brightness_slider and not brightness_slider.value_changed.is_connected(_on_brightness_changed): brightness_slider.value_changed.connect(_on_brightness_changed)
	if vhs_intensity_slider and not vhs_intensity_slider.value_changed.is_connected(_on_vhs_intensity_changed):
		vhs_intensity_slider.value_changed.connect(_on_vhs_intensity_changed)
	if vhs_toggle and not vhs_toggle.toggled.is_connected(_on_vhs_toggle_toggled):
		vhs_toggle.toggled.connect(_on_vhs_toggle_toggled)
	if aa_option and not aa_option.item_selected.is_connected(_on_aa_selected): aa_option.item_selected.connect(_on_aa_selected)
	if quality_option and not quality_option.item_selected.is_connected(_on_quality_selected): quality_option.item_selected.connect(_on_quality_selected)
	if vsync_check and not vsync_check.toggled.is_connected(_on_vsync_toggled): vsync_check.toggled.connect(_on_vsync_toggled)
	if style_option and not style_option.item_selected.is_connected(_on_style_selected): style_option.item_selected.connect(_on_style_selected)
	if stats_format_toggle and not stats_format_toggle.toggled.is_connected(_on_stats_format_toggle_toggled):
		stats_format_toggle.toggled.connect(_on_stats_format_toggle_toggled)

	if damage_numbers_toggle and not damage_numbers_toggle.toggled.is_connected(_on_damage_numbers_toggled):
		damage_numbers_toggle.toggled.connect(_on_damage_numbers_toggled)

func setup_graphics_settings() -> void :
	if not res_option or not window_option or not style_option: return
	if res_option.get_item_count() == 0:
		for res: Vector2i in resolutions: res_option.add_item(str(res.x) + " x " + str(res.y))
	if window_option.get_item_count() == 0:
		window_option.add_item("В окне")
		window_option.add_item("Полный экран")
	if style_option.get_item_count() == 0:
		style_option.add_item("Стандартная кассета")
		style_option.add_item("ЧБ (Камера слежения)")
		style_option.add_item("Зеленое ночное видение")
		style_option.add_item("Кровавый (Manhunt)")
	if aa_option and aa_option.get_item_count() == 0:
		aa_option.add_item("Выкл")
		aa_option.add_item("FXAA")
		aa_option.add_item("MSAA 2x")
		aa_option.add_item("MSAA 4x")
		aa_option.add_item("MSAA 8x")
	if quality_option and quality_option.get_item_count() == 0:
		quality_option.add_item("Низкие (Картошка)")
		quality_option.add_item("Средние")
		quality_option.add_item("Высокие")


	if brightness_slider:
		brightness_slider.min_value = 0.0
		brightness_slider.max_value = 3.0
		brightness_slider.step = 0.05
	if noise_slider:
		noise_slider.min_value = 0.0
		noise_slider.max_value = 1.0
		noise_slider.step = 0.01
	if rgb_slider:
		rgb_slider.min_value = 0.0
		rgb_slider.max_value = 0.05
		rgb_slider.step = 0.001
	if vhs_intensity_slider:
		vhs_intensity_slider.min_value = 0.0
		vhs_intensity_slider.max_value = 1.0
		vhs_intensity_slider.step = 0.01

func update_ui_from_global() -> void :
	if sens_slider: sens_slider.set_value_no_signal(Global.mouse_sensitivity)
	if color_picker: color_picker.color = Global.crosshair_color
	if length_slider: length_slider.set_value_no_signal(Global.crosshair_length)
	if gap_slider: gap_slider.set_value_no_signal(Global.crosshair_base_gap)
	if thickness_slider: thickness_slider.set_value_no_signal(Global.crosshair_thickness)
	if master_slider:
		master_slider.set_value_no_signal(Global.master_volume)
		set_bus_volume("Master", Global.master_volume)
	if music_slider:
		music_slider.set_value_no_signal(Global.music_volume)
		set_bus_volume("Music", Global.music_volume)
	if sfx_slider:
		sfx_slider.set_value_no_signal(Global.sfx_volume)
		set_bus_volume("SFX", Global.sfx_volume)

	if res_option: res_option.selected = Global.resolution_index as int
	if window_option: window_option.selected = 1 if Global.is_fullscreen else 0
	if brightness_slider: brightness_slider.set_value_no_signal(Global.brightness as float)
	if aa_option: aa_option.selected = Global.anti_aliasing as int
	if quality_option: quality_option.selected = Global.graphics_quality as int
	if vsync_check: vsync_check.set_pressed_no_signal(Global.vsync as bool)
	if vhs_toggle: vhs_toggle.set_pressed_no_signal(Global.vhs_enabled)
	if vhs_intensity_slider: vhs_intensity_slider.set_value_no_signal(Global.vhs_intensity)
	if noise_slider: noise_slider.set_value_no_signal(Global.vhs_noise)
	if rgb_slider: rgb_slider.set_value_no_signal(Global.vhs_rgb)
	if style_option: style_option.selected = Global.vhs_style
	if stats_format_toggle: stats_format_toggle.set_pressed_no_signal(Global.show_stats_as_percentage)

	if damage_numbers_toggle: damage_numbers_toggle.set_pressed_no_signal(Global.show_damage_numbers)

	update_value_labels()
	if crosshair_preview: crosshair_preview.queue_redraw()

func update_value_labels() -> void :
	if sens_value_label: sens_value_label.text = str(snapped(Global.mouse_sensitivity as float, 0.001))
	if length_value_label: length_value_label.text = str(Global.crosshair_length)
	if gap_value_label: gap_value_label.text = str(Global.crosshair_base_gap)
	if thickness_value_label: thickness_value_label.text = str(Global.crosshair_thickness)
	if master_value_label: master_value_label.text = str(int((Global.master_volume as float) * 100)) + "%"
	if music_value_label: music_value_label.text = str(int((Global.music_volume as float) * 100)) + "%"
	if sfx_value_label: sfx_value_label.text = str(int((Global.sfx_volume as float) * 100)) + "%"

func set_bus_volume(bus_name: String, value: float) -> void :
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	if value <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_master_changed(value: float) -> void :
	Global.master_volume = value
	update_value_labels()
	if Global.has_method("apply_audio_settings"): Global.apply_audio_settings()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_music_changed(value: float) -> void :
	Global.music_volume = value
	update_value_labels()
	if Global.has_method("apply_audio_settings"): Global.apply_audio_settings()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_sfx_changed(value: float) -> void :
	Global.sfx_volume = value
	update_value_labels()
	if Global.has_method("apply_audio_settings"): Global.apply_audio_settings()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_sens_changed(value: float) -> void :
	Global.mouse_sensitivity = value
	update_value_labels()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_color_changed(color: Color) -> void :
	Global.crosshair_color = color
	if crosshair_preview: crosshair_preview.queue_redraw()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_length_changed(value: float) -> void :
	Global.crosshair_length = value
	update_value_labels()
	if crosshair_preview: crosshair_preview.queue_redraw()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_gap_changed(value: float) -> void :
	Global.crosshair_base_gap = value
	update_value_labels()
	if crosshair_preview: crosshair_preview.queue_redraw()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_thickness_changed(value: float) -> void :
	Global.crosshair_thickness = value
	update_value_labels()
	if crosshair_preview: crosshair_preview.queue_redraw()
	if Global.has_method("save_settings"): Global.save_settings()

func _on_preview_draw() -> void :
	if not crosshair_preview: return
	crosshair_preview.draw_rect(Rect2(Vector2.ZERO, crosshair_preview.size), Color(0.02, 0.02, 0.02, 0.9))
	var center: Vector2 = crosshair_preview.size / 2.0
	var color: Color = Global.crosshair_color
	var length: float = Global.crosshair_length as float
	var gap: float = Global.crosshair_base_gap as float
	var thick: float = Global.crosshair_thickness as float
	if Global.crosshair_dot:
		crosshair_preview.draw_rect(Rect2(center - Vector2(thick / 2.0, thick / 2.0), Vector2(thick, thick)), color)
	crosshair_preview.draw_rect(Rect2(center.x - gap - length, center.y - thick / 2.0, length, thick), color)
	crosshair_preview.draw_rect(Rect2(center.x + gap, center.y - thick / 2.0, length, thick), color)
	crosshair_preview.draw_rect(Rect2(center.x - thick / 2.0, center.y - gap - length, thick, length), color)
	crosshair_preview.draw_rect(Rect2(center.x - thick / 2.0, center.y + gap, thick, length), color)

func _on_resolution_selected(index: int) -> void :
	Global.resolution_index = index
	if Global.has_method("apply_graphics_settings"):
		Global.apply_graphics_settings()
	if Global.has_method("save_settings"):
		Global.save_settings()

func _on_window_selected(index: int) -> void :
	Global.is_fullscreen = (index == 1)
	if Global.has_method("apply_graphics_settings"):
		Global.apply_graphics_settings()
	if Global.has_method("save_settings"):
		Global.save_settings()

func _on_brightness_changed(value: float) -> void : Global.brightness = value;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_aa_selected(index: int) -> void : Global.anti_aliasing = index;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_quality_selected(index: int) -> void : Global.graphics_quality = index;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_vsync_toggled(button_pressed: bool) -> void : Global.vsync = button_pressed;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()

func _on_noise_changed(value: float) -> void :
	Global.vhs_noise = value
	get_tree().call_group("vhs_filter", "update_vhs_settings")
	if Global.has_method("save_settings"): Global.save_settings()

func _on_rgb_changed(value: float) -> void :
	Global.vhs_rgb = value
	get_tree().call_group("vhs_filter", "update_vhs_settings")
	if Global.has_method("save_settings"): Global.save_settings()

func _on_vhs_intensity_changed(value: float) -> void :
	Global.vhs_intensity = value
	get_tree().call_group("vhs_filter", "update_vhs_settings")
	if Global.has_method("save_settings"): Global.save_settings()

func _on_vhs_toggle_toggled(button_pressed: bool) -> void :
	Global.vhs_enabled = button_pressed
	get_tree().call_group("vhs_filter", "update_vhs_settings")
	if Global.has_method("save_settings"): Global.save_settings()

func _on_style_selected(index: int) -> void :
	Global.vhs_style = index
	get_tree().call_group("vhs_filter", "update_vhs_settings")
	if Global.has_method("save_settings"): Global.save_settings()

func _on_stats_format_toggle_toggled(toggled_on: bool) -> void :
	Global.show_stats_as_percentage = toggled_on
	if Global.has_method("save_settings"): Global.save_settings()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("update_health_ui"): player.update_health_ui()
		if player.has_method("update_mana_ui"): player.update_mana_ui()

func _on_damage_numbers_toggled(toggled_on: bool) -> void :
	Global.show_damage_numbers = toggled_on
	if Global.has_method("save_settings"): Global.save_settings()

func _create_damage_toggle_ui() -> void :
	if not stats_format_toggle: return

	var ui_container = stats_format_toggle.get_parent()
	if ui_container is HBoxContainer:
		ui_container = ui_container.get_parent()

	var row = HBoxContainer.new()
	row.name = "DamageNumbersRow"

	var lbl = Label.new()
	lbl.name = "DamageLabel"
	lbl.text = "ПОКАЗЫВАТЬ ЦИФРЫ УРОНА"
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	damage_numbers_toggle = CheckButton.new()
	damage_numbers_toggle.name = "DamageNumbersToggle"
	damage_numbers_toggle.set_pressed_no_signal(Global.show_damage_numbers)
	row.add_child(damage_numbers_toggle)

	ui_container.add_child(row)

	if not damage_numbers_toggle.toggled.is_connected(_on_damage_numbers_toggled):
		damage_numbers_toggle.toggled.connect(_on_damage_numbers_toggled)

func _apply_window_settings() -> void :
	var main_window = get_window()
	var current_res = resolutions[Global.resolution_index] if Global.resolution_index < resolutions.size() else Vector2i(1920, 1080)

	if Global.is_fullscreen:
		main_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		if main_window.mode != Window.MODE_WINDOWED:
			main_window.mode = Window.MODE_WINDOWED
			main_window.borderless = false
			await get_tree().process_frame

		main_window.size = current_res
		await get_tree().process_frame

		var screen_size = DisplayServer.screen_get_size(main_window.current_screen)
		main_window.position = (screen_size / 2) - (current_res / 2)

	get_tree().root.content_scale_size = current_res
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE

	if Global.has_method("apply_graphics_settings"):
		Global.apply_graphics_settings()

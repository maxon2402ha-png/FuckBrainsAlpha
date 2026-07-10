extends CharacterBody3D

signal on_hit(is_headshot)
signal spread_changed(new_spread_value)




var muzzle_side_shader = preload("res://Shaders/muzzle_flash_side.gdshader")
var muzzle_face_shader = preload("res://Shaders/muzzle_flash_face.gdshader")
var base_walk_speed = 6.0
var base_sprint_speed = 11.5
var hammer_timer: float = 0.0

const GROUND_ACCEL = 8.0
const GROUND_FRICTION = 7.0
const AIR_ACCEL = 2.0

var jump_velocity = 8.5
const GRAVITY = 28.0
var coyote_time = 0.0
var jump_buffer = 0.0

const SLIDE_START_SPEED = 18.0
const SLIDE_FRICTION = 6.0
const SLIDE_MIN_SPEED = 5.0
const SLIDE_CONTROL = 2.0
var is_sliding = false
var slide_tilt_dir = 1.0
var slide_timer = 0.0
var slide_duration = 0.0

var is_sprinting = false

var is_mantling = false
var player_half_height = 1.0
var mantle_target_pos = Vector3.ZERO
var mantle_start_pos = Vector3.ZERO
var mantle_timer = 0.0
var mantle_duration = 0.2


var max_stamina = 100.0
var current_stamina = 100.0
var stamina_recharge_rate = 45.0
var sprint_stamina_drain = 12.0
var slide_stamina_cost = 20.0
var is_exhausted = false

var stamina_battery_container: Control
var stamina_battery_rect: ColorRect
var stamina_battery_time: float = 0.0
var stamina_drain_impact: float = 0.0

var air_time = 0.0
var was_in_air = false
var landing_impact = 0.0
var camera_tilt_target = 0.0
var move_tilt = 0.0
var current_slide_tilt = 0.0

var t_bob = 0.0
var last_step_time = 0.0
var headbob_intensity = 0.0

var current_state_pos_offset = Vector3.ZERO
var current_state_rot_offset = Vector3.ZERO

const TILT_AMOUNT = 0.05
const CAM_HEIGHT_STANDING = 1.6
const CAM_HEIGHT_SLIDING = 0.5
const CAM_SMOOTH_SPEED = 18.0

var kick_cooldown: float = 0.0
const KICK_COOLDOWN_TIME = 0.5
const KICK_FOV_KICK = 5.0
const KICK_TILT_AMOUNT = deg_to_rad(4.0)
const KICKBACK_FORCE_ON_PLAYER = 2.0

var prev_velocity_y: float = 0.0

var target_landing_dip_pos: float = 0.0
var target_landing_dip_rot: float = 0.0
var landing_dip_pos: float = 0.0
var landing_dip_rot: float = 0.0

var jump_fall_tilt: float = 0.0
var target_jump_fall_tilt: float = 0.0

var bob_x: float = 0.0
var bob_y: float = 0.0
const HEADBOB_WALK_AMP = Vector2(0.04, 0.05)
const HEADBOB_SPRINT_AMP = Vector2(0.08, 0.12)
const HEADBOB_FREQ_MULT = 2.8

var weapon_origins = {}
var active_model: Node3D
var weapon_anim_player: AnimationPlayer

var max_health = 100
var current_health = 100
var max_mana = 0
var current_mana = 0

var ecg_container: Control
var ecg_rect: ColorRect
var ecg_border: ReferenceRect
var ecg_status_lbl: Label
var ecg_numbers_lbl: Label
var ecg_time: float = 0.0
var ecg_damage_impact: float = 0.0
var current_ecg_color: Color = Color(0.2, 1.0, 0.4)

var market_container: Control
var market_border: ReferenceRect
var market_graph_rect: ColorRect
var market_value_lbl: Label
var market_delta_lbl: Label
var market_inflation_lbl: Label
var arrow_up_lbl: Label
var arrow_down_lbl: Label
var money_title: Label

var visual_money: float = 0.0
var money_impact_timer: float = 0.0
var money_shake_impact: float = 0.0
var last_money_diff: int = 0
var market_trend: int = 0
var target_market_scale: Vector2 = Vector2.ONE

const COLOR_MARKET_BG = Color(0.02, 0.02, 0.04, 0.95)
const COLOR_MARKET_BORDER = Color(0.0, 1.0, 0.4)
const COLOR_MONEY_UP = Color(0.0, 1.0, 0.2)
const COLOR_MONEY_DOWN = Color(1.0, 0.0, 0.2)

var ammo_box: Control
var ammo_bg: ColorRect
var ammo_border: ReferenceRect
var ammo_title: Label
var ammo_val_lbl: Label
var ammo_integrity_lbl: Label
var ammo_visual_rect: ColorRect
var ammo_shake_impact: float = 0.0

var is_dead = false
var skip_save_stats = false
var damage = 20
var max_ammo = 12
var current_ammo = 12
var is_reloading = false
var is_automatic = false
var base_weapon_fire_rate = 0.1
var current_fire_timer = 0.0

var base_spread = 0.02
var move_spread_factor = 3.0
var jump_spread_factor = 6.0
var fire_spread_increment = 0.05
var max_spread_limit = 0.3
var spread_recovery = 6.0
var current_spread = 0.0

var sway_pos = Vector3.ZERO
var sway_rot = Vector3.ZERO
var sway_speed = 6.0
var sway_amount_pos = 0.02
var sway_amount_rot = 0.5

var recoil_pos_curr = Vector3.ZERO
var recoil_pos_target = Vector3.ZERO
var recoil_rot_curr = Vector3.ZERO
var recoil_rot_target = Vector3.ZERO
var recoil_snap = 35.0
var recoil_return = 12.0

const MAX_RECOIL_POS_Z = 0.45
const MAX_RECOIL_ROT_X = 75.0
const MAX_RECOIL_ROT_Y = 25.0

var cam_recoil_target = Vector3.ZERO
var cam_recoil_curr = Vector3.ZERO

var weapon_bob_weight: float = 1.0

var camera_pitch: float = 0.0
var noise = FastNoiseLite.new()
var noise_time = 0.0
var mouse_input = Vector2.ZERO
var target_fov = 90.0
var default_fov = 90.0

var trauma: float = 0.0
var shake_rot = Vector3.ZERO
var fov_kick = 0.0
var target_fov_kick = 0.0
var max_x_angle: float = 4.0
var max_y_angle: float = 4.0
var max_z_angle: float = 2.0
var trauma_decay: float = 3.0
var shake_power = 1.0

var is_inventory_open = false
var target_weapon_pos: Vector3
var target_weapon_rot: Vector3

var footstep_player: AudioStreamPlayer3D
var hitmarker_player: AudioStreamPlayer

var sound_walk = load("res://Assets/Sound/walk.mp3")
var sound_run = load("res://Assets/Sound/run.mp3")
var sound_hitmarker = preload("res://Assets/Sound/hit.mp3")

var has_baby_oil: bool = false
var oil_timer: float = 0.0
var oil_puddle_scene = preload("res://Scenes/oil_puddle.tscn")
var fire_trail_timer: float = 0.0
var fire_trail_scene = preload("res://Scenes/fire_trail.tscn")

var damage_overlay: ColorRect
var hole_scene = preload("res://Scenes/bullet_hole.tscn")


var cached_muzzle_side_mat: ShaderMaterial = null
var cached_muzzle_face_mat: ShaderMaterial = null
var cached_spark_ramp: GradientTexture1D = null
var cached_spark_mesh_mat: StandardMaterial3D = null
var cached_blood_pool_mat: ShaderMaterial = null

var boss_health_bar: ProgressBar
var boss_name_label: Label
var active_boss_ref: Node3D = null

@onready var head = $Head
@onready var camera = $Head / Camera3D
@onready var raycast = $Head / Camera3D / RayCast3D

@onready var Menu = get_node_or_null("CanvasLayer_UI/Menu")
@onready var settings_panel = get_node_or_null("CanvasLayer_UI/SettingsPanel")

@onready var osd_ui = $CanvasLayer_UI / Control_OSD
@onready var health_label = get_node_or_null("CanvasLayer_UI/Control_OSD/BottomLeftContainer/VBoxContainer_Stats/HealthLabel")
@onready var ammo_label = get_node_or_null("CanvasLayer_UI/Control_OSD/BottomLeftContainer/VBoxContainer_Stats/AmmoLabel")
@onready var money_label = get_node_or_null("CanvasLayer_UI/Control_OSD/BottomLeftContainer/VBoxContainer_Stats/MoneyLabel")
@onready var crosshair_label = get_node_or_null("CanvasLayer_UI/Control_OSD/CenterContainer/Crosshair")

@onready var stamina_bar = find_child("StaminaBar", true, false)
@onready var notification_box = find_child("NotificationBox", true, false)
@onready var loadout_menu = get_node_or_null("CanvasLayer_UI/LoadoutMenu")

@onready var anim_player = $AnimationPlayer
@onready var gun_sound = $Head / GunSound
@onready var reload_sound = $Head / ReloadSound
@onready var weapons_container = $Head / Camera3D / WeaponsContainer
@onready var pistol_node = $Head / Camera3D / WeaponsContainer / Pistol
@onready var rifle_node = $Head / Camera3D / WeaponsContainer / Rifle
@onready var shotgun_node = $Head / Camera3D / WeaponsContainer / Shotgun

var panties_aura_mesh: MeshInstance3D = null


var badtrip_pause_menu: Control
var ui_audio_player: AudioStreamPlayer
var sound_ui_hover = preload("res://Assets/Sound/walk.mp3")
var sound_ui_drag = preload("res://Assets/Sound/hit.mp3")
var last_drag_time: float = 0.0




@onready var sens_slider: Slider = find_child("SensSlider", true, false) as Slider
@onready var vhs_toggle: CheckButton = find_child("VHSToggle", true, false) as CheckButton
@onready var style_option: OptionButton = find_child("StyleOption", true, false) as OptionButton
@onready var noise_slider: Slider = find_child("NoiseSlider", true, false) as Slider
@onready var rgb_slider: Slider = find_child("RGBSlider", true, false) as Slider
@onready var vhs_intensity_slider: Slider = find_child("VHSIntensitySlider", true, false) as Slider
@onready var stats_format_toggle: CheckButton = find_child("StatsFormatToggle", true, false) as CheckButton
@onready var color_picker: ColorPickerButton = find_child("ColorPickerButton", true, false) as ColorPickerButton
@onready var length_slider: Slider = find_child("LengthSlider", true, false) as Slider
@onready var gap_slider: Slider = find_child("GapSlider", true, false) as Slider
@onready var thickness_slider: Slider = find_child("ThicknessSlider", true, false) as Slider
@onready var crosshair_preview: Control = find_child("CrosshairPreview", true, false) as Control
@onready var master_slider: Slider = find_child("MasterSlider", true, false) as Slider
@onready var music_slider: Slider = find_child("MusicSlider", true, false) as Slider
@onready var sfx_slider: Slider = find_child("SFXSlider", true, false) as Slider
@onready var bind_list: Control = find_child("BindList", true, false) as Control
@onready var res_option: OptionButton = find_child("ResOption", true, false) as OptionButton
@onready var window_option: OptionButton = find_child("WindowOption", true, false) as OptionButton
@onready var aa_option: OptionButton = find_child("AAOption", true, false) as OptionButton
@onready var quality_option: OptionButton = find_child("QualityOption", true, false) as OptionButton
@onready var brightness_slider: Slider = find_child("BrightnessSlider", true, false) as Slider
@onready var vsync_check: CheckButton = find_child("VSyncCheck", true, false) as CheckButton

var sens_value_label: Label
var length_value_label: Label
var gap_value_label: Label
var thickness_value_label: Label
var master_value_label: Label
var music_value_label: Label
var sfx_value_label: Label

var current_theme_color: Color = Color(0.9, 0.05, 0.05)

var action_translations: Dictionary = {
	"move_forward": "SYS.MOVE_FWD", "move_back": "SYS.MOVE_BWD", "move_left": "SYS.STRAFE_L", "move_right": "SYS.STRAFE_R", 
	"jump": "SYS.JUMP", "crouch": "SYS.CROUCH", "sprint": "SYS.DASH", "reload": "SYS.RELOAD", "interact": "SYS.INTERACT"
}
var listening_action: String = ""
var listening_button: Button = null
var resolutions: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(800, 600)]


var current_interactable: Node3D = null
const INTERACT_DISTANCE = 2.5


var bot_nav_agent: NavigationAgent3D
var bot_stuck_timer: float = 0.0
var bot_last_pos: Vector3 = Vector3.ZERO
var auto_test_timer: float = 0.0
var bot_strafe_dir: float = 1.0
var bot_strafe_timer: float = 0.0
var bot_ray_front: RayCast3D
var bot_ray_left: RayCast3D
var bot_ray_right: RayCast3D
var bot_roam_target: Vector3 = Vector3.ZERO
var bot_roam_timer: float = 0.0
var bot_reverse_timer: float = 0.0

var cached_bot_target: Node3D = null
var bot_target_refresh_timer: float = 0.0

var item_names_ru = {
	"baby_oil": "Детское масло", "mge_photo": "Фото МГЕ брата", "chingis_eggs": "Три яйца Чингисхана", "plunger": "Вантуз", 
	"maduro_drink": "Напиток Мадуро", "diary": "Ежедневник", "nails": "Гвозди", "medpolis": "Медполис", "rubiks_cube": "Кубик Рубика", 
	"gold_chain": "Золотая цепочка", "lightbulb": "Лампочка", "shishkin": "Встанислав Шишкин", "panties": "Использованные трусы", 
	"cologne": "Одеколон ХХХ", "xbox_gamepad": "Геймпад Xbox", "ps_gamepad": "Геймпад PlayStation", "huy_yogurt": "Хурмовый Украинский Йогурт(ХУЙ)", 
	"soldering_iron": "Паяльник"
}

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	raycast.add_exception(self)

	floor_stop_on_slope = true
	floor_block_on_wall = true
	platform_on_leave = PLATFORM_ON_LEAVE_DO_NOTHING
	safe_margin = 0.08

	if osd_ui:
		osd_ui.visible = true
		osd_ui.modulate = Color(2.0, 2.0, 2.0, 1.0)

	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.position = Vector3(0, -1.0, 0)
	footstep_player.max_polyphony = 6
	footstep_player.bus = "SFX"
	add_child(footstep_player)

	hitmarker_player = AudioStreamPlayer.new()
	hitmarker_player.max_polyphony = 10
	hitmarker_player.bus = "SFX"
	add_child(hitmarker_player)

	if gun_sound: gun_sound.max_polyphony = 10

	setup_boss_health_bar()

	max_health = Global.get_final_max_health()
	if Global.player_health > 0: current_health = Global.player_health
	else: current_health = max_health

	max_mana = Global.get_final_max_mana()
	if Global.player_mana >= 0: current_mana = Global.player_mana
	else: current_mana = max_mana

	_setup_ecg_ui()
	if health_label: health_label.hide()

	_setup_stamina_battery_ui()
	if stamina_bar: stamina_bar.hide()

	_setup_market_ui()
	if money_label: money_label.hide()

	_setup_ammo_ui()
	if ammo_label: ammo_label.hide()

	update_health_ui()
	update_mana_ui()

	visual_money = float(Global.money)
	Global.money_updated.connect(_on_money_pushed_from_global)

	default_fov = camera.fov
	noise.seed = randi()
	noise.frequency = 0.8

	for child in weapons_container.get_children():
		if child is Node3D:
			weapon_origins[child.name] = {"pos": child.position, "rot": child.rotation_degrees}

	Global.current_weapon_type = Global.selected_weapon
	setup_weapon(Global.current_weapon_type)
	target_fov = default_fov

	var canvas = CanvasLayer.new()
	canvas.layer = 15
	add_child(canvas)

	damage_overlay = ColorRect.new()
	damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_overlay.color = Color(0.8, 0.0, 0.0, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(damage_overlay)

	_setup_ps1_filter()
	_build_perfect_badtrip_menu()
	_init_real_settings_panel()
	_prepare_combat_assets()

func _init_real_settings_panel():
	if not settings_panel: return

	settings_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	ui_audio_player = AudioStreamPlayer.new()
	ui_audio_player.bus = "SFX"
	ui_audio_player.max_polyphony = 10
	ui_audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui_audio_player)

	if FileAccess.file_exists("user://pinned_theme.json"):
		var file = FileAccess.open("user://pinned_theme.json", FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var data = JSON.parse_string(text)
			if typeof(data) == TYPE_DICTIONARY and data.get("is_pinned", false):
				current_theme_color = Color(data.get("color_html", "e60d0d"))

	var close_btn = settings_panel.find_child("CloseButton*", true, false) as Button
	if close_btn and not close_btn.pressed.is_connected(close_settings):
		close_btn.pressed.connect(close_settings)

	_setup_ui_sounds_and_binds(settings_panel)

	if sens_slider: sens_value_label = sens_slider.get_parent().get_node_or_null("LabelValue")
	if length_slider: length_value_label = length_slider.get_parent().get_node_or_null("LabelValue")
	if gap_slider: gap_value_label = gap_slider.get_parent().get_node_or_null("LabelValue")
	if thickness_slider: thickness_value_label = thickness_slider.get_parent().get_node_or_null("LabelValue")
	if master_slider: master_value_label = master_slider.get_parent().get_node_or_null("LabelValue")
	if music_slider: music_value_label = music_slider.get_parent().get_node_or_null("LabelValue")
	if sfx_slider: sfx_value_label = sfx_slider.get_parent().get_node_or_null("LabelValue")

	_connect_graphics_signals()

	if sens_slider and not sens_slider.value_changed.is_connected(_on_sens_changed): sens_slider.value_changed.connect(_on_sens_changed)
	if color_picker and not color_picker.color_changed.is_connected(_on_color_changed): color_picker.color_changed.connect(_on_color_changed)
	if length_slider and not length_slider.value_changed.is_connected(_on_length_changed): length_slider.value_changed.connect(_on_length_changed)
	if gap_slider and not gap_slider.value_changed.is_connected(_on_gap_changed): gap_slider.value_changed.connect(_on_gap_changed)
	if thickness_slider and not thickness_slider.value_changed.is_connected(_on_thickness_changed): thickness_slider.value_changed.connect(_on_thickness_changed)
	if master_slider and not master_slider.value_changed.is_connected(_on_master_changed): master_slider.value_changed.connect(_on_master_changed)
	if music_slider and not music_slider.value_changed.is_connected(_on_music_changed): music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider and not sfx_slider.value_changed.is_connected(_on_sfx_changed): sfx_slider.value_changed.connect(_on_sfx_changed)

	if crosshair_preview and not crosshair_preview.draw.is_connected(_on_preview_draw):
		crosshair_preview.draw.connect(_on_preview_draw)

	build_keybind_list()
	setup_graphics_settings()
	_stylize_settings_window()
	_apply_manhunt_theme_recursive(settings_panel)
	update_ui_from_global()

func _setup_ui_sounds_and_binds(node: Node):
	if node is Slider:
		if not node.mouse_entered.is_connected(_on_ui_hover):
			node.mouse_entered.connect(_on_ui_hover)
		if not node.value_changed.is_connected(_on_slider_drag):
			node.value_changed.connect(_on_slider_drag)

	elif node is BaseButton:
		if not node.mouse_entered.is_connected(_on_ui_hover):
			node.mouse_entered.connect(_on_ui_hover)

		if node is CheckButton:
			if not node.toggled.is_connected(_on_ui_click):
				node.toggled.connect( func(_pressed): _on_ui_click())

		elif node is OptionButton:
			if not node.item_selected.is_connected(_on_ui_click):
				node.item_selected.connect( func(_index): _on_ui_click())

		elif node is ColorPickerButton:
			if not node.color_changed.is_connected(_on_ui_click):
				node.color_changed.connect( func(_color): _on_ui_click())

	for child in node.get_children():
		_setup_ui_sounds_and_binds(child)

func _on_ui_hover():
	if sound_ui_hover and ui_audio_player:
		ui_audio_player.stream = sound_ui_hover
		ui_audio_player.pitch_scale = randf_range(0.9, 1.1)
		ui_audio_player.play()

func _on_ui_click():
	if sound_ui_drag and ui_audio_player:
		ui_audio_player.stream = sound_ui_drag
		ui_audio_player.pitch_scale = randf_range(0.95, 1.05)
		ui_audio_player.play()

func _on_slider_drag(_value: float):
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_drag_time > 0.08:
		last_drag_time = current_time
		_on_ui_click()

func _stylize_settings_window() -> void :
	var close_settings_button_ref = settings_panel.find_child("CloseButton*", true, false) as Button
	if close_settings_button_ref:
		close_settings_button_ref.text = "SYS.RETURN"
		close_settings_button_ref.custom_minimum_size = Vector2(250, 50)
		_apply_bad_trip_hover_to_button(close_settings_button_ref, "", "SYS.RETURN", 32)

	var tabs = _find_node_by_class(settings_panel, "TabContainer") as TabContainer
	if tabs:
		for i in range(tabs.get_tab_count()):
			var old_title = tabs.get_tab_title(i)
			tabs.set_tab_title(i, "/ " + old_title.to_upper())

func _find_node_by_class(parent: Node, target_class: String) -> Node:
	for child in parent.get_children():
		if child.is_class(target_class): return child
		var found = _find_node_by_class(child, target_class)
		if found: return found
	return null

func _apply_manhunt_theme_recursive(node: Node) -> void :
	if (node is Panel or node is PanelContainer) and not node.has_theme_stylebox_override("panel") and not node is ScrollContainer:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.01, 0.01, 0.01, 0.9)
		style.border_width_left = 4
		style.border_color = current_theme_color
		style.content_margin_left = 20;style.content_margin_right = 20
		style.content_margin_top = 20;style.content_margin_bottom = 20
		node.add_theme_stylebox_override("panel", style)

	if node is TabContainer:
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.02, 0.02, 0.02, 0.8)
		node.add_theme_stylebox_override("panel", panel_style)

		var tab_sel = StyleBoxFlat.new()
		var s_color = current_theme_color;s_color.a = 0.8
		tab_sel.bg_color = s_color
		tab_sel.content_margin_left = 20;tab_sel.content_margin_right = 20
		tab_sel.content_margin_top = 10;tab_sel.content_margin_bottom = 10
		node.add_theme_stylebox_override("tab_selected", tab_sel)

		var tab_unsel = StyleBoxFlat.new()
		tab_unsel.bg_color = Color(0.0, 0.0, 0.0, 0.8)
		tab_unsel.content_margin_left = 20;tab_unsel.content_margin_right = 20
		tab_unsel.content_margin_top = 10;tab_unsel.content_margin_bottom = 10
		node.add_theme_stylebox_override("tab_unselected", tab_unsel)

		node.add_theme_color_override("font_selected_color", Color(1.0, 1.0, 1.0))
		node.add_theme_color_override("font_unselected_color", Color(0.4, 0.4, 0.4))

	if node is Label:
		node.add_theme_font_size_override("font_size", 22)
		var txt = node.text.to_upper()
		if txt == "EQUIPPED" or txt == "ACTIVE" or "SYS." in txt or txt == "REC":
			node.add_theme_color_override("font_color", current_theme_color)
		else:
			node.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			if not txt.begins_with(">") and not txt.begins_with("[") and not txt.is_valid_float() and not "%" in txt:
				if node.name.contains("Label") and not node.name.contains("Value"):
					if not node.has_meta("styled"):
						node.text = "> " + txt
						node.set_meta("styled", true)

	if node is Button and not node is OptionButton and not node is ColorPickerButton and not node is CheckButton:
		if not node.has_meta("bad_trip") and not node.has_meta("no_bad_trip") and node.text != "":
			var original_text = node.text
			_apply_bad_trip_hover_to_button(node, "", original_text, 24)

	if node is CheckButton:
		node.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		node.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		node.add_theme_color_override("font_pressed_color", current_theme_color)

	if node is Button and node.has_meta("no_bad_trip"):
		var flat_style = StyleBoxFlat.new()
		var btn_col = current_theme_color;btn_col.a = 0.2
		flat_style.bg_color = btn_col
		flat_style.border_width_bottom = 2
		flat_style.border_color = current_theme_color
		node.add_theme_stylebox_override("normal", flat_style)
		node.add_theme_stylebox_override("hover", flat_style)
		node.add_theme_color_override("font_color", current_theme_color)
		node.add_theme_font_size_override("font_size", 22)

	if node is HSlider or node is VSlider:
		var slider_style: StyleBoxFlat = StyleBoxFlat.new()
		slider_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
		slider_style.expand_margin_top = 6
		slider_style.expand_margin_bottom = 6
		node.add_theme_stylebox_override("slider", slider_style)

		var img: Image = Image.create_empty(16, 28, false, Image.FORMAT_RGBA8)
		img.fill(current_theme_color)
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		node.add_theme_icon_override("grabber", tex)
		node.add_theme_icon_override("grabber_highlight", tex)

	if node is ColorPickerButton:
		var cp_style = StyleBoxFlat.new()
		cp_style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
		cp_style.border_width_left = 2
		cp_style.border_width_right = 2
		cp_style.border_width_top = 2
		cp_style.border_width_bottom = 2
		cp_style.border_color = current_theme_color
		node.add_theme_stylebox_override("normal", cp_style)
		node.add_theme_stylebox_override("hover", cp_style)
		node.add_theme_stylebox_override("pressed", cp_style)
		node.custom_minimum_size = Vector2(80, 32)

	if node is OptionButton:
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
		btn_style.border_width_bottom = 2
		btn_style.border_color = current_theme_color
		btn_style.content_margin_left = 10;btn_style.content_margin_right = 10
		node.add_theme_stylebox_override("normal", btn_style)
		node.add_theme_stylebox_override("hover", btn_style)
		node.add_theme_stylebox_override("pressed", btn_style)
		node.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))

	for child: Node in node.get_children():
		_apply_manhunt_theme_recursive(child)

func _apply_bad_trip_hover_to_button(btn: Button, _icon_text: String = "", _main_text: String = "", font_sz: int = 28) -> void :
	if btn.has_meta("bad_trip"): return
	btn.set_meta("bad_trip", true)
	var original_text = btn.text if btn.text != "" else _main_text
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	btn.add_theme_font_size_override("font_size", font_sz)

	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)

	var hover_bg = ColorRect.new()
	hover_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var h_color = current_theme_color;h_color.a = 0.6
	hover_bg.color = h_color
	hover_bg.visible = false
	hover_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hover_bg)
	btn.move_child(hover_bg, 0)

	btn.mouse_entered.connect( func():
		if btn.has_meta("shake_tween"):
			var st = btn.get_meta("shake_tween")
			if is_instance_valid(st): st.kill()

		hover_bg.visible = true
		btn.text = "> " + original_text
		btn.add_theme_color_override("font_color", Color.WHITE)

		var shake_tween = create_tween()
		shake_tween.tween_property(btn, "position:x", btn.position.x + randf_range(-3.0, 3.0), 0.05)
		shake_tween.tween_property(btn, "position:x", btn.position.x, 0.05)
		btn.set_meta("shake_tween", shake_tween)
	)

	btn.mouse_exited.connect( func():
		if btn.has_meta("shake_tween"):
			var st = btn.get_meta("shake_tween")
			if is_instance_valid(st): st.kill()
			btn.remove_meta("shake_tween")

		hover_bg.visible = false
		btn.text = original_text
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	)

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
	btn.text = "[ _AWAITING_INPUT_ ]"
	btn.release_focus()

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
	_apply_window_settings()
	if Global.has_method("save_settings"):
		Global.save_settings()
func _on_window_selected(index: int) -> void :
	Global.is_fullscreen = (index == 1)
	_apply_window_settings()
	if Global.has_method("save_settings"):
		Global.save_settings()
func _on_brightness_changed(value: float) -> void : Global.brightness = value;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_aa_selected(index: int) -> void : Global.anti_aliasing = index;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_quality_selected(index: int) -> void : Global.graphics_quality = index;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_vsync_toggled(button_pressed: bool) -> void : Global.vsync = button_pressed;Global.apply_graphics_settings(); if Global.has_method("save_settings"): Global.save_settings()
func _on_noise_changed(value: float) -> void : Global.vhs_noise = value;get_tree().call_group("vhs_filter", "update_vhs_settings"); if Global.has_method("save_settings"): Global.save_settings()
func _on_rgb_changed(value: float) -> void : Global.vhs_rgb = value;get_tree().call_group("vhs_filter", "update_vhs_settings"); if Global.has_method("save_settings"): Global.save_settings()
func _on_vhs_intensity_changed(value: float) -> void : Global.vhs_intensity = value;get_tree().call_group("vhs_filter", "update_vhs_settings"); if Global.has_method("save_settings"): Global.save_settings()
func _on_vhs_toggle_toggled(button_pressed: bool) -> void : Global.vhs_enabled = button_pressed;get_tree().call_group("vhs_filter", "update_vhs_settings"); if Global.has_method("save_settings"): Global.save_settings()
func _on_style_selected(index: int) -> void : Global.vhs_style = index;get_tree().call_group("vhs_filter", "update_vhs_settings"); if Global.has_method("save_settings"): Global.save_settings()
func _on_stats_format_toggle_toggled(toggled_on: bool) -> void :
	Global.show_stats_as_percentage = toggled_on
	if Global.has_method("save_settings"): Global.save_settings()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("update_health_ui"): player.update_health_ui()
		if player.has_method("update_mana_ui"): player.update_mana_ui()

func setup_boss_health_bar():
	boss_health_bar = ProgressBar.new()
	boss_health_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boss_health_bar.offset_left = -300
	boss_health_bar.offset_right = 300
	boss_health_bar.offset_bottom = -40
	boss_health_bar.offset_top = -70
	boss_health_bar.show_percentage = false

	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color.BLACK
	sb_bg.border_width_left = 4
	sb_bg.border_width_right = 4
	sb_bg.border_width_top = 4
	sb_bg.border_width_bottom = 4
	sb_bg.border_color = Color(0.2, 0.0, 0.0, 1.0)
	sb_bg.anti_aliasing = false

	var sb_fg = StyleBoxFlat.new()
	sb_fg.bg_color = Color(0.8, 0.0, 0.0, 1.0)
	sb_fg.anti_aliasing = false

	boss_health_bar.add_theme_stylebox_override("background", sb_bg)
	boss_health_bar.add_theme_stylebox_override("fill", sb_fg)

	boss_name_label = Label.new()
	boss_name_label.text = "БОСС"
	boss_name_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_name_label.offset_left = -200
	boss_name_label.offset_right = 200
	boss_name_label.offset_top = -30
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_font_size_override("font_size", 22)
	boss_name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 2)

	boss_health_bar.add_child(boss_name_label)
	boss_health_bar.visible = false
	$CanvasLayer_UI / Control_OSD.add_child(boss_health_bar)

func _exit_tree():
	if skip_save_stats: return
	Global.player_health = current_health
	Global.player_mana = current_mana
	if active_model == pistol_node: Global.pistol_ammo = current_ammo
	elif active_model == rifle_node: Global.rifle_ammo = current_ammo
	elif active_model == shotgun_node: Global.shotgun_ammo = current_ammo

func toggle_inventory():
	is_inventory_open = !is_inventory_open
	if is_inventory_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().call_group("player_hud", "hide")
		var meta_panel = get_node_or_null("CanvasLayer_UI/FullMapOverlay")
		if meta_panel:
			meta_panel.show()
			if meta_panel.has_method("update_stats_data"): meta_panel.update_stats_data()
		if loadout_menu:
			loadout_menu.show()
			if loadout_menu.has_method("update_slots"): loadout_menu.update_slots()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().call_group("player_hud", "show")
		var meta_panel = get_node_or_null("CanvasLayer_UI/FullMapOverlay")
		if meta_panel: meta_panel.hide()
		if loadout_menu: loadout_menu.hide()

func _input(event):
	if Global.is_auto_test: return


	if listening_action != "" and event is InputEventKey:
		if event.pressed:
			var new_key: int = event.physical_keycode
			if new_key != KEY_ESCAPE:
				Global.keybinds[listening_action] = new_key
				Global.apply_keybinds()
				if Global.has_method("save_settings"): Global.save_settings()
			listening_button.text = "[ " + OS.get_keycode_string(Global.keybinds[listening_action] as int).to_upper() + " ]"
			listening_action = ""
			listening_button = null
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input += event.relative
		rotate_y( - event.relative.x * Global.mouse_sensitivity)
		camera_pitch -= event.relative.y * Global.mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		head.rotation.x = camera_pitch
		camera_tilt_target = clamp( - event.relative.x * 0.008, -0.08, 0.08)

	if event.is_action_pressed("inventory"):
		if not get_tree().paused: toggle_inventory()

	if is_inventory_open:
		if event.is_action_pressed("ui_cancel"): toggle_inventory()
		return

	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			if settings_panel and settings_panel.visible:
				close_settings()
			elif badtrip_pause_menu and badtrip_pause_menu.visible:
				_on_resume_pressed()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().paused = true
			if badtrip_pause_menu: badtrip_pause_menu.visible = true
			if settings_panel: settings_panel.visible = false
			get_tree().call_group("player_hud", "hide")

	if event.is_action_pressed("reload"): reload()
	if event.is_action_pressed("interact") and current_interactable:
		if current_interactable.has_method("interact"):
			current_interactable.interact(self)
	if event.is_action_pressed("shoot"):
		if not is_automatic: attempt_shoot()
	if event.is_action_pressed("inspect_weapon"): inspect_weapon()
	if event.is_action_pressed("kick") and kick_cooldown <= 0: perform_kick()

func perform_kick():
	kick_cooldown = KICK_COOLDOWN_TIME
	add_camera_trauma(0.3)
	target_fov_kick = KICK_FOV_KICK
	var random_tilt_dir = [-1.0, 1.0].pick_random()
	camera_tilt_target = random_tilt_dir * KICK_TILT_AMOUNT

	var space_state = get_world_3d().direct_space_state
	var forward_dir = - camera.global_transform.basis.z.normalized()

	var kick_shape = SphereShape3D.new()
	kick_shape.radius = 1.0

	var kick_pos = camera.global_position + (forward_dir * 1.5)
	kick_pos.y -= 0.4

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = kick_shape
	query.transform = Transform3D(Basis(), kick_pos)
	query.exclude = [self.get_rid()]

	var results = space_state.intersect_shape(query)
	var hit_something = false
	var enemies_hit = 0

	for result in results:
		var col = result.collider
		if col is RigidBody3D:
			var push_dir = global_position.direction_to(col.global_position)
			push_dir.y += 0.3
			push_dir = push_dir.normalized()

			var mass_factor = clamp(col.mass, 1.0, 30.0)
			var force_multiplier = 45.0 * mass_factor
			var melee_dmg = Global.melee_damage if Global.get("melee_damage") != null else 20.0
			var stat_multiplier = clamp(melee_dmg / 20.0, 1.0, 2.0)

			var final_impulse = push_dir * force_multiplier * stat_multiplier
			col.apply_central_impulse(final_impulse)
			col.angular_velocity = Vector3.ZERO
			col.apply_torque_impulse(Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * mass_factor)

			if col.has_method("get_kicked"): col.get_kicked(global_position, "player")
			hit_something = true

		elif (col.is_in_group("enemies") or col.is_in_group("boss")) and col.has_method("take_damage"):
			if enemies_hit >= 3: continue
			enemies_hit += 1

			var base_dmg = Global.melee_damage if Global.get("melee_damage") != null else 20.0
			var dmg = base_dmg * 0.3

			var push_dir = global_position.direction_to(col.global_position)
			push_dir.y = 0.3
			push_dir = push_dir.normalized()

			if col.is_in_group("boss"):
				col.take_damage(dmg, false, col.global_position, push_dir)
			else:
				col.take_damage(dmg, false, col.global_position, push_dir, null)

			if col is CharacterBody3D and not col.is_in_group("boss"):
				col.velocity += push_dir * 15.0
			hit_something = true

	if hit_something:
		var player_push_dir = forward_dir
		player_push_dir.y = 0
		velocity.x -= player_push_dir.x * 1.5
		velocity.z -= player_push_dir.z * 1.5

func _physics_process(delta):
	if kick_cooldown > 0: kick_cooldown -= delta

	if is_mantling:
		mantle_timer -= delta
		var progress = clamp(1.0 - (mantle_timer / mantle_duration), 0.0, 1.0)
		var up_pos = Vector3(mantle_start_pos.x, mantle_target_pos.y + 0.1, mantle_start_pos.z)
		var next_pos = Vector3.ZERO
		if progress < 0.5: next_pos = mantle_start_pos.lerp(up_pos, progress * 2.0)
		else: next_pos = up_pos.lerp(mantle_target_pos, (progress - 0.5) * 2.0)

		var motion = next_pos - global_position
		move_and_collide(motion)

		if mantle_timer <= 0:
			is_mantling = false
			velocity = Vector3.ZERO
		process_head_physics(delta)
		return

	var input_dir = Vector2.ZERO
	if Global.is_auto_test: input_dir = process_bot_logic(delta)
	else: input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var is_moving = direction.length() > 0.1

	if is_moving and not is_on_floor(): check_ledge_climb(direction)

	camera_tilt_target = lerp(camera_tilt_target, 0.0, delta * 8.0)

	if current_stamina <= 0.0: is_exhausted = true
	elif current_stamina >= max_stamina: is_exhausted = false

	if Input.is_action_just_pressed("sprint") and current_stamina > 0 and is_moving and not is_sliding and not is_exhausted:
		is_sprinting = not is_sprinting

	if not is_moving or current_stamina <= 0 or is_sliding or is_exhausted:
		is_sprinting = false

	if is_sprinting:
		current_stamina -= sprint_stamina_drain * delta
		current_stamina = max(0.0, current_stamina)
		stamina_drain_impact = max(stamina_drain_impact, 0.15)
	elif not is_sliding:
		current_stamina += stamina_recharge_rate * delta
		current_stamina = min(max_stamina, current_stamina)

	if Input.is_action_just_pressed("crouch") and is_on_floor() and not is_sliding and current_stamina >= slide_stamina_cost and horizontal_speed > 3.0 and not is_exhausted:
		current_stamina -= slide_stamina_cost
		stamina_drain_impact = 1.0

		if direction == Vector3.ZERO:
			direction = - camera.global_transform.basis.z
			direction.y = 0
			direction = direction.normalized()
		start_slide(direction)

	var current_max_speed = Global.get_final_speed(base_sprint_speed if is_sprinting else base_walk_speed)
	var fall_speed = prev_velocity_y

	if is_on_floor():
		coyote_time = 0.15
		if was_in_air:
			was_in_air = false
			var impact_intensity = clamp(abs(fall_speed) / 14.0, 0.0, 1.5)
			if impact_intensity > 0.1:
				target_landing_dip_pos = -0.9 * impact_intensity
				target_landing_dip_rot = deg_to_rad(-35.0) * impact_intensity
				add_camera_trauma(0.6 * impact_intensity)
				target_fov_kick -= 15.0 * impact_intensity

				if sound_walk:
					footstep_player.stream = sound_walk
					footstep_player.pitch_scale = randf_range(0.5, 0.6)
					footstep_player.volume_db = 4.0 * impact_intensity
					footstep_player.play()
			air_time = 0.0
	else:
		was_in_air = true
		air_time += delta
		coyote_time -= delta

	if Input.is_action_just_pressed("jump"): jump_buffer = 0.15

	if jump_buffer > 0:
		if is_on_floor() or coyote_time > 0:
			velocity.y = Global.get_final_jump(jump_velocity)
			jump_buffer = 0.0
			velocity.y = jump_velocity
			coyote_time = 0.0
			if is_sliding:
				stop_slide()
				var boost_dir = Vector3(velocity.x, 0, velocity.z).normalized()
				velocity.x += boost_dir.x * 3.0
				velocity.z += boost_dir.z * 3.0

	if jump_buffer > 0: jump_buffer -= delta

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0 or horizontal_speed < SLIDE_MIN_SPEED or not is_on_floor(): stop_slide()
		else:
			var friction_mult = 1.0 + (1.0 - (slide_timer / slide_duration)) * 2.0
			velocity.x = move_toward(velocity.x, 0.0, SLIDE_FRICTION * friction_mult * delta)
			velocity.z = move_toward(velocity.z, 0.0, SLIDE_FRICTION * friction_mult * delta)
			if direction:
				var steer_dir = (Vector3(velocity.x, 0, velocity.z).normalized() + direction * SLIDE_CONTROL * delta).normalized()
				var current_spd = Vector2(velocity.x, velocity.z).length()
				velocity.x = steer_dir.x * current_spd
				velocity.z = steer_dir.z * current_spd
	else:
		if is_on_floor():
			if direction != Vector3.ZERO:
				velocity.x = lerp(velocity.x, direction.x * current_max_speed, GROUND_ACCEL * delta)
				velocity.z = lerp(velocity.z, direction.z * current_max_speed, GROUND_ACCEL * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, GROUND_FRICTION * delta)
				velocity.z = lerp(velocity.z, 0.0, GROUND_FRICTION * delta)
		else:
			if direction != Vector3.ZERO:
				velocity.x = lerp(velocity.x, direction.x * current_max_speed, AIR_ACCEL * delta)
				velocity.z = lerp(velocity.z, direction.z * current_max_speed, AIR_ACCEL * delta)
			else:
				velocity.x = lerp(velocity.x, 0.0, (GROUND_FRICTION * 0.05) * delta)
				velocity.z = lerp(velocity.z, 0.0, (GROUND_FRICTION * 0.05) * delta)

	velocity.y -= GRAVITY * delta
	prev_velocity_y = velocity.y
	move_and_slide()

	process_head_physics(delta)
	process_dynamic_spread(delta)
	update_weapon_animations(is_moving)
	process_weapon_physics(delta)
	process_interaction()
	push_rigid_bodies()

	if has_baby_oil and is_on_floor() and horizontal_speed > 1.0:
		oil_timer -= delta
		if oil_timer <= 0:
			spawn_oil()
			oil_timer = 0.4

	if Global.soldering_iron_count > 0 and is_on_floor() and horizontal_speed > 1.0:
		fire_trail_timer -= delta
		if fire_trail_timer <= 0:
			spawn_fire_trail()
			fire_trail_timer = 0.3

func process_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if is_instance_valid(collider) and collider.is_in_group("interactable"):
			var distance = global_position.distance_to(collider.global_position)

			if distance <= INTERACT_DISTANCE:
				if current_interactable != collider:
					clear_interactable()
					current_interactable = collider
					if current_interactable.has_method("highlight"):
						current_interactable.highlight()
				return

	clear_interactable()

func clear_interactable():
	if current_interactable:
		if is_instance_valid(current_interactable):
			if current_interactable.has_method("unhighlight"):
				current_interactable.unhighlight()
		current_interactable = null

func update_weapon_animations(is_moving: bool):
	if not weapon_anim_player: return
	if is_reloading: return

	var curr_anim = weapon_anim_player.current_animation
	var is_empty = current_ammo <= 0
	var unskippable_anims = [
		"Pistol_FIRE", "Pistol_FIRE(magnum)", "Pistol_FIRE_EMPTY", "Pistol_RELOAD", 
		"Arms_Fire", "Arms_fullreload", "Arms_notfullreload", "Arms_Draw", "Arms_Inspect", 
		"RIG_UE5_Comando_Fire", "RIG_UE5_Comando_Reload", "RIG_UE5_Comando_Equip", "RIG_UE5_Comando_Hold"
	]
	if curr_anim in unskippable_anims:
		if weapon_anim_player.is_playing(): return

	var target_anim = ""
	if Global.current_weapon_type == "pistol":
		if not is_on_floor():
			if velocity.y > 0: target_anim = "Pistol_JUMP_START_EMPTY" if is_empty else "Pistol_JUMP_START"
			else: target_anim = "Pistol_JUMP_FALL_EMPTY" if is_empty else "Pistol_JUMP_FALL"
		else:
			if is_sprinting and is_moving: target_anim = "Pistol_RUN_EMPTY" if is_empty else "Pistol_RUN"
			elif is_moving: target_anim = "Pistol_WALK_EMPTY" if is_empty else "Pistol_WALK"
			else: target_anim = "Pistol_IDLE_EMPTY" if is_empty else "Pistol_IDLE"

	elif Global.current_weapon_type == "rifle":
		if not is_on_floor(): target_anim = "Arms_Idle"
		else:
			if is_sprinting and is_moving: target_anim = "Arms_Sprint" if weapon_anim_player.has_animation("Arms_Sprint") else "Arms_Run"
			elif is_moving: target_anim = "Arms_Walk"
			else: target_anim = "Arms_Idle"

	elif Global.current_weapon_type == "shotgun":
		if not is_on_floor(): target_anim = "RIG_UE5_Comando_Run"
		else:
			if is_sprinting and is_moving: target_anim = "RIG_UE5_Comando_Run"
			elif is_moving: target_anim = "RIG_UE5_Comando_Walk"
			else: target_anim = "RIG_UE5_Comando_Idle"

	if target_anim != "" and curr_anim != target_anim:
		if weapon_anim_player.has_animation(target_anim):
			weapon_anim_player.play(target_anim, 0.15)

func inspect_weapon():
	if not weapon_anim_player or is_reloading or current_fire_timer > 0: return
	if Global.current_weapon_type == "rifle" and weapon_anim_player.has_animation("Arms_Inspect"): weapon_anim_player.play("Arms_Inspect")
	elif Global.current_weapon_type == "shotgun" and weapon_anim_player.has_animation("RIG_UE5_Comando_Hold"): weapon_anim_player.play("RIG_UE5_Comando_Hold")

func process_bot_logic(delta) -> Vector2:
	if not bot_nav_agent:
		bot_nav_agent = NavigationAgent3D.new()
		bot_nav_agent.path_desired_distance = 1.5
		bot_nav_agent.target_desired_distance = 1.5
		add_child(bot_nav_agent)

		bot_ray_front = RayCast3D.new()
		bot_ray_front.target_position = Vector3(0, -0.2, -2.0)
		bot_ray_left = RayCast3D.new()
		bot_ray_left.target_position = Vector3(-1.5, -0.2, -1.0)
		bot_ray_right = RayCast3D.new()
		bot_ray_right.target_position = Vector3(1.5, -0.2, -1.0)
		head.add_child(bot_ray_front)
		head.add_child(bot_ray_left)
		head.add_child(bot_ray_right)

	var input = Vector2.ZERO
	if bot_reverse_timer > 0:
		bot_reverse_timer -= delta
		input.y = 1.0
		input.x = bot_strafe_dir
		bot_nav_agent.target_position = global_position
		bot_roam_timer = 0.0
		return input

	var obs_front = bot_ray_front.is_colliding() if bot_ray_front else false
	var obs_left = bot_ray_left.is_colliding() if bot_ray_left else false
	var obs_right = bot_ray_right.is_colliding() if bot_ray_right else false

	bot_target_refresh_timer -= delta
	var min_d = 25.0

	if bot_target_refresh_timer <= 0.0 or not is_instance_valid(cached_bot_target) or cached_bot_target.get("is_dead"):
		cached_bot_target = null
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and not e.get("is_dead"):
				var d = global_position.distance_to(e.global_position)
				if d < min_d:
					min_d = d
					cached_bot_target = e
		bot_target_refresh_timer = 0.5
	elif is_instance_valid(cached_bot_target):
		min_d = global_position.distance_to(cached_bot_target.global_position)

	if cached_bot_target:
		var target_pos = cached_bot_target.global_position + Vector3(0, 1.2, 0)
		var look_dir = (target_pos - global_position)
		look_dir.y = 0
		if look_dir.length_squared() > 0.01:
			look_dir = look_dir.normalized()
			var target_yaw = atan2( - look_dir.x, - look_dir.z)
			global_rotation.y = lerp_angle(global_rotation.y, target_yaw, delta * 15.0)

		var pitch_dir = (target_pos - head.global_position).normalized()
		head.rotation.x = lerp_angle(head.rotation.x, asin(pitch_dir.y), delta * 15.0)
		camera_pitch = head.rotation.x

		if not is_reloading: attempt_shoot()

		bot_strafe_timer -= delta
		if bot_strafe_timer <= 0:
			bot_strafe_dir = [-1.0, 1.0].pick_random()
			bot_strafe_timer = randf_range(0.5, 2.0)

		input.x = bot_strafe_dir
		if min_d < 5.0: input.y = 1.0
		elif min_d > 15.0: input.y = -1.0
	else:
		bot_roam_timer -= delta
		if bot_roam_timer <= 0 or bot_nav_agent.is_navigation_finished() or not bot_nav_agent.is_target_reachable():
			var found_interest = false
			var exits = get_tree().get_nodes_in_group("exit")
			var items = get_tree().get_nodes_in_group("items")

			if items.size() > 0:
				bot_nav_agent.target_position = items.pick_random().global_position
				found_interest = true
			elif exits.size() > 0:
				bot_nav_agent.target_position = exits[0].global_position
				found_interest = true

			if not found_interest:
				var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				var random_target = global_position + random_dir * 10.0
				var map_id = get_world_3d().navigation_map
				var valid_pos = NavigationServer3D.map_get_closest_point(map_id, random_target)
				bot_nav_agent.target_position = valid_pos

			bot_roam_timer = 4.0

		var next_pos = bot_nav_agent.get_next_path_position()
		var look_dir = (next_pos - global_position)
		look_dir.y = 0

		if obs_front:
			jump_buffer = 0.2
			if not obs_left:
				input.x = -1.0
				global_rotation.y += 3.0 * delta
			elif not obs_right:
				input.x = 1.0
				global_rotation.y -= 3.0 * delta
			else:
				input.y = 1.0
				global_rotation.y += 4.0 * delta
		else:
			if look_dir.length_squared() > 0.01:
				look_dir = look_dir.normalized()
				var target_yaw = atan2( - look_dir.x, - look_dir.z)
				global_rotation.y = lerp_angle(global_rotation.y, target_yaw, delta * 8.0)
			input.y = -1.0

		head.rotation.x = lerp_angle(head.rotation.x, 0.0, delta * 8.0)
		camera_pitch = head.rotation.x

	var dist_moved = global_position.distance_to(bot_last_pos)
	if dist_moved < 0.05 or (is_on_wall() and input.y < 0.0):
		bot_stuck_timer += delta
		if bot_stuck_timer > 0.6:
			jump_buffer = 0.2
			bot_reverse_timer = 1.5
			bot_strafe_dir = [-1.0, 1.0].pick_random()
			bot_stuck_timer = 0.0
	else:
		bot_stuck_timer = 0.0

	bot_last_pos = global_position
	return input

func check_ledge_climb(forward_dir: Vector3):
	if is_mantling or velocity.y > 0.0 or velocity.y < -15.0: return

	var space_state = get_world_3d().direct_space_state
	var chest_pos = global_position + Vector3(0, 1.2, 0)
	var wall_query = PhysicsRayQueryParameters3D.create(chest_pos, chest_pos + forward_dir * 0.8, 1)
	wall_query.exclude = [self.get_rid()]
	var wall_hit = space_state.intersect_ray(wall_query)

	if wall_hit:
		var col = wall_hit.collider
		if col is RigidBody3D or col.is_in_group("enemies") or col.is_in_group("player"): return
		if wall_hit.normal.y > 0.3: return

		var push_in_dir = - wall_hit.normal
		push_in_dir.y = 0
		push_in_dir = push_in_dir.normalized()
		var head_height = global_position.y + 2.2

		var depth = 0.4
		var top_check_start = wall_hit.position + (push_in_dir * depth)
		top_check_start.y = head_height
		var top_check_end = top_check_start + Vector3(0, -2.0, 0)
		var ledge_query = PhysicsRayQueryParameters3D.create(top_check_start, top_check_end, 1)
		ledge_query.exclude = [self.get_rid()]
		var ledge_hit = space_state.intersect_ray(ledge_query)

		if ledge_hit:
			var climb_height = ledge_hit.position.y - global_position.y
			if climb_height > 0.5 and climb_height < 2.0:
				var ceil_start = ledge_hit.position + Vector3(0, 0.1, 0)
				var ceil_end = ledge_hit.position + Vector3(0, 1.9, 0)
				var ceil_query = PhysicsRayQueryParameters3D.create(ceil_start, ceil_end, 1)
				ceil_query.exclude = [self.get_rid()]

				if not space_state.intersect_ray(ceil_query):
					is_mantling = true
					mantle_timer = mantle_duration
					mantle_start_pos = global_position
					mantle_target_pos = ledge_hit.position + Vector3(0, player_half_height + 0.1, 0) + (wall_hit.normal * 0.2)
					velocity = Vector3.ZERO

func start_slide(slide_dir: Vector3):
	is_sliding = true
	var current_speed = Vector2(velocity.x, velocity.z).length()
	slide_duration = clamp(current_speed * 0.07, 0.3, 0.8)
	slide_timer = slide_duration

	var base_boost = max(SLIDE_START_SPEED, current_speed * 1.4)
	var boost = base_boost * Global.speed_multiplier
	velocity.x = slide_dir.x * boost
	velocity.z = slide_dir.z * boost

	slide_tilt_dir = 1.0 if randf() > 0.5 else -1.0
	target_landing_dip_pos = -0.5
	target_fov_kick += 10.0
	add_camera_trauma(0.1)

func stop_slide():
	is_sliding = false

func process_head_physics(delta):
	var target_height = CAM_HEIGHT_SLIDING if is_sliding else CAM_HEIGHT_STANDING
	var smooth_speed = CAM_SMOOTH_SPEED * (2.0 if is_sliding else 1.0)

	target_landing_dip_pos = lerp(target_landing_dip_pos, 0.0, delta * 4.0)
	target_landing_dip_rot = lerp(target_landing_dip_rot, 0.0, delta * 4.0)

	landing_dip_pos = lerp(landing_dip_pos, target_landing_dip_pos, delta * 15.0)
	landing_dip_rot = lerp(landing_dip_rot, target_landing_dip_rot, delta * 12.0)

	target_height += landing_dip_pos

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var target_intensity = 1.0 if (is_on_floor() and not is_sliding and horizontal_speed > 1.0) else 0.0
	headbob_intensity = lerp(headbob_intensity, target_intensity, delta * 10.0)

	if headbob_intensity > 0.05:
		var step_rate = (horizontal_speed / base_walk_speed) * HEADBOB_FREQ_MULT
		t_bob += delta * step_rate
		if t_bob > last_step_time + PI:
			last_step_time += PI
			play_footstep()

		var amp = HEADBOB_SPRINT_AMP if is_sprinting else HEADBOB_WALK_AMP
		amp *= headbob_intensity

		bob_y = - abs(sin(t_bob)) * amp.y
		bob_x = cos(t_bob * 0.5) * amp.x
	else:
		last_step_time = 0.0
		bob_y = lerp(bob_y, 0.0, delta * 5.0)
		bob_x = lerp(bob_x, 0.0, delta * 5.0)
		if t_bob > 0:
			t_bob = wrapf(t_bob, 0, TAU)
		t_bob = lerp(t_bob, 0.0, delta * 5.0)

		if footstep_player and footstep_player.playing:
			footstep_player.stop()

	head.position.y = lerp(head.position.y, target_height + bob_y, delta * smooth_speed)
	head.position.x = lerp(head.position.x, bob_x, delta * smooth_speed)

	var target_tilt = 0.0
	if is_sliding:
		target_tilt = slide_tilt_dir * 0.15
	else:
		var local_vel = transform.basis.inverse() * velocity
		var speed_ratio = clamp(local_vel.x / base_sprint_speed, -1.0, 1.0)
		target_tilt = - speed_ratio * 0.035

	target_tilt += camera_tilt_target
	current_slide_tilt = lerp(current_slide_tilt, target_tilt, delta * 8.0)
	head.rotation.z = current_slide_tilt

	if not is_on_floor():
		target_jump_fall_tilt = clamp(velocity.y * 0.015, -0.2, 0.15)
	else:
		target_jump_fall_tilt = 0.0

	jump_fall_tilt = lerp(jump_fall_tilt, target_jump_fall_tilt, delta * 8.0)

	camera.rotation.x = cam_recoil_curr.x + deg_to_rad(shake_rot.x) + landing_dip_rot + jump_fall_tilt
	camera.rotation.y = cam_recoil_curr.y + deg_to_rad(shake_rot.y)
	camera.rotation.z = cam_recoil_curr.z + deg_to_rad(shake_rot.z)

func play_footstep():
	if Global.active_synergies.has("wheelchair"): return
	if not footstep_player: return
	if is_sprinting and sound_run:
		footstep_player.stream = sound_run
		footstep_player.pitch_scale = randf_range(0.85, 1.15)
		footstep_player.volume_db = randf_range(-5.0, -2.0)
	elif sound_walk:
		footstep_player.stream = sound_walk
		footstep_player.pitch_scale = randf_range(0.85, 1.15)
		footstep_player.volume_db = randf_range(-12.0, -8.0)
	footstep_player.play()

func process_fov(delta):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var speed_ratio = clamp(horizontal_speed / 15.0, 0.0, 1.0)

	target_fov_kick = lerp(target_fov_kick, 0.0, clamp(delta * 5.0, 0.0, 1.0))
	fov_kick = lerp(fov_kick, target_fov_kick, clamp(delta * 10.0, 0.0, 1.0))

	var target = default_fov + (speed_ratio * 18.0)
	var next_fov = lerp(camera.fov, target + fov_kick, clamp(delta * 12.0, 0.0, 1.0))

	camera.fov = clamp(next_fov, 10.0, 170.0)

func _process(delta):
	if Global.is_auto_test:
		auto_test_timer += delta
		if auto_test_timer > 60.0:
			take_damage(9999)
			return

	if Global.justice_hammer_count > 0:
		hammer_timer += delta
		if hammer_timer >= 15.0:
			hammer_timer -= 15.0
			if randf() < 0.1: trigger_justice_hammer()

	process_recoil_system(delta)
	process_shake(delta)
	process_fov(delta)
	process_weapon_physics(delta)
	update_boss_health_bar(delta)

	ecg_time += delta
	_update_ecg_visuals(delta)

	stamina_battery_time += delta
	_update_stamina_battery_visuals(delta)

	_update_market_visuals(delta)
	_update_ammo_visuals(delta)

	if damage_overlay:
		if current_health <= max_health * 0.3 and not is_dead:
			var pulse_speed = 5.0 + (1.0 - (current_health / (max_health * 0.3))) * 10.0
			var pulse = (sin(Time.get_ticks_msec() * 0.001 * pulse_speed) + 1.0) / 2.0
			var target_alpha = lerp(0.1, 0.35, pulse)
			damage_overlay.color = Color(0.8, 0.0, 0.0, target_alpha)
		else:
			if damage_overlay.color.a > 0.0:
				damage_overlay.color.a = move_toward(damage_overlay.color.a, 0.0, delta * 3.0)

	if is_automatic and Input.is_action_pressed("shoot") and not is_inventory_open:
		attempt_shoot()

	if current_fire_timer > 0:
		current_fire_timer -= delta

func update_boss_health_bar(delta):
	if not boss_health_bar: return

	if not is_instance_valid(active_boss_ref) or active_boss_ref.get("is_dead") or not active_boss_ref.visible:
		active_boss_ref = null
		boss_health_bar.visible = false

		var bosses = get_tree().get_nodes_in_group("boss")
		for b in bosses:
			if is_instance_valid(b) and "max_health" in b and not b.get("is_dead") and b.visible:
				active_boss_ref = b
				break

		if not active_boss_ref:
			return

	if not boss_health_bar.visible: boss_health_bar.visible = true
	boss_health_bar.max_value = active_boss_ref.max_health
	boss_health_bar.value = lerp(boss_health_bar.value, float(active_boss_ref.current_health), 10.0 * delta)

func add_camera_trauma(amount: float): trauma = clamp(trauma + amount, 0.0, 1.0)

func process_shake(delta: float):
	if trauma > 0:
		trauma = clamp(trauma - trauma_decay * delta, 0.0, 1.0)
		var shake_amount = trauma * trauma
		noise_time += delta * 40.0
		shake_rot.x = noise.get_noise_2d(noise_time, 0) * max_x_angle * shake_amount
		shake_rot.y = noise.get_noise_2d(0, noise_time) * max_y_angle * shake_amount
		shake_rot.z = noise.get_noise_2d(noise_time, noise_time) * max_z_angle * shake_amount
	else: shake_rot = Vector3.ZERO

func process_weapon_physics(delta):
	if not weapons_container: return

	var sway_target_rot = Vector3(mouse_input.y * 0.08, mouse_input.x * 0.08, - mouse_input.x * 0.06)
	var sway_target_pos = Vector3( - mouse_input.x * 0.0005, mouse_input.y * 0.0005, 0.0)

	sway_target_rot.x = clamp(sway_target_rot.x, -5.0, 5.0)
	sway_target_rot.y = clamp(sway_target_rot.y, -5.0, 5.0)
	sway_target_rot.z = clamp(sway_target_rot.z, -5.0, 5.0)

	sway_pos = sway_pos.lerp(sway_target_pos, 10.0 * delta)
	sway_rot = sway_rot.lerp(sway_target_rot, 12.0 * delta)

	var local_vel = transform.basis.inverse() * velocity
	var strafe_tilt = (local_vel.x / base_sprint_speed) * 4.0

	var target_state_rot = Vector3(0, 0, - strafe_tilt)
	var target_state_pos = Vector3.ZERO

	var is_pistol = (Global.current_weapon_type == "pistol")
	if is_sliding:
		target_state_pos = Vector3(0.0, -0.05, 0.05)
		target_state_rot += Vector3(10.0, 0.0, slide_tilt_dir * 15.0)
	elif is_sprinting:
		if is_pistol:
			target_state_pos = Vector3(0.0, 0.02, 0.02)
			target_state_rot += Vector3(20.0, 5.0, -5.0)
		else:
			target_state_pos = Vector3(0.05, 0.02, 0.03)
			target_state_rot += Vector3(-15.0, 15.0, -5.0)

	current_state_pos_offset = current_state_pos_offset.lerp(target_state_pos, delta * 10.0)
	current_state_rot_offset = current_state_rot_offset.lerp(target_state_rot, delta * 10.0)

	var fire_penalty = 1.0
	if current_fire_timer > 0 or is_reloading: fire_penalty = 0.1

	weapon_bob_weight = lerp(weapon_bob_weight, fire_penalty, delta * 15.0)

	var b_time = Time.get_ticks_msec() * 0.001
	var w_bob_pos = Vector3.ZERO
	var w_bob_rot = Vector3.ZERO

	if headbob_intensity > 0.01:
		var bob_amp = (0.01 if is_sprinting else 0.005) * headbob_intensity * weapon_bob_weight
		var bob_amp_rot = (1.5 if is_sprinting else 0.8) * headbob_intensity * weapon_bob_weight
		w_bob_pos.x = cos(t_bob * 0.5) * bob_amp
		w_bob_pos.y = sin(t_bob) * bob_amp
		w_bob_rot.z = cos(t_bob * 0.5) * bob_amp_rot
		w_bob_rot.x = abs(sin(t_bob)) * bob_amp_rot
		w_bob_rot.y = sin(t_bob * 0.5) * bob_amp_rot
	else:
		w_bob_pos = Vector3(cos(b_time * 1.5) * 0.002, sin(b_time * 3.0) * 0.002, 0) * weapon_bob_weight
		w_bob_rot = Vector3(sin(b_time * 3.0) * 0.4, cos(b_time * 1.5) * 0.2, 0) * weapon_bob_weight

	recoil_pos_curr = recoil_pos_curr.lerp(recoil_pos_target, recoil_snap * delta)
	recoil_rot_curr = recoil_rot_curr.lerp(recoil_rot_target, recoil_snap * delta)
	recoil_pos_target = recoil_pos_target.lerp(Vector3.ZERO, recoil_return * delta)
	recoil_rot_target = recoil_rot_target.lerp(Vector3.ZERO, recoil_return * delta)

	var weapon_fall_lag = Vector3(0, jump_fall_tilt * 0.2, 0)
	var final_pos = current_state_pos_offset + sway_pos + w_bob_pos + recoil_pos_curr + weapon_fall_lag
	var final_rot = current_state_rot_offset + sway_rot + w_bob_rot + recoil_rot_curr

	weapons_container.position = weapons_container.position.lerp(final_pos, 15.0 * delta)
	weapons_container.rotation_degrees = weapons_container.rotation_degrees.lerp(final_rot, 15.0 * delta)
	mouse_input = mouse_input.lerp(Vector2.ZERO, 15.0 * delta)

func process_dynamic_spread(delta):
	var actual_base_spread = base_spread * Global.spread_multiplier
	var target_spread = actual_base_spread
	if velocity.length() > 0.1: target_spread += actual_base_spread * move_spread_factor
	if not is_on_floor(): target_spread += actual_base_spread * jump_spread_factor

	var actual_max_spread = max_spread_limit * Global.spread_multiplier
	current_spread = lerp(current_spread, target_spread, spread_recovery * delta)
	current_spread = clamp(current_spread, actual_base_spread, actual_max_spread)
	emit_signal("spread_changed", current_spread)

func process_recoil_system(delta):
	if cam_recoil_target.length_squared() > 0.0001:
		var step = cam_recoil_target * 12.0 * delta
		camera_pitch += step.x
		camera_pitch = clamp(camera_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		head.rotation.x = camera_pitch
		rotation.y += step.y
		cam_recoil_target -= step
		cam_recoil_curr.z = lerp(cam_recoil_curr.z, step.z * 10.0, 15.0 * delta)
	else:
		cam_recoil_curr.z = lerp(cam_recoil_curr.z, 0.0, 8.0 * delta)

func add_recoil_punch():
	var r_mult = Global.recoil_multiplier
	var is_pistol = (Global.current_weapon_type == "pistol")
	var is_shotgun = (Global.current_weapon_type == "shotgun")

	var kick_z = 0.15 if is_pistol else 0.1
	var kick_rot_x = 35.0 if is_pistol else 20.0
	if is_shotgun:
		kick_z = 0.3
		kick_rot_x = 55.0

	recoil_pos_target += Vector3(0.0, 0.01, kick_z) * r_mult
	recoil_rot_target += Vector3(kick_rot_x, randf_range(-5.0, 5.0), randf_range(-4.0, 4.0)) * r_mult

	var cam_kick_up = randf_range(0.04, 0.06) if is_pistol else randf_range(0.03, 0.05)
	if is_shotgun: cam_kick_up = randf_range(0.12, 0.18)

	var cam_kick_side = randf_range(-0.015, 0.015)
	var cam_kick_roll = randf_range(-0.02, 0.02)

	cam_recoil_target += Vector3(cam_kick_up, cam_kick_side, cam_kick_roll) * r_mult

	recoil_pos_target.z = clamp(recoil_pos_target.z, 0.0, MAX_RECOIL_POS_Z * r_mult)
	recoil_rot_target.x = clamp(recoil_rot_target.x, 0.0, MAX_RECOIL_ROT_X * r_mult)

func attempt_shoot():
	if is_reloading:
		if Global.current_weapon_type == "shotgun" and current_ammo > 0: is_reloading = false
		else: return

	if current_fire_timer > 0: return
	if current_ammo <= 0:
		reload()
		return

	is_sprinting = false
	current_fire_timer = Global.get_final_fire_rate(base_weapon_fire_rate)
	shoot()

func shoot():
	current_ammo -= 1
	ammo_shake_impact = 1.0
	update_ammo_ui()
	current_spread += (fire_spread_increment * Global.spread_multiplier)
	add_camera_trauma(0.12 * Global.recoil_multiplier)
	target_fov_kick = 4.0

	get_tree().call_group("enemies", "investigate_sound", global_position)

	if gun_sound:
		gun_sound.volume_db = randf_range(-14.0, -10.0)
		gun_sound.pitch_scale = randf_range(0.9, 1.1)
		gun_sound.play()

	if weapon_anim_player:
		var anim_to_play = ""
		if Global.current_weapon_type == "pistol": anim_to_play = "Pistol_FIRE_EMPTY" if current_ammo <= 0 else "Pistol_FIRE"
		elif Global.current_weapon_type == "rifle": anim_to_play = "Arms_Fire"
		elif Global.current_weapon_type == "shotgun": anim_to_play = "RIG_UE5_Comando_Fire"

		if weapon_anim_player.has_animation(anim_to_play):
			weapon_anim_player.stop(true)
			weapon_anim_player.play(anim_to_play, 0.1)

	add_recoil_punch()

	var weapon_data = Global.weapons_db[Global.current_weapon_type]
	var bullets_to_fire = weapon_data.get("pellets", 1)


	if Global.buyanov_desync:
		await get_tree().create_timer(randf_range(0.1, 0.25)).timeout
		if not is_inside_tree(): return

	for i in range(bullets_to_fire): fire_projectile()

func fire_projectile():
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.global_position
	var ray_dir = - camera.global_transform.basis.z.normalized()

	var weapon_data = Global.weapons_db[Global.current_weapon_type]
	var base_weapon_spread = weapon_data.get("spread", 0.0)
	var final_spread_angle = current_spread + base_weapon_spread


	if Global.active_synergies.has("wheelchair"): final_spread_angle = 0.0

	var final_dir = ray_dir
	if final_spread_angle > 0.0:
		var right = camera.global_transform.basis.x.normalized()
		var up = camera.global_transform.basis.y.normalized()
		var spread_radius = sqrt(randf()) * final_spread_angle
		var angle = randf() * TAU
		var offset_x = cos(angle) * spread_radius
		var offset_y = sin(angle) * spread_radius
		final_dir = (ray_dir + right * offset_x + up * offset_y).normalized()

	var ray_end = ray_origin + final_dir * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self.get_rid()]
	query.collision_mask = 5
	var result = space_state.intersect_ray(query)

	spawn_muzzle_flash()


	var final_damage = Global.get_final_phys_damage(damage)


	var proc_count = 0
	if Global.plunger_chance > 0 and randf() < Global.plunger_chance: proc_count += 1
	if Global.bleed_chance > 0 and randf() < Global.bleed_chance: proc_count += 1
	if Global.shishkin_chance > 0 and randf() < Global.shishkin_chance: proc_count += 1
	if Global.natalia_iron_chance > 0 and randf() < Global.natalia_iron_chance: proc_count += 1
	if Global.bread_chance > 0 and randf() < Global.bread_chance: proc_count += 1

	var is_glitch_shot = false
	if proc_count >= 3:
		is_glitch_shot = true
		final_damage *= 5.0
		add_camera_trauma(0.8)
		if damage_overlay: damage_overlay.color = Color(1, 1, 1, 0.8)

	if result:
		var col = result.collider
		var hit_pos = result.position
		var hit_normal = result.normal
		var actual_target = col
		var hit_bone_name = ""
		var hit_bone_node = null

		if col is PhysicalBone3D:
			hit_bone_name = col.name
			hit_bone_node = col
			actual_target = col
			while actual_target and not actual_target.has_method("take_damage"):
				actual_target = actual_target.get_parent()
			if not actual_target: actual_target = col

		var is_enemy = false
		if actual_target.is_in_group("enemies") or actual_target.is_in_group("boss") or (actual_target.has_method("take_damage") and not actual_target is RigidBody3D):
			is_enemy = true

		if is_enemy:
			var lethal_shishkin = false

			if not is_glitch_shot and Global.shishkin_chance > 0 and randf() < Global.shishkin_chance and not actual_target.is_in_group("boss"):
				var target_e = null
				var min_d = INF
				for e in Global.active_enemies:
					if is_instance_valid(e) and e != actual_target and not e.get("is_dead"):
						var d = actual_target.global_position.distance_to(e.global_position)
						if d < 30.0 and d < min_d: min_d = d;target_e = e
				if target_e and actual_target.has_method("apply_shishkin_launch"):
					actual_target.apply_shishkin_launch(target_e)
					lethal_shishkin = true

			if not lethal_shishkin and actual_target.has_method("take_damage"):
				var is_crit = randf() < Global.crit_chance
				if "Head" in hit_bone_name or "Neck" in hit_bone_name: is_crit = true
				if is_crit: final_damage *= Global.crit_damage_mult


				if Global.whip_count > 0: final_damage *= 1.3

				var is_headshot = false
				if actual_target.is_in_group("boss"):
					is_headshot = actual_target.take_damage(final_damage, is_crit, hit_pos, final_dir)
				else:
					is_headshot = actual_target.take_damage(final_damage, is_crit, hit_pos, final_dir, hit_bone_node)

				if "Head" in hit_bone_name or "Neck" in hit_bone_name: is_headshot = true
				emit_signal("on_hit", is_headshot)

				var is_heavy = (Global.current_weapon_type == "shotgun")
				spawn_blood_at(hit_pos, is_heavy)

				if hitmarker_player and sound_hitmarker:
					hitmarker_player.stream = sound_hitmarker
					hitmarker_player.pitch_scale = randf_range(0.9, 1.1)
					hitmarker_player.play()


				if not is_glitch_shot:
					if Global.plunger_chance > 0 and randf() < Global.plunger_chance:
						if "stun_timer" in actual_target: actual_target.stun_timer = max(actual_target.stun_timer, 0.5)
						spawn_visual_plunger(hit_pos, hit_normal, actual_target)

					if Global.bleed_chance > 0 and randf() < Global.bleed_chance:
						if actual_target.has_method("apply_bleed"): actual_target.apply_bleed(actual_target.max_health * 0.02 if "max_health" in actual_target else 2.0, 2.0)

					if Global.natalia_iron_chance > 0 and randf() < Global.natalia_iron_chance:
						spawn_natalia_black_hole(hit_pos)

					if Global.bread_chance > 0 and randf() < Global.bread_chance:
						if actual_target.has_method("apply_bread_taunt"): actual_target.apply_bread_taunt()

		elif col is RigidBody3D:
			spawn_hole(hit_pos, hit_normal)
			spawn_hit_sparks(hit_pos, hit_normal)
			var impact_force = damage * 1.5 * Global.phys_damage_multiplier
			col.apply_impulse(final_dir * impact_force, hit_pos - col.global_position)
			if col.has_method("take_damage"): col.take_damage(final_damage, false, hit_pos, final_dir)
		else:
			if col.has_method("take_damage"): col.take_damage(final_damage, false, hit_pos, ray_dir)
			spawn_hole(hit_pos, hit_normal)
			spawn_hit_sparks(hit_pos, hit_normal)

func reload():
	if is_reloading or current_ammo == max_ammo: return
	is_reloading = true

	recoil_rot_target.x = -5.0
	recoil_rot_target.z = 3.0
	var rel_speed = Global.get("reload_speed_multiplier") if Global.get("reload_speed_multiplier") != null else 1.0

	if Global.current_weapon_type == "shotgun":
		var anim_name = "RIG_UE5_Comando_Reload"
		if weapon_anim_player: weapon_anim_player.speed_scale = rel_speed
		_shotgun_reload_loop(anim_name, rel_speed)
	else:
		var anim_length = 1.5
		var anim_name = "Pistol_RELOAD" if Global.current_weapon_type == "pistol" else ("Arms_fullreload" if current_ammo == 0 else "Arms_notfullreload")

		if weapon_anim_player and weapon_anim_player.has_animation(anim_name):
			weapon_anim_player.speed_scale = rel_speed
			weapon_anim_player.stop(true)
			weapon_anim_player.play(anim_name, 0.15)
			anim_length = weapon_anim_player.get_animation(anim_name).length / rel_speed

		if reload_sound: reload_sound.play()

		await get_tree().create_timer(anim_length, false).timeout
		if not is_inside_tree() or not is_reloading: return

		if weapon_anim_player: weapon_anim_player.speed_scale = 1.0
		current_ammo = max_ammo
		is_reloading = false
		ammo_shake_impact = 0.5
		update_ammo_ui()

func _shotgun_reload_loop(anim_name: String, rel_speed: float):
	var loop_start = 0.5
	var loop_end = 1.3

	if weapon_anim_player and weapon_anim_player.has_animation(anim_name):
		weapon_anim_player.stop(true)
		weapon_anim_player.play(anim_name, 0.15)

	if reload_sound:
		reload_sound.pitch_scale = randf_range(0.95, 1.05)
		reload_sound.play()

	var wait_time = loop_end / rel_speed
	await get_tree().create_timer(wait_time, false).timeout
	if not is_inside_tree() or not is_reloading: return

	current_ammo += 1
	ammo_shake_impact = 0.5
	update_ammo_ui()
	add_camera_trauma(0.1)
	recoil_rot_target.x -= 2.0
	target_fov_kick = 1.0

	while current_ammo < max_ammo and is_reloading:
		if weapon_anim_player:
			weapon_anim_player.stop(true)
			weapon_anim_player.play(anim_name, 0.15)
			weapon_anim_player.seek(loop_start)

		if reload_sound:
			reload_sound.pitch_scale = randf_range(0.92, 1.08)
			reload_sound.play()

		var loop_duration = (loop_end - loop_start) / rel_speed
		await get_tree().create_timer(loop_duration, false).timeout
		if not is_inside_tree() or not is_reloading: break

		current_ammo += 1
		ammo_shake_impact = 0.5
		update_ammo_ui()
		add_camera_trauma(0.12)
		recoil_rot_target.x -= 2.5
		recoil_rot_target.z = randf_range(-1.5, 1.5)
		target_fov_kick = 1.0

	if is_reloading and weapon_anim_player and weapon_anim_player.has_animation(anim_name):
		var anim_length = weapon_anim_player.get_animation(anim_name).length
		var remaining_time = (anim_length - loop_end) / rel_speed

		add_camera_trauma(0.25)
		recoil_rot_target.x += 6.0
		target_fov_kick = -2.0

		await get_tree().create_timer(remaining_time, false).timeout

	if not is_inside_tree(): return
	if weapon_anim_player: weapon_anim_player.speed_scale = 1.0
	is_reloading = false

func spawn_muzzle_flash():
	if not active_model: return
	var side_mat = ShaderMaterial.new()
	if muzzle_side_shader: side_mat.shader = muzzle_side_shader
	var face_mat = ShaderMaterial.new()
	if muzzle_face_shader: face_mat.shader = muzzle_face_shader

	var flash_root = Node3D.new()
	var side_mesh_inst = MeshInstance3D.new()
	var side_quad = QuadMesh.new()
	side_quad.size = Vector2(0.6, 0.6)
	side_mesh_inst.mesh = side_quad
	side_mesh_inst.material_override = side_mat
	flash_root.add_child(side_mesh_inst)

	var face_mesh_inst = MeshInstance3D.new()
	var face_quad = QuadMesh.new()
	face_quad.size = Vector2(0.6, 0.6)
	face_mesh_inst.mesh = face_quad
	face_mesh_inst.material_override = face_mat
	face_mesh_inst.rotation_degrees.y = 90
	flash_root.add_child(face_mesh_inst)

	var muzzle_point = active_model.get_node_or_null("Muzzle")
	if muzzle_point:
		muzzle_point.add_child(flash_root)
		flash_root.position = Vector3.ZERO
	else:
		active_model.add_child(flash_root)
		if Global.current_weapon_type == "pistol": flash_root.position = Vector3(0.0, 0.06, -0.55)
		else: flash_root.position = Vector3(0.0, 0.08, -0.85)

	var rand_s = randf_range(0.8, 1.2)
	flash_root.scale = Vector3(rand_s, rand_s, rand_s)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.1)
	light.light_energy = 5.0
	light.omni_range = 6.0
	light.shadow_enabled = false
	flash_root.add_child(light)

	var tween = get_tree().create_tween().bind_node(flash_root)
	tween.set_parallel(true)
	tween.tween_property(flash_root, "scale", Vector3.ZERO, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(light, "light_energy", 0.0, 0.08)
	tween.tween_method( func(val):
		if is_instance_valid(side_mat): side_mat.set_shader_parameter("opacity", val)
		if is_instance_valid(face_mat): face_mat.set_shader_parameter("opacity", val)
	, 1.0, 0.0, 0.08)
	tween.chain().tween_callback(flash_root.queue_free)

func spawn_hit_sparks(pos: Vector3, normal: Vector3):
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	if not Global.get("_pools") or not Global._pools.has("hit_sparks_scene"): return

	var p = Global.spawn_from_pool("sparks", Global._pools["hit_sparks_scene"], pos + (normal * 0.05), root)
	if p is GPUParticles3D:
		var process_mat = p.process_material as ParticleProcessMaterial
		if process_mat: process_mat.direction = normal
		p.restart()
		p.emitting = true

		var timer = p.get_node_or_null("DespawnTimer")
		if not timer:
			timer = Timer.new()
			timer.name = "DespawnTimer"
			timer.one_shot = true
			p.add_child(timer)
			timer.timeout.connect( func(): Global.despawn_to_pool(p))
		timer.start(0.4)

func spawn_blood_at(pos: Vector3, is_heavy_hit: bool):
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()


	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(pos, pos + Vector3(0, -5.0, 0))
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)

	if result and result.collider is StaticBody3D:
		if not cached_blood_pool_mat:
			var shader = Shader.new()
			shader.code = "\n\t\t\tshader_type spatial;\n\t\t\trender_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, depth_test_disabled;\n\n\t\t\tuniform vec3 blood_color : source_color = vec3(0.4, 0.01, 0.01);\n\t\t\tuniform float growth : hint_range(0.0, 1.0) = 0.0;\n\t\t\tuniform float seed = 0.0;\n\n\t\t\tfloat hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }\n\t\t\tfloat noise(vec2 p) {\n\t\t\t\tvec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);\n\t\t\t\treturn mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),\n\t\t\t\t\t\t   mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);\n\t\t\t}\n\t\t\tvoid fragment() {\n\t\t\t\tvec2 uv = UV * 2.0 - 1.0;\n\t\t\t\tfloat dist = length(uv);\n\t\t\t\tfloat n = noise(uv * 3.0 + vec2(seed)) * 0.4;\n\t\t\t\tfloat blob = dist + n;\n\t\t\t\tfloat edge = 1.0 - growth;\n\t\t\t\tfloat alpha = smoothstep(edge + 0.05, edge - 0.05, blob);\n\t\t\t\tALBEDO = blood_color;\n\t\t\t\tROUGHNESS = 0.05; // Свежая влажная кровь\n\t\t\t\tMETALLIC = 0.2;\n\t\t\t\tALPHA = clamp(alpha, 0.0, 1.0);\n\t\t\t}\n\t\t\t"


























			cached_blood_pool_mat = ShaderMaterial.new()
			cached_blood_pool_mat.shader = shader

		var pool_mesh = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(2.5, 2.5)
		pool_mesh.mesh = plane

		var mat = cached_blood_pool_mat.duplicate()
		mat.set_shader_parameter("seed", randf_range(0.0, 100.0))
		mat.set_shader_parameter("growth", 0.0)
		pool_mesh.material_override = mat

		root.add_child(pool_mesh)


		pool_mesh.global_position = result.position + result.normal * 0.01
		if not result.normal.is_equal_approx(Vector3.UP) and not result.normal.is_equal_approx(Vector3.DOWN):
			pool_mesh.quaternion = Quaternion(Vector3.UP, result.normal)
		pool_mesh.rotate_object_local(Vector3.UP, randf() * TAU)

		var target_growth = randf_range(0.4, 0.6)
		if is_heavy_hit: target_growth = randf_range(0.7, 0.9)

		var tween = get_tree().create_tween()
		tween.tween_method( func(val):
			if is_instance_valid(mat): mat.set_shader_parameter("growth", val)
		, 0.0, target_growth, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


		tween.tween_interval(10.0)
		tween.tween_method( func(val):
			if is_instance_valid(mat): mat.set_shader_parameter("growth", val)
		, target_growth, 0.0, 3.0)
		tween.chain().tween_callback(pool_mesh.queue_free)

func spawn_hole(pos, norm):
	if not hole_scene: return
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	var h = Global.spawn_from_pool("bullet_holes", hole_scene, pos, root)

	if h and is_instance_valid(h):
		h.global_position = pos + (norm * 0.02)
		var up_vec = Vector3.RIGHT if abs(norm.y) > 0.999 else Vector3.UP
		if norm.length_squared() > 0.001:
			h.look_at(h.global_position + norm, up_vec)

		var timer = h.get_node_or_null("DespawnTimer")
		if not timer:
			timer = Timer.new()
			timer.name = "DespawnTimer"
			timer.one_shot = true
			h.add_child(timer)
			timer.timeout.connect( func(): Global.despawn_to_pool(h))
		timer.start(10.0)

func take_damage(amt, _source_name: String = "Unknown Enemy", source_node: Node3D = null):
	if has_meta("god_mode") and get_meta("god_mode"): return

	var damage_reduction = 100.0 / (100.0 + Global.armor)
	var final_received_damage = amt * damage_reduction
	current_health -= final_received_damage


	if current_health > 0.0 and current_health <= 0.2:
		current_health = 0.0

	Global.trigger_diary_effect()
	add_camera_trauma(0.5)


	if Global.thorns_damage_mult > 0.0 and is_instance_valid(source_node) and source_node.has_method("take_damage"):
		source_node.take_damage(amt * Global.thorns_damage_mult, false, global_position, global_position.direction_to(source_node.global_position))


	if Global.playboy_chance > 0 and randf() < Global.playboy_chance:
		get_tree().call_group("enemies", "apply_stun", 3.0)
		show_notification("ПЛЕЙБОЙ: ВРАГИ ОТВЛЕЧЕНЫ!", Color.PINK)

	ecg_damage_impact = 1.0

	if damage_overlay:
		damage_overlay.color = Color(0.8, 0.0, 0.0, 0.45)
	update_health_ui()

	if current_health <= 0 and not is_dead:
		is_dead = true
		skip_save_stats = true
		Global.convert_score_to_crystals()
		Global.player_health = -1.0
		Global.pistol_ammo = 15
		Global.rifle_ammo = 40
		Global.shotgun_ammo = 8
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/game_over_screen.tscn")

func setup_weapon(w_name):
	is_reloading = false
	if active_model != null:
		if active_model == pistol_node:
			Global.pistol_ammo = current_ammo
		elif active_model == rifle_node:
			Global.rifle_ammo = current_ammo
		elif active_model == shotgun_node:
			Global.shotgun_ammo = current_ammo

	pistol_node.visible = false
	rifle_node.visible = false
	if shotgun_node:
		shotgun_node.visible = false

	for child in weapons_container.get_children():
		if child is Node3D and child.name not in ["Pistol", "Rifle", "Shotgun"]:
			child.visible = false

	var mag_mult = Global.get("magazine_size_multiplier") if Global.get("magazine_size_multiplier") != null else 1.0

	match w_name:
		"pistol":
			active_model = weapons_container.get_node_or_null("Pistol") if weapons_container.has_node("Pistol") else pistol_node
			active_model.visible = true
			damage = 12
			base_weapon_fire_rate = 0.25
			is_automatic = false
			max_ammo = int(15 * mag_mult)
			base_spread = 0.02
			fire_spread_increment = 0.03
			current_ammo = min(Global.pistol_ammo, max_ammo) if Global.get("pistol_ammo") != null else max_ammo
		"rifle":
			active_model = weapons_container.get_node_or_null("Rifle") if weapons_container.has_node("Rifle") else rifle_node
			active_model.visible = true
			damage = 7
			base_weapon_fire_rate = 0.12
			is_automatic = true
			max_ammo = int(40 * mag_mult)
			base_spread = 0.03
			fire_spread_increment = 0.025
			current_ammo = min(Global.rifle_ammo, max_ammo) if Global.get("rifle_ammo") != null else max_ammo
		"shotgun":
			active_model = weapons_container.get_node_or_null("Shotgun") if weapons_container.has_node("Shotgun") else shotgun_node
			if active_model:
				active_model.visible = true
			var w_data = Global.weapons_db.get("shotgun", {})
			damage = w_data.get("dmg", 10)
			base_weapon_fire_rate = w_data.get("fire_rate", 1.0)
			is_automatic = false
			max_ammo = int(w_data.get("ammo", 8) * mag_mult)
			base_spread = 0.02
			fire_spread_increment = 0.08
			current_ammo = min(Global.shotgun_ammo, max_ammo) if Global.get("shotgun_ammo") != null else max_ammo

	if active_model:
		weapon_anim_player = active_model.find_child("AnimationPlayer*", true, false) as AnimationPlayer
		var draw_anim = "Arms_Draw" if w_name == "rifle" else "RIG_UE5_Comando_Equip" if w_name == "shotgun" else ""
		if weapon_anim_player and draw_anim != "" and weapon_anim_player.has_animation(draw_anim):
			weapon_anim_player.play(draw_anim)

	current_state_pos_offset = Vector3.ZERO
	current_state_rot_offset = Vector3.ZERO
	Global.current_weapon_type = w_name
	Global.save_game()
	update_ammo_ui()

func update_panties_aura():
	if Global.panties_count > 0 and not panties_aura_mesh:
		panties_aura_mesh = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 7.8
		torus.outer_radius = 8.0
		panties_aura_mesh.mesh = torus

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.8, 0.2, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.6, 0.1)
		torus.surface_set_material(0, mat)

		add_child(panties_aura_mesh)
		panties_aura_mesh.position.y = -0.9

func add_item(item_name: String):
	if Global.has_method("add_item"):
		Global.add_item(item_name)

	if item_name == "baby_oil":
		has_baby_oil = true

	var readable_name = item_names_ru.get(item_name, item_name.capitalize())
	var text_color = Color(0.2, 1.0, 0.2)

	if item_name == "baby_oil": text_color = Color.YELLOW
	elif item_name == "mge_photo": text_color = Color.ORANGE
	elif item_name == "chingis_eggs": text_color = Color(1.0, 0.8, 0.0)
	elif item_name == "plunger": text_color = Color(1.0, 0.2, 0.2)
	elif item_name == "maduro_drink": text_color = Color(0.0, 0.8, 1.0)
	elif item_name == "diary": text_color = Color(0.8, 0.2, 1.0)
	elif item_name == "nails": text_color = Color(0.7, 0.7, 0.7)
	elif item_name == "medpolis": text_color = Color(1.0, 0.4, 0.4)
	elif item_name == "rubiks_cube": text_color = Color(0.9, 0.3, 0.9)
	elif item_name == "gold_chain": text_color = Color(1.0, 0.84, 0.0)
	elif item_name == "lightbulb": text_color = Color(1.0, 1.0, 0.6)
	elif item_name == "shishkin": text_color = Color(0.8, 0.1, 0.1)
	elif item_name == "panties": text_color = Color(0.5, 0.8, 0.2)
	elif item_name == "cologne": text_color = Color(1.0, 0.4, 0.8)
	elif item_name == "xbox_gamepad": text_color = Color(0.0, 0.8, 0.2)
	elif item_name == "ps_gamepad": text_color = Color(0.2, 0.4, 1.0)
	elif item_name == "huy_yogurt": text_color = Color(0.0, 0.6, 1.0)
	elif item_name == "soldering_iron": text_color = Color(1.0, 0.4, 0.0)

	show_notification("ПОДОБРАНО: " + readable_name, text_color)
	recalculate_stats()

func show_notification(text: String, color: Color = Color.WHITE):
	if not notification_box: return

	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = color
	style.anti_aliasing = false
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var label = Label.new()
	label.text = "> " + text
	label.uppercase = true
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)

	panel.add_child(label)
	notification_box.add_child(panel)

	panel.modulate.a = 0.1
	var tween = get_tree().create_tween().bind_node(panel)
	tween.tween_property(panel, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_interval(2.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.1)
	tween.tween_callback(panel.queue_free)

func _on_resume_pressed() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	if badtrip_pause_menu:
		badtrip_pause_menu.visible = false
	if settings_panel:
		settings_panel.visible = false
	get_tree().call_group("player_hud", "show")

func _on_main_menu_pressed() -> void :
	Global.ex = true
	get_tree().paused = false

	if has_node("/root/LoadingScreen"):
		LoadingScreen.change_scene("res://Scenes/main_menu.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/main_menu.tscn")

func _on_settings_pressed() -> void :
	if badtrip_pause_menu:
		badtrip_pause_menu.visible = false
	if settings_panel:
		update_ui_from_global()
		settings_panel.visible = true

func close_settings() -> void :
	if settings_panel:
		settings_panel.visible = false
	if badtrip_pause_menu:
		badtrip_pause_menu.visible = true

	if Global.has_method("save_settings"):
		Global.save_settings()

func _on_restart_pressed() -> void :
	get_tree().paused = false
	skip_save_stats = true
	Global.reset_run()

	if has_node("/root/LoadingScreen"):
		LoadingScreen.change_scene("res://Scenes/level_generator.tscn", "ПЕРЕЗАГРУЗКА СИСТЕМЫ...")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/level_generator.tscn")

func spawn_visual_plunger(hit_pos: Vector3, normal: Vector3, target: Node3D):
	var plunger_root = Node3D.new()
	var stick = MeshInstance3D.new()
	var stick_mesh = CylinderMesh.new()
	stick_mesh.top_radius = 0.02
	stick_mesh.bottom_radius = 0.02
	stick_mesh.height = 0.4
	stick.mesh = stick_mesh

	var stick_mat = StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.6, 0.4, 0.2)
	stick_mesh.surface_set_material(0, stick_mat)
	stick.position.z = 0.2
	stick.rotation.x = PI / 2.0
	plunger_root.add_child(stick)

	var cup = MeshInstance3D.new()
	var cup_mesh = SphereMesh.new()
	cup_mesh.radius = 0.08
	cup_mesh.height = 0.16
	cup.mesh = cup_mesh

	var cup_mat = StandardMaterial3D.new()
	cup_mat.albedo_color = Color(0.8, 0.1, 0.1)
	cup_mesh.surface_set_material(0, cup_mat)
	cup.scale.z = 0.5
	plunger_root.add_child(cup)

	target.add_child(plunger_root)
	plunger_root.global_position = hit_pos
	var up_vec = Vector3.RIGHT if abs(normal.y) > 0.999 else Vector3.UP
	plunger_root.look_at(hit_pos - normal, up_vec)

	var tree = get_tree()
	if tree:
		tree.create_timer(3.0).timeout.connect(plunger_root.queue_free)

func recalculate_stats():
	var old_max_health = max_health
	max_health = Global.get_final_max_health()
	if max_health > old_max_health:
		current_health += (max_health - old_max_health)

	if not (has_meta("god_mode") and get_meta("god_mode")):
		current_health = min(current_health, max_health)

	var old_max_mana = max_mana
	max_mana = Global.get_final_max_mana()
	if max_mana > old_max_mana:
		current_mana += (max_mana - old_max_mana)
	current_mana = min(current_mana, max_mana)

	var mag_mult = Global.get("magazine_size_multiplier") if Global.get("magazine_size_multiplier") != null else 1.0
	var old_max_ammo = max_ammo

	if Global.current_weapon_type == "pistol":
		max_ammo = int(15 * mag_mult)
	elif Global.current_weapon_type == "rifle":
		max_ammo = int(40 * mag_mult)
	elif Global.current_weapon_type == "shotgun":
		max_ammo = int(Global.weapons_db.get("shotgun", {}).get("ammo", 8) * mag_mult)

	if max_ammo > old_max_ammo:
		current_ammo += (max_ammo - old_max_ammo)
	current_ammo = min(current_ammo, max_ammo)

	update_health_ui()
	update_mana_ui()
	update_ammo_ui()

	if stamina_bar:
		stamina_bar.max_value = max_stamina

func update_ammo_ui():
	if osd_ui and osd_ui.has_method("update_ammo"):
		osd_ui.update_ammo(current_ammo, max_ammo)
	elif ammo_label:
		ammo_label.text = "AMMO: %d / %d" % [current_ammo, max_ammo]

	if is_instance_valid(ammo_val_lbl):
		ammo_val_lbl.text = "%d / %d" % [current_ammo, max_ammo]

		var ratio = float(current_ammo) / float(max(1, max_ammo))
		var target_color = COLOR_MARKET_BORDER
		if ratio <= 0.3: target_color = Color(1.0, 0.5, 0.0)
		if ratio <= 0.0: target_color = COLOR_MONEY_DOWN

		if ammo_border.border_color != target_color:
			ammo_border.border_color = target_color
			ammo_title.add_theme_color_override("font_color", target_color)

		if ammo_visual_rect and is_instance_valid(ammo_box):
			ammo_visual_rect.queue_redraw()

func update_health_ui():
	if osd_ui and osd_ui.has_method("update_health"):
		osd_ui.update_health(current_health, max_health)

func update_mana_ui():
	var _display_text = ""
	if Global.show_stats_as_percentage:
		var pct = 0
		if max_mana > 0:
			pct = int((float(current_mana) / float(max_mana)) * 100.0)
		_display_text = "MANA: %d%%" % pct
	else:

		_display_text = "MANA: %d / %d" % [ceil(max(0.0, current_mana)), int(max_mana)]

	if osd_ui and osd_ui.has_method("update_mana"):
		osd_ui.update_mana(current_mana, max_mana)

func update_money_ui():
	if visual_money != Global.money:
		_on_money_pushed_from_global()

	if osd_ui and osd_ui.has_method("update_money"):
		osd_ui.update_money(Global.money)

func heal(amt):
	current_health = min(current_health + amt, max_health)
	update_health_ui()

func heal_mana(amt):
	max_mana = Global.get_final_max_mana()
	current_mana = min(current_mana + amt, max_mana)
	update_mana_ui()

func spawn_oil():
	if not oil_puddle_scene or not is_inside_tree(): return
	var puddle = oil_puddle_scene.instantiate()
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	root.add_child(puddle)
	var pos = global_position
	pos.y -= 0.95
	puddle.global_position = pos

func spawn_fire_trail():
	if not fire_trail_scene or not is_inside_tree(): return
	var trail = fire_trail_scene.instantiate()
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	root.add_child(trail)
	var pos = global_position
	pos.y -= 0.95
	trail.global_position = pos

func push_rigid_bodies():

	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()

		if collider is RigidBody3D:
			var normal = col.get_normal()
			if abs(normal.y) > 0.1:
				continue

			if collider.mass > 150.0:
				continue

			if collider.sleeping:
				collider.sleeping = false

			var push_dir = - normal
			push_dir.y = 0.0
			push_dir = push_dir.normalized()

			var hit_offset = col.get_position() - collider.global_position
			var player_mass = 80.0
			var mass_ratio = clamp(player_mass / collider.mass, 0.5, 5.0)

			var velocity_diff = velocity.dot(push_dir) - collider.linear_velocity.dot(push_dir)
			if velocity_diff > 0:
				var push_force = velocity_diff * mass_ratio * 3.0
				push_force = clamp(push_force, 0.0, 40.0)
				collider.apply_impulse(push_dir * push_force, hit_offset)




func _setup_ecg_ui():
	ecg_container = Control.new()
	ecg_container.custom_minimum_size = Vector2(300, 80)

	ecg_rect = ColorRect.new()
	ecg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	ecg_rect.color = Color(0.02, 0.02, 0.03, 1.0)
	ecg_container.add_child(ecg_rect)

	ecg_border = ReferenceRect.new()
	ecg_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	ecg_border.border_color = Color(0.2, 0.8, 0.2, 1.0)
	ecg_border.border_width = 4.0
	ecg_border.editor_only = false
	ecg_rect.add_child(ecg_border)

	var margin_c = MarginContainer.new()
	margin_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_c.add_theme_constant_override("margin_right", 15)
	margin_c.add_theme_constant_override("margin_bottom", 5)
	ecg_rect.add_child(margin_c)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_END
	margin_c.add_child(vbox)

	ecg_status_lbl = Label.new()
	ecg_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ecg_status_lbl.add_theme_font_size_override("font_size", 14)
	ecg_status_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	ecg_status_lbl.add_theme_constant_override("shadow_offset_x", 2)
	ecg_status_lbl.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(ecg_status_lbl)

	ecg_numbers_lbl = Label.new()
	ecg_numbers_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ecg_numbers_lbl.add_theme_font_size_override("font_size", 28)
	ecg_numbers_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	ecg_numbers_lbl.add_theme_constant_override("shadow_offset_x", 3)
	ecg_numbers_lbl.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(ecg_numbers_lbl)

	var shader = Shader.new()
	shader.code = "\n\tshader_type canvas_item;\n\tuniform float time;\n\tuniform vec3 line_color = vec3(0.2, 1.0, 0.2);\n\tuniform float health_ratio = 1.0;\n\tuniform float damage_glitch = 0.0;\n\n\tvoid fragment() {\n\t\tvec2 uv = UV;\n\t\tvec4 bg_base = vec4(0.0, 0.0, 0.0, 1.0);\n\t\t\n\t\t// Легкое искривление CRT\n\t\tuv.y += sin(uv.x * 40.0 + time * 5.0) * 0.003;\n\n\t\tif (damage_glitch > 0.0) {\n\t\t\tfloat n = fract(sin(dot(uv + time, vec2(12.9898,78.233))) * 43758.5453);\n\t\t\tuv.x += (n - 0.5) * damage_glitch * 0.05;\n\t\t\tbg_base.rgb += vec3(0.3, 0.0, 0.0) * damage_glitch * n;\n\t\t}\n\n\t\tfloat speed_mult = (health_ratio <= 0.0) ? 0.0 : mix(3.0, 1.2, health_ratio);\n\t\tfloat t = time * speed_mult;\n\t\tfloat x = fract(uv.x - t);\n\n\t\tfloat pulse = 0.0;\n\t\tpulse += exp(-pow((x - 0.2) * 40.0, 2.0)) * 0.1;\n\t\tpulse -= exp(-pow((x - 0.27) * 60.0, 2.0)) * 0.15;\n\t\tpulse += exp(-pow((x - 0.3) * 80.0, 2.0)) * 0.8;\n\t\tpulse -= exp(-pow((x - 0.34) * 60.0, 2.0)) * 0.2;\n\t\tpulse += exp(-pow((x - 0.5) * 30.0, 2.0)) * 0.15;\n\n\t\tfloat arrhythmia = mix(0.3, 0.0, health_ratio) * fract(sin(time * 10.0)*10.0);\n\t\tpulse += arrhythmia * 0.2;\n\n\t\tfloat amplitude_mult = (health_ratio <= 0.0) ? 0.0 : mix(1.3, 1.0, health_ratio);\n\t\tfloat target_y = 0.5 - pulse * 0.4 * amplitude_mult;\n\t\t\n\t\tfloat dist_to_line = abs(uv.y - target_y);\n\t\t\n\t\t// Возвращаем красивое свечение линии\n\t\tfloat line = smoothstep(0.03, 0.01, dist_to_line);\n\t\tfloat glow = smoothstep(0.1, 0.02, dist_to_line) * 0.5;\n\t\t\n\t\tfloat fade = smoothstep(0.0, 0.05, uv.x) * smoothstep(1.0, 0.95, uv.x);\n\t\tfloat grid = max(step(0.95, fract(uv.x * 10.0)), step(0.95, fract(uv.y * 5.0))) * 0.15;\n\n\t\tvec3 final_glow = line_color * (line + glow) * fade;\n\t\tif (damage_glitch > 0.5) final_glow = mix(final_glow, vec3(1.0), 0.5);\n\n\t\tCOLOR = vec4(bg_base.rgb + final_glow + (line_color * grid), 1.0);\n\t}\n\t"



















































	var mat = ShaderMaterial.new()
	mat.shader = shader
	ecg_rect.material = mat

	var stats_container = get_node_or_null("CanvasLayer_UI/Control_OSD/BottomLeftContainer/VBoxContainer_Stats")
	if stats_container:
		stats_container.add_child(ecg_container)
		if health_label: stats_container.move_child(ecg_container, health_label.get_index())
	elif osd_ui:
		osd_ui.add_child(ecg_container)

func _update_ecg_visuals(delta):
	if not ecg_rect or not is_instance_valid(ecg_rect): return
	ecg_damage_impact = lerp(ecg_damage_impact, 0.0, delta * 5.0)
	var ratio = clamp(float(current_health) / float(max_health), 0.0, 1.0) if max_health > 0 else 0.0

	var target_color: Color
	var status_text: String
	if ratio > 0.6: target_color = Color(0.2, 1.0, 0.4);status_text = "ОПТИМАЛЬНО"
	elif ratio > 0.25: target_color = Color(1.0, 0.8, 0.1);status_text = "ПОВРЕЖДЕНИЯ"
	elif ratio > 0.0: target_color = Color(1.0, 0.2, 0.2);status_text = "КРИТИЧЕСКИ"
	else: target_color = Color(0.5, 0.0, 0.0);status_text = "ОТКАЗ СИСТЕМ"

	current_ecg_color = current_ecg_color.lerp(target_color, delta * 4.0)

	if ecg_damage_impact > 0.01:
		var shake = 8.0 * ecg_damage_impact
		ecg_rect.position = Vector2(randf_range( - shake, shake), randf_range( - shake, shake))
		ecg_border.border_color = Color(1.0, 0.0, 0.0, 1.0) if randf() > 0.3 else Color(0, 0, 0, 0)
	else:
		ecg_rect.position = Vector2.ZERO
		ecg_border.border_color = Color(current_ecg_color.r, current_ecg_color.g, current_ecg_color.b, 0.8)

	if ecg_rect.material:

		ecg_rect.material.set_shader_parameter("time", ecg_time)
		ecg_rect.material.set_shader_parameter("health_ratio", ratio)
		ecg_rect.material.set_shader_parameter("line_color", Vector3(current_ecg_color.r, current_ecg_color.g, current_ecg_color.b))
		ecg_rect.material.set_shader_parameter("damage_glitch", ecg_damage_impact)

	ecg_status_lbl.text = status_text
	ecg_status_lbl.add_theme_color_override("font_color", current_ecg_color)

	var display_hp = ceil(max(0.0, current_health))
	ecg_numbers_lbl.text = "%d / %d" % [display_hp, int(max_health)]

	if ecg_damage_impact > 0.5: ecg_numbers_lbl.add_theme_color_override("font_color", Color.WHITE)
	else: ecg_numbers_lbl.add_theme_color_override("font_color", current_ecg_color)



func _setup_stamina_battery_ui():
	stamina_battery_container = Control.new()
	stamina_battery_container.custom_minimum_size = Vector2(240, 18)

	stamina_battery_rect = ColorRect.new()
	stamina_battery_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	stamina_battery_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamina_battery_rect.custom_minimum_size.y = 18
	stamina_battery_container.add_child(stamina_battery_rect)

	var shader = Shader.new()
	shader.code = "\n\tshader_type canvas_item;\n\tuniform float time;\n\tuniform float stamina_ratio = 1.0;\n\tuniform float drain_impact = 0.0;\n\tuniform bool exhausted = false;\n\n\tvoid fragment() {\n\t\tvec2 uv = UV;\n\t\t\n\t\tvec3 color_full = vec3(0.0, 1.0, 0.3); \n\t\tvec3 color_warn = vec3(1.0, 0.8, 0.0); \n\t\tvec3 color_crit = vec3(1.0, 0.1, 0.1); \n\t\t\n\t\t// Четкое переключение цвета\n\t\tvec3 current_color = mix(color_crit, color_warn, step(0.25, stamina_ratio));\n\t\tcurrent_color = mix(current_color, color_full, step(0.6, stamina_ratio));\n\t\t\n\t\tif (exhausted) {\n\t\t\tcurrent_color = mix(vec3(0.2), vec3(0.9), step(0.5, fract(time * 8.0)));\n\t\t}\n\t\t\n\t\t// Наклон\n\t\tvec2 suv = uv;\n\t\tsuv.x += (0.5 - uv.y) * 0.3; \n\t\t\n\t\tfloat segments = 22.0; \n\t\tfloat seg_uv = fract(suv.x * segments);\n\t\t\n\t\t// Четкие блоки с зазорами (без лесенки)\n\t\tfloat is_segment = step(0.15, seg_uv); \n\t\tfloat is_active = step(suv.x, stamina_ratio);\n\t\t\n\t\tif (drain_impact > 0.05) {\n\t\t\tfloat noise = fract(sin(dot(uv + time, vec2(12.9898,78.233))) * 43758.5453);\n\t\t\tcurrent_color = mix(current_color, vec3(1.0), drain_impact * step(0.7, noise));\n\t\t}\n\t\t\n\t\tfloat bounds = step(0.01, suv.x) * step(suv.x, 0.99);\n\t\tCOLOR = vec4(current_color, is_segment * is_active * bounds);\n\t}\n\t"









































	var mat = ShaderMaterial.new()
	mat.shader = shader
	stamina_battery_rect.material = mat

	var stats_container = get_node_or_null("CanvasLayer_UI/Control_OSD/BottomLeftContainer/VBoxContainer_Stats")
	if stats_container:
		for child in stats_container.get_children():
			if child.get_meta("ui_type", "") == "stamina_bar":
				child.queue_free()

		stamina_battery_container.set_meta("ui_type", "stamina_bar")
		stats_container.add_child(stamina_battery_container)
		if ecg_container:
			stats_container.move_child(stamina_battery_container, ecg_container.get_index() + 1)

func _update_stamina_battery_visuals(delta):
	if not stamina_battery_rect or not is_instance_valid(stamina_battery_rect): return

	stamina_drain_impact = lerp(stamina_drain_impact, 0.0, delta * 7.0)
	var ratio = clamp(current_stamina / max_stamina, 0.0, 1.0) if max_stamina > 0 else 0.0

	if stamina_battery_rect.material:
		stamina_battery_rect.material.set_shader_parameter("time", stamina_battery_time)
		stamina_battery_rect.material.set_shader_parameter("stamina_ratio", ratio)
		stamina_battery_rect.material.set_shader_parameter("exhausted", is_exhausted)
		stamina_battery_rect.material.set_shader_parameter("drain_impact", stamina_drain_impact)

	if stamina_drain_impact > 0.1:
		var shake = 4.0 * stamina_drain_impact
		stamina_battery_rect.position = Vector2(randf_range( - shake, shake), randf_range( - shake, shake))
	else:
		stamina_battery_rect.position = Vector2.ZERO





func _setup_market_ui():
	market_container = Control.new()
	market_container.add_to_group("player_hud")
	market_container.custom_minimum_size = Vector2(280, 140)
	market_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	market_container.position = Vector2(20, 45)
	market_container.pivot_offset = Vector2(140, 70)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.9)
	market_container.add_child(bg)

	market_border = ReferenceRect.new()
	market_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	market_border.border_color = COLOR_MARKET_BORDER
	market_border.border_width = 4.0
	market_border.editor_only = false
	market_container.add_child(market_border)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	market_container.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)

	var top_hbox = HBoxContainer.new()
	main_vbox.add_child(top_hbox)

	var chart_header = Label.new()
	chart_header.text = "I ИНФЛЯЦИЯ ЦЕН"
	chart_header.add_theme_font_size_override("font_size", 12)
	chart_header.add_theme_color_override("font_color", COLOR_MARKET_BORDER)
	chart_header.add_theme_color_override("font_shadow_color", Color.BLACK)
	chart_header.add_theme_constant_override("shadow_offset_x", 1)
	chart_header.add_theme_constant_override("shadow_offset_y", 1)
	chart_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(chart_header)

	market_inflation_lbl = Label.new()
	market_inflation_lbl.text = "[ 1.00x ]"
	market_inflation_lbl.add_theme_font_size_override("font_size", 14)
	market_inflation_lbl.add_theme_color_override("font_color", Color.WHITE)
	market_inflation_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	market_inflation_lbl.add_theme_constant_override("shadow_offset_x", 2)
	market_inflation_lbl.add_theme_constant_override("shadow_offset_y", 2)
	top_hbox.add_child(market_inflation_lbl)

	arrow_up_lbl = Label.new()
	arrow_up_lbl.text = "▲"
	arrow_up_lbl.add_theme_font_size_override("font_size", 16)
	arrow_up_lbl.add_theme_color_override("font_color", COLOR_MONEY_UP)
	arrow_up_lbl.modulate.a = 0.2
	top_hbox.add_child(arrow_up_lbl)

	arrow_down_lbl = Label.new()
	arrow_down_lbl.text = "▼"
	arrow_down_lbl.add_theme_font_size_override("font_size", 16)
	arrow_down_lbl.add_theme_color_override("font_color", COLOR_MONEY_DOWN)
	arrow_down_lbl.modulate.a = 0.2
	top_hbox.add_child(arrow_down_lbl)

	market_graph_rect = ColorRect.new()
	market_graph_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_graph_rect.custom_minimum_size.y = 60
	market_graph_rect.color = Color(0.02, 0.02, 0.02, 1.0)
	market_graph_rect.clip_contents = true
	market_graph_rect.draw.connect(_on_market_graph_draw)
	main_vbox.add_child(market_graph_rect)

	var bot_hbox = HBoxContainer.new()
	main_vbox.add_child(bot_hbox)

	money_title = Label.new()
	money_title.text = "I БАЛАНС"
	money_title.add_theme_font_size_override("font_size", 12)
	money_title.add_theme_color_override("font_color", COLOR_MARKET_BORDER)
	money_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	money_title.add_theme_constant_override("shadow_offset_x", 1)
	money_title.add_theme_constant_override("shadow_offset_y", 1)
	money_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_hbox.add_child(money_title)

	market_delta_lbl = Label.new()
	market_delta_lbl.text = ""
	market_delta_lbl.add_theme_font_size_override("font_size", 12)
	market_delta_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	market_delta_lbl.add_theme_constant_override("shadow_offset_x", 2)
	market_delta_lbl.add_theme_constant_override("shadow_offset_y", 2)
	bot_hbox.add_child(market_delta_lbl)

	market_value_lbl = Label.new()
	market_value_lbl.text = "$0"
	market_value_lbl.add_theme_font_size_override("font_size", 16)
	market_value_lbl.add_theme_color_override("font_color", Color.WHITE)
	market_value_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	market_value_lbl.add_theme_constant_override("shadow_offset_x", 2)
	market_value_lbl.add_theme_constant_override("shadow_offset_y", 2)
	bot_hbox.add_child(market_value_lbl)

	var ui_layer = get_node_or_null("CanvasLayer_UI")
	if ui_layer: ui_layer.add_child(market_container)

func _on_market_graph_draw():
	var history = Global.market_history
	if market_graph_rect == null or history.size() < 2: return
	var h = market_graph_rect.size.y
	var w = market_graph_rect.size.x

	var grid_col = COLOR_MARKET_BORDER * 0.2
	for y_slot in [0.25, 0.5, 0.75]:
		var y_pos = floor(h * y_slot)
		for x_pos in range(0, int(w), 4):
			market_graph_rect.draw_rect(Rect2(x_pos, y_pos, 2, 2), grid_col)

	var min_val = history.min()
	var max_val = history.max()
	if max_val - min_val < 0.01:
		max_val += 0.1
		min_val -= 0.1

	var step_x = max(1.0, floor(w / float(history.size() - 1)))

	for i in range(1, history.size()):
		var val_prev = history[i - 1]
		var val_curr = history[i]

		var px_prev = floor((i - 1) * step_x)
		var py_prev = clamp(floor(h - ((val_prev - min_val) / (max_val - min_val)) * h), 2.0, h - 2.0)
		var px_curr = floor(i * step_x)
		var py_curr = clamp(floor(h - ((val_curr - min_val) / (max_val - min_val)) * h), 2.0, h - 2.0)

		var line_color = COLOR_MONEY_DOWN if val_curr >= val_prev else COLOR_MONEY_UP
		market_graph_rect.draw_line(Vector2(px_prev, py_prev), Vector2(px_curr, py_curr), line_color, 3.0, false)
		market_graph_rect.draw_rect(Rect2(px_curr - 2, py_curr - 2, 5, 5), line_color)

func _on_money_pushed_from_global():
	var target_money = float(Global.money)
	var diff = target_money - visual_money
	if abs(diff) < 0.1: return

	last_money_diff = int(target_money - visual_money)

	if diff > 0:
		market_trend = 1
		target_market_scale = Vector2(1.1, 1.1)
	else:
		market_trend = -1
		money_shake_impact = 1.0

	money_impact_timer = 2.0

func _update_market_visuals(delta):
	if not market_container or not is_instance_valid(market_container): return

	market_container.scale = market_container.scale.lerp(target_market_scale, delta * 20.0)
	if target_market_scale.x > 1.0: target_market_scale = target_market_scale.lerp(Vector2.ONE, delta * 12.0)

	if abs(Global.money - visual_money) > 0.1:
		visual_money = lerp(visual_money, float(Global.money), 15.0 * delta)
		if abs(Global.money - visual_money) < 1.0: visual_money = float(Global.money)

	if money_impact_timer > 0:
		money_impact_timer -= delta
		if money_impact_timer <= 0:
			market_trend = 0
			money_shake_impact = 0.0
			last_money_diff = 0

	if money_shake_impact > 0:
		money_shake_impact = lerp(money_shake_impact, 0.0, delta * 5.0)
		var shake_pwr = floor(10.0 * money_shake_impact)
		market_container.position = Vector2(20 + randf_range( - shake_pwr, shake_pwr), 45 + randf_range( - shake_pwr, shake_pwr))
	else:
		market_container.position = Vector2(20, 45)

	_update_market_text(delta)

	var current_inf = Global.total_market_mult
	market_inflation_lbl.text = "[ %.2fx ]" % current_inf

	if market_graph_rect: market_graph_rect.queue_redraw()

	var glob_history = Global.market_history
	if glob_history.size() >= 2:
		var prev_inf = glob_history[glob_history.size() - 2]
		arrow_up_lbl.modulate.a = 1.0 if current_inf > prev_inf else 0.2
		arrow_down_lbl.modulate.a = 1.0 if current_inf < prev_inf else 0.2

func _update_market_text(delta):
	if not is_instance_valid(market_border): return

	var target_color = COLOR_MARKET_BORDER
	var prefix = ""

	if market_trend == 1:
		target_color = COLOR_MONEY_UP
		prefix = "+"
	elif market_trend == -1:
		target_color = COLOR_MONEY_DOWN

	if last_money_diff != 0:
		var percent = (float(last_money_diff) / max(1.0, float(visual_money - last_money_diff))) * 100.0
		market_delta_lbl.text = "%s%d (%.1f%%)" % [prefix, last_money_diff, percent]
		market_delta_lbl.add_theme_color_override("font_color", target_color)
	else:
		market_delta_lbl.text = ""

	var current_border_color = market_border.border_color.lerp(target_color, delta * 8.0)
	market_border.border_color = current_border_color
	money_title.add_theme_color_override("font_color", current_border_color)
	market_value_lbl.add_theme_color_override("font_color", current_border_color.lerp(Color.WHITE, 0.3))

	market_value_lbl.text = "₽ %d" % int(visual_money)




func _setup_ammo_ui():
	ammo_box = Control.new()
	ammo_box.add_to_group("player_hud")
	ammo_box.custom_minimum_size = Vector2(180, 110)
	ammo_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_box.offset_left = -200
	ammo_box.offset_top = -130
	ammo_box.offset_right = -20
	ammo_box.offset_bottom = -20
	ammo_box.pivot_offset = Vector2(90, 55)

	var bg_shader = Shader.new()
	bg_shader.code = "\n\tshader_type canvas_item; \n\tvoid fragment() { \n\t\tfloat time_q = floor(TIME * 12.0) / 12.0;\n\t\tfloat scanline = step(0.6, fract(UV.y * 50.0 + time_q * 2.0)) * 0.15; \n\t\tfloat noise = step(0.98, fract(sin(dot(UV + time_q, vec2(12.9898,78.233))) * 43758.5453)) * 0.1;\n\t\tCOLOR = vec4(0.0, 0.0, 0.0, 1.0) + vec4(0.0, scanline + noise, 0.0, 1.0); \n\t}\n\t"








	var bg_mat = ShaderMaterial.new()
	bg_mat.shader = bg_shader

	ammo_bg = ColorRect.new()
	ammo_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ammo_bg.material = bg_mat
	ammo_box.add_child(ammo_bg)

	ammo_border = ReferenceRect.new()
	ammo_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	ammo_border.border_color = COLOR_MARKET_BORDER
	ammo_border.border_width = 4.0
	ammo_border.editor_only = false
	ammo_box.add_child(ammo_border)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	ammo_box.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var title_hbox = HBoxContainer.new()
	vbox.add_child(title_hbox)

	ammo_title = Label.new()
	ammo_title.text = "[ БОЕЗАПАС ]"
	ammo_title.add_theme_font_size_override("font_size", 12)
	ammo_title.add_theme_color_override("font_color", COLOR_MARKET_BORDER)
	ammo_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	ammo_title.add_theme_constant_override("shadow_offset_x", 1)
	ammo_title.add_theme_constant_override("shadow_offset_y", 1)
	ammo_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(ammo_title)

	ammo_integrity_lbl = Label.new()
	ammo_integrity_lbl.text = "100%"
	ammo_integrity_lbl.add_theme_font_size_override("font_size", 11)
	ammo_integrity_lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.5))
	ammo_integrity_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	title_hbox.add_child(ammo_integrity_lbl)

	ammo_val_lbl = Label.new()
	ammo_val_lbl.text = "0 / 0"
	ammo_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_val_lbl.add_theme_font_size_override("font_size", 32)
	ammo_val_lbl.add_theme_color_override("font_color", Color.WHITE)
	ammo_val_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	ammo_val_lbl.add_theme_constant_override("shadow_offset_x", 3)
	ammo_val_lbl.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(ammo_val_lbl)

	ammo_visual_rect = ColorRect.new()
	ammo_visual_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ammo_visual_rect.custom_minimum_size.y = 25
	ammo_visual_rect.color = Color(0, 0, 0, 0)
	ammo_visual_rect.draw.connect(_on_ammo_draw)
	vbox.add_child(ammo_visual_rect)

	var ui_layer = get_node_or_null("CanvasLayer_UI")
	if ui_layer: ui_layer.add_child(ammo_box)

func _on_ammo_draw():
	if not is_instance_valid(ammo_visual_rect) or max_ammo <= 0: return
	var w = ammo_visual_rect.size.x
	var h = ammo_visual_rect.size.y

	var active_color = ammo_border.border_color
	var empty_color = Color(0.0, 0.2, 0.05, 0.7)

	var cols = 15
	if max_ammo > 30: cols = 20
	if max_ammo > 60: cols = 30

	var rows = ceil(float(max_ammo) / float(cols))
	var gap = 3.0 if cols <= 20 else 2.0

	var block_w = max(2.0, floor((w - (cols - 1) * gap) / float(cols)))
	var block_h = max(4.0, floor((h - (rows - 1) * gap) / float(rows)))

	for i in range(max_ammo):
		var px = (i % cols) * (block_w + gap)
		@warning_ignore("integer_division")
		var py = (i / cols) * (block_h + gap)

		var points = PackedVector2Array()
		var tip_h = floor(block_h * 0.3)

		points.append(Vector2(px, py + tip_h))
		points.append(Vector2(px + floor(block_w / 2.0), py))
		points.append(Vector2(px + block_w, py + tip_h))
		points.append(Vector2(px + block_w, py + block_h))
		points.append(Vector2(px, py + block_h))

		if i < current_ammo:
			ammo_visual_rect.draw_polygon(points, PackedColorArray([active_color, active_color, active_color, active_color, active_color]))
		else:
			ammo_visual_rect.draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[4], points[0]]), empty_color, 2.0)
			if block_w > 4.0 and block_h > 6.0:
				ammo_visual_rect.draw_rect(Rect2(px + block_w / 2.0 - 1, py + block_h / 2.0 + 1, 2, 2), empty_color * 0.5)

func _update_ammo_visuals(delta):
	if not is_instance_valid(ammo_box): return

	if ammo_shake_impact > 0:
		ammo_shake_impact = lerp(ammo_shake_impact, 0.0, delta * 8.0)
		var shake_pwr = floor(12.0 * ammo_shake_impact)
		ammo_box.offset_left = -200 + randf_range( - shake_pwr, shake_pwr)
		ammo_box.offset_top = -130 + randf_range( - shake_pwr, shake_pwr)
		ammo_box.offset_right = -20 + randf_range( - shake_pwr, shake_pwr)
		ammo_box.offset_bottom = -20 + randf_range( - shake_pwr, shake_pwr)
	else:
		ammo_box.offset_left = -200
		ammo_box.offset_top = -130
		ammo_box.offset_right = -20
		ammo_box.offset_bottom = -20




func _build_perfect_badtrip_menu():
	if Menu:
		Menu.queue_free()

	badtrip_pause_menu = Control.new()
	badtrip_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	badtrip_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	badtrip_pause_menu.visible = false
	badtrip_pause_menu.z_index = 100

	var ui_layer = get_node_or_null("CanvasLayer_UI")
	if ui_layer:
		ui_layer.add_child(badtrip_pause_menu)
	else:
		add_child(badtrip_pause_menu)


	var bg_rect = ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shader = Shader.new()
	shader.code = "\n\tshader_type canvas_item;\n\tuniform vec3 theme_col;\n\n\tvoid fragment() {\n\t\tvec2 uv = SCREEN_UV;\n\t\tfloat t = TIME * 0.5; // Встроенное время работает даже на паузе\n\t\t\n\t\t// Темный фон с легким оттенком текущей темы\n\t\tvec3 bg = mix(vec3(0.01, 0.01, 0.02), theme_col, 0.05);\n\t\tvec3 blob_col = theme_col * 0.15; // Плавающие пятна цвета темы\n\t\t\n\t\tvec2 p1 = vec2(0.2 + sin(t * 0.1)*0.1, 0.4 + cos(t * 0.15)*0.1);\n\t\tvec2 p2 = vec2(0.8 + cos(t * 0.2)*0.1, 0.6 + sin(t * 0.1)*0.1);\n\t\t\n\t\tvec2 uv1 = uv * vec2(1.0, 0.5); p1 *= vec2(1.0, 0.5);\n\t\tvec2 uv2 = uv * vec2(0.5, 1.0); p2 *= vec2(0.5, 1.0);\n\t\t\n\t\tfloat blobs = smoothstep(0.5, 0.1, distance(uv1, p1)) + smoothstep(0.5, 0.1, distance(uv2, p2));\n\t\tvec3 final_color = mix(bg, blob_col, clamp(blobs, 0.0, 1.0));\n\t\t\n\t\t// Сканлайны\n\t\tfinal_color -= sin(SCREEN_UV.y * 1200.0) * 0.015;\n\t\t\n\t\tCOLOR = vec4(final_color, 0.85); // 0.85 альфа, чтобы игра просвечивала на фоне\n\t}\n\t"


























	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("theme_col", Vector3(current_theme_color.r, current_theme_color.g, current_theme_color.b))
	bg_rect.material = mat
	badtrip_pause_menu.add_child(bg_rect)


	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	badtrip_pause_menu.add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)


	var title_vbox = VBoxContainer.new()
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_vbox)

	var title1 = Label.new()
	title1.text = "FUCK BRAINS"
	title1.add_theme_font_size_override("font_size", 75)
	title1.add_theme_color_override("font_color", current_theme_color)
	title1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title1.rotation_degrees = -3.0
	title1.pivot_offset = Vector2(810 / 2.0, 40)
	title_vbox.add_child(title1)

	var title2 = Label.new()
	title2.text = "[ SYS.PAUSED ]"
	title2.add_theme_font_size_override("font_size", 28)
	var dimmed_color = current_theme_color.lerp(Color.GRAY, 0.3)
	title2.add_theme_color_override("font_color", dimmed_color)
	title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(title2)

	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)


	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_vbox.add_theme_constant_override("separation", 15)
	vbox.add_child(buttons_vbox)

	var btn_resume = Button.new()
	_style_pause_cyber_button(btn_resume, "ПРОДОЛЖИТЬ")
	btn_resume.pressed.connect(_on_resume_pressed)
	buttons_vbox.add_child(btn_resume)

	var btn_settings = Button.new()
	_style_pause_cyber_button(btn_settings, "НАСТРОЙКИ")
	btn_settings.pressed.connect(_on_settings_pressed)
	buttons_vbox.add_child(btn_settings)

	var btn_restart = Button.new()
	_style_pause_cyber_button(btn_restart, "ПЕРЕЗАПУСК")
	btn_restart.pressed.connect(_on_restart_pressed)
	buttons_vbox.add_child(btn_restart)

	var btn_main = Button.new()
	_style_pause_cyber_button(btn_main, "ВЫХОД В МЕНЮ")
	btn_main.pressed.connect(_on_main_menu_pressed)
	buttons_vbox.add_child(btn_main)


func _style_pause_cyber_button(btn: Button, main_text: String):
	btn.text = ""
	btn.custom_minimum_size = Vector2(400, 60)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)

	var text_lbl = Label.new()
	text_lbl.text = main_text
	text_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.add_theme_font_size_override("font_size", 30)
	var dimmed_color = current_theme_color.lerp(Color.GRAY, 0.4)
	text_lbl.add_theme_color_override("font_color", dimmed_color)
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(text_lbl)

	var hover_bg = ColorRect.new()
	hover_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_hover_color = current_theme_color
	bg_hover_color.a = 0.5
	hover_bg.color = bg_hover_color
	hover_bg.visible = false
	hover_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hover_bg)
	btn.move_child(hover_bg, 0)

	btn.mouse_entered.connect( func():
		if btn.has_meta("shake_tween"):
			var st = btn.get_meta("shake_tween")
			if is_instance_valid(st): st.kill()
		if btn.has_meta("pulse_tween"):
			var pt = btn.get_meta("pulse_tween")
			if is_instance_valid(pt): pt.kill()

		hover_bg.visible = true
		text_lbl.add_theme_color_override("font_color", Color.WHITE)


		var shake_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		for j in range(4):
			shake_tween.tween_property(btn, "position:x", btn.position.x + randf_range(-5.0, 5.0), 0.03)
			shake_tween.tween_property(btn, "position:x", btn.position.x, 0.03)
		btn.set_meta("shake_tween", shake_tween)

		var pulse_tween = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pulse_tween.tween_property(hover_bg, "color:a", 0.7, 0.1)
		pulse_tween.tween_property(hover_bg, "color:a", 0.4, 0.1)
		btn.set_meta("pulse_tween", pulse_tween)
	)

	btn.mouse_exited.connect( func():
		hover_bg.visible = false
		text_lbl.add_theme_color_override("font_color", dimmed_color)

		if btn.has_meta("shake_tween"):
			var st = btn.get_meta("shake_tween")
			if is_instance_valid(st): st.kill()
			btn.remove_meta("shake_tween")

		if btn.has_meta("pulse_tween"):
			var pt = btn.get_meta("pulse_tween")
			if is_instance_valid(pt): pt.kill()
			btn.remove_meta("pulse_tween")
	)




func _setup_ps1_filter():
	var filter_layer = CanvasLayer.new()
	filter_layer.layer = -1
	add_child(filter_layer)

	var color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	filter_layer.add_child(color_rect)

	var shader = Shader.new()
	shader.code = "\n\tshader_type canvas_item;\n\tuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;\n\tuniform int color_depth : hint_range(1, 8) = 5; \n\tuniform bool dithering = true; \n\tuniform int resolution_scale : hint_range(1, 10) = 4;\n\n\tint dithering_pattern(ivec2 fragcoord) {\n\t\tconst int pattern[] = {\n\t\t\t-4, +0, -3, +1,\n\t\t\t+2, -2, +3, -1,\n\t\t\t-3, +1, -4, +0,\n\t\t\t+3, -1, +2, -2\n\t\t};\n\t\tint x = fragcoord.x % 4;\n\t\tint y = fragcoord.y % 4;\n\t\treturn pattern[y * 4 + x];\n\t}\n\n\tvoid fragment() {\n\t\tivec2 uv = ivec2(FRAGCOORD.xy / float(resolution_scale));\n\t\tvec3 color = texelFetch(screen_texture, uv * resolution_scale, 0).rgb;\n\t\tivec3 c = ivec3(round(color * 255.0));\n\t\tif (dithering) c += ivec3(dithering_pattern(uv));\n\t\tc >>= (8 - color_depth);\n\t\tCOLOR.rgb = vec3(c) / float(1 << color_depth);\n\t\tCOLOR.a = 1.0;\n\t}\n\t"




























	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	color_rect.material = shader_mat

	color_rect.material = shader_mat
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
		@warning_ignore("integer_division")
		main_window.position = (screen_size / 2) - (current_res / 2)


	get_tree().root.content_scale_size = current_res
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	if Global.has_method("apply_graphics_settings"):
		Global.apply_graphics_settings()


func _prepare_combat_assets():
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.add_point(0.1, Color(1.0, 0.8, 0.0, 1.0))
	gradient.add_point(0.6, Color(1.0, 0.2, 0.0, 1.0))
	gradient.add_point(1.0, Color(0.0, 0.0, 0.0, 0.0))
	cached_spark_ramp = GradientTexture1D.new()
	cached_spark_ramp.gradient = gradient

	cached_spark_mesh_mat = StandardMaterial3D.new()
	cached_spark_mesh_mat.vertex_color_use_as_albedo = true
	cached_spark_mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cached_spark_mesh_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD

	if Global.get("_pools") != null and not Global._pools.has("hit_sparks_scene"):
		var p_node = GPUParticles3D.new()
		p_node.one_shot = true
		p_node.explosiveness = 1.0
		p_node.amount = 8
		p_node.lifetime = 0.25
		var mat = ParticleProcessMaterial.new()
		mat.spread = 35.0
		mat.initial_velocity_min = 15.0
		mat.initial_velocity_max = 30.0
		mat.gravity = Vector3(0, -40.0, 0)
		mat.particle_flag_align_y = true
		mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
		mat.collision_bounce = 0.3
		mat.collision_friction = 0.8
		mat.color_ramp = cached_spark_ramp
		p_node.process_material = mat
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.015, 0.2, 0.015)
		mesh.surface_set_material(0, cached_spark_mesh_mat)
		p_node.draw_pass_1 = mesh
		var packed_scene = PackedScene.new()
		packed_scene.pack(p_node)
		Global._pools["hit_sparks_scene"] = packed_scene

	var blood_shader = Shader.new()
	blood_shader.code = "\n\tshader_type spatial;\n\trender_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, depth_test_disabled;\n\tuniform vec3 blood_color : source_color = vec3(0.4, 0.01, 0.01);\n\tuniform float growth : hint_range(0.0, 1.0) = 0.0;\n\tuniform float seed = 0.0;\n\tfloat hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }\n\tfloat noise(vec2 p) {\n\t\tvec2 i = floor(p); vec2 f = fract(p); vec2 u = f * f * (3.0 - 2.0 * f);\n\t\treturn mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),\n\t\t\t\t   mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);\n\t}\n\tvoid fragment() {\n\t\tvec2 uv = UV * 2.0 - 1.0;\n\t\tfloat dist = length(uv);\n\t\tfloat n = noise(uv * 3.0 + vec2(seed)) * 0.4;\n\t\tfloat blob = dist + n;\n\t\tfloat edge = 1.0 - growth;\n\t\tfloat alpha = smoothstep(edge + 0.05, edge - 0.05, blob);\n\t\tALBEDO = blood_color;\n\t\tROUGHNESS = 0.05; \n\t\tMETALLIC = 0.2;\n\t\tALPHA = clamp(alpha, 0.0, 1.0);\n\t}\n\t"
























	cached_blood_pool_mat = ShaderMaterial.new()
	cached_blood_pool_mat.shader = blood_shader



	var prewarm_node = Node3D.new()
	camera.add_child(prewarm_node)
	prewarm_node.position = Vector3(0, 0, -1.0)
	prewarm_node.scale = Vector3(0.001, 0.001, 0.001)

	if Global.get("_pools") != null and Global._pools.has("hit_sparks_scene"):
		var spark_prewarm = GPUParticles3D.new()
		spark_prewarm.process_material = Global._pools["hit_sparks_scene"].instantiate().process_material
		spark_prewarm.draw_pass_1 = Global._pools["hit_sparks_scene"].instantiate().draw_pass_1
		spark_prewarm.emitting = true
		prewarm_node.add_child(spark_prewarm)

	var blood_prewarm = MeshInstance3D.new()
	blood_prewarm.mesh = PlaneMesh.new()
	blood_prewarm.material_override = cached_blood_pool_mat
	prewarm_node.add_child(blood_prewarm)

	var side_mat = ShaderMaterial.new()
	if muzzle_side_shader: side_mat.shader = muzzle_side_shader
	var face_mat = ShaderMaterial.new()
	if muzzle_face_shader: face_mat.shader = muzzle_face_shader

	var m_prewarm1 = MeshInstance3D.new()
	m_prewarm1.mesh = QuadMesh.new()
	m_prewarm1.material_override = side_mat
	prewarm_node.add_child(m_prewarm1)

	var m_prewarm2 = MeshInstance3D.new()
	m_prewarm2.mesh = QuadMesh.new()
	m_prewarm2.material_override = face_mat
	prewarm_node.add_child(m_prewarm2)


	if hole_scene:
		var hole_prewarm = hole_scene.instantiate()
		prewarm_node.add_child(hole_prewarm)


	get_tree().create_timer(0.2).timeout.connect(prewarm_node.queue_free)


func spawn_natalia_black_hole(target_pos: Vector3):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			var d = e.global_position.distance_to(target_pos)
			if d < 12.0:
				var pull_dir = e.global_position.direction_to(target_pos)

				if e is CharacterBody3D: e.velocity += pull_dir * 25.0
				elif e is RigidBody3D: e.apply_central_impulse(pull_dir * 50.0)
	show_notification("СИНГУЛЯРНОСТЬ УТЮГА!", Color.PURPLE)


func trigger_justice_hammer():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var valid_enemies = []
	for e in enemies:
		if is_instance_valid(e) and not e.get("is_dead"):
			valid_enemies.append(e)
	if valid_enemies.size() > 0:
		var target = valid_enemies.pick_random()
		var final_dmg = Global.get_final_phys_damage(damage) * 3.3
		if target.has_method("take_damage"):
			target.take_damage(final_dmg, true, target.global_position, Vector3.DOWN)
			show_notification("МОЛОТ СПРАВЕДЛИВОСТИ!", Color.YELLOW)

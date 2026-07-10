extends Node

signal inventory_updated
signal money_updated

const SAVE_PATH = "user://savegame.cfg"
const META_SAVE_PATH = "user://meta_save.dat"


var active_enemies: Array[Node3D] = []
var _pools: Dictionary = {}

var is_auto_test: bool = false
var player_health: float = -1.0
var player_mana: float = -1.0
var pistol_ammo: int = 15
var rifle_ammo: int = 40
var shotgun_ammo: int = 8

var spawn_protection: bool = false


var show_stats_as_percentage: bool = true
var active_anim_type: int = -1
var vhs_enabled: bool = true
var vhs_intensity: float = 1.0
var vhs_noise: float = 0.05
var vhs_rgb: float = 0.1
var vhs_style: int = 0
var show_damage_numbers: bool = true

var score: int = 0
var selected_weapon: String = "pistol"
var current_weapon_type = "pistol"
var money: int = 0
var ex = false
var run_time: float = 0.0


var market_history: Array[float] = []
var current_market_mult: float = 1.0
var total_market_mult: float = 1.0
var market_timer: float = 0.0

func add_money(amount: int):
	money += amount
	money_updated.emit()




var base_max_health: float = 100.0
var bonus_max_health: float = 0.0
var health_multiplier: float = 1.0

var base_max_mana: float = 0.0
var bonus_max_mana: float = 0.0
var mana_multiplier: float = 1.0

var base_max_stamina: float = 100.0
var bonus_max_stamina: float = 0.0
var stamina_multiplier: float = 1.0

var base_stamina_regen: float = 45.0
var bonus_stamina_regen: float = 0.0
var stamina_regen_multiplier: float = 1.0

var armor: float = 0.0
var magic_resist: float = 0.0

var phys_damage_multiplier: float = 1.0
var magic_damage_multiplier: float = 1.0
var melee_damage: float = 20.0
var crit_chance: float = 0.05
var crit_damage_mult: float = 2.0

var speed_multiplier: float = 1.0
var jump_multiplier: float = 1.0

var fire_rate_multiplier: float = 1.0
var reload_speed_multiplier: float = 1.0
var magazine_size_multiplier: float = 1.0
var recoil_multiplier: float = 1.0
var spread_multiplier: float = 1.0

var luck: float = 1.0


var current_friendly_chance: float = 0.0
var plunger_chance: float = 0.0
var bleed_chance: float = 0.0
var shishkin_chance: float = 0.0

var exp_multiplier: float = 1.0
var pickup_radius_mult: float = 1.0
var thorns_damage_mult: float = 0.0
var has_worms: bool = false
var buyanov_desync: bool = false
var natalia_iron_chance: float = 0.0
var bread_chance: float = 0.0
var kamikaze_chance: float = 0.0
var playboy_chance: float = 0.0
var justice_hammer_count: int = 0
var midas_touch_count: int = 0
var whip_count: int = 0
var gambling_machine_count: int = 0
var dep_machine_count: int = 0
var condoms_count: int = 0

var active_diary_buffs: Array = []
var medpolis_room_counter: int = 0
var lightbulb_count: int = 0
var panties_count: int = 0
var cologne_count: int = 0
var soldering_iron_count: int = 0

var inventory: Dictionary = {}
var collected_items: Array = []

var current_level: int = 1
const MAX_LEVELS: int = 10

var map_layout: Array[Vector2] = []
var discovered_rooms: Array[Vector2] = []
var boss_room_pos: Vector2 = Vector2.ZERO
var gold_room_pos: Vector2 = Vector2.ZERO
var shop_room_pos: Vector2 = Vector2.ZERO
var current_room_pos: Vector2 = Vector2.ZERO

var cached_player_node: Node3D = null

var meta_crystals: int = 0
var meta_upgrades = {
	"health": 0, "damage": 0, "speed": 0, "fire_rate": 0, 
	"crit_chance": 0, "crit_damage": 0, "armor": 0, 
	"accuracy": 0, "recoil": 0, "melee_damage": 0, "luck": 0, 
	"reload_speed": 0, "magazine_size": 0
}
var selected_starting_perk: String = "none"

var resolution_index: int = 0
var is_fullscreen: bool = false
var brightness: float = 1.0
var anti_aliasing: int = 0
var graphics_quality: int = 1
var vsync: bool = true

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var mouse_sensitivity: float = 0.003
var crosshair_color: Color = Color(0, 1, 0, 1)
var crosshair_length: float = 10.0
var crosshair_thickness: float = 2.0
var crosshair_base_gap: float = 5.0
var crosshair_dot: bool = true

var keybinds: Dictionary = {
	"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, 
	"jump": KEY_SPACE, "crouch": KEY_CTRL, "sprint": KEY_SHIFT, "reload": KEY_R, "interact": KEY_E
}
const SETTINGS_FILE = "user://settings.cfg"

var weapons_db: Dictionary = {
	"pistol": {"name": "ПИСТОЛЕТ M1911", "dmg": 12, "ammo": 15, "fire_rate": 0.25, "reload": 1.5, "recoil": "НИЗКАЯ", "pellets": 1, "spread": 0.0, "scene": null}, 
	"rifle": {"name": "ШТУРМОВАЯ ВИНТОВКА", "dmg": 7, "ammo": 40, "fire_rate": 0.12, "reload": 2.2, "recoil": "СРЕДНЯЯ", "pellets": 1, "spread": 0.02, "scene": null}, 
	"shotgun": {"name": "ПОМПОВЫЙ ДРОБОВИК", "dmg": 10, "ammo": 8, "fire_rate": 1.0, "reload": 3.0, "recoil": "ВЫСОКАЯ", "pellets": 8, "spread": 0.08, "scene": null}
}

var music_player: AudioStreamPlayer
var current_track_state: String = ""
var music_tween: Tween = null
var force_fade: bool = false

var menu_music = preload("res://Assets/Music/TopSecretDemo.mp3")
var ambient_music = preload("res://Assets/Music/AmbientG.mp3")
var boss_music = preload("res://Assets/Music/Glavniyhuy.mp3")

var global_brightness_overlay: ColorRect




var item_database = {
	"baby_oil": {"name": "ДЕТСКОЕ МАСЛО", "desc": "ОСТАВЛЯЕТ СКОЛЬЗКИЙ СЛЕД"}, 
	"mge_photo": {"name": "ФОТО МГЕ БРАТА", "desc": "УДАЧА: +5\nСИНЕРГИЯ С БРОНЕЙ"}, 
	"chingis_eggs": {"name": "ТРИ ЯЙЦА ЧИНГИСХАНА", "desc": "УДАЧА: x3\nМАГ. ЗАЩИТА: +3"}, 
	"plunger": {"name": "ВАНТУЗ", "desc": "ШАНС ВЫСТРЕЛА ВАНТУЗОМ: 15%\nОГЛУШЕНИЕ: 1.5 СЕК."}, 
	"maduro_drink": {"name": "НАПИТОК МАДУРО", "desc": "СКОРОСТЬ ДВИЖЕНИЯ: +10%"}, 
	"diary": {"name": "ЕЖЕДНЕВНИК", "desc": "ПРИ УРОНЕ: СЛУЧАЙНЫЙ БАФФ (2 МИН.)"}, 
	"nails": {"name": "ГВОЗДИ", "desc": "ШАНС КРОВОТЕЧЕНИЯ: 5%\nУРОН: 2% ОТ МАКС. ХП/СЕК"}, 
	"medpolis": {"name": "МЕДПОЛИС", "desc": "КАЖДАЯ 5-Я ЗАЧИЩЕННАЯ КОМНАТА\nГАРАНТИРУЕТ АПТЕЧКУ"}, 
	"rubiks_cube": {"name": "КУБИК РУБИКА", "desc": "АНОМАЛЬНЫЙ УРОН: +5%\nАНОМАЛЬНАЯ ЗАЩИТА: +5%"}, 
	"gold_chain": {"name": "ЗОЛОТАЯ ЦЕПОЧКА", "desc": "БЕЛАЯ ВЕЧЕРИНКА ВМЕСТО ЗОЛОТОЙ: +10%\nЕСЛИ УДАЧА >= 20, ШАНС СТАНЕТ 60%"}, 
	"lightbulb": {"name": "ЛАМПОЧКА", "desc": "ПОДСВЕЧИВАЕТ ЦЕЛЬ\nНАГРАДА ЗА УБИЙСТВО: +10$"}, 
	"shishkin": {"name": "ВСТАНИСЛАВ ШИШКИН", "desc": "ШАНС 2% ПРЕВРАТИТЬ ВРАГА\nВ СМЕРТЕЛЬНЫЙ СНАРЯД"}, 
	"panties": {"name": "ИСПОЛЬЗОВАННЫЕ ТРУСЫ", "desc": "ТОКСИЧНАЯ АУРА (-30% УРОНА ВРАГОВ)\nБОССЫ СТАНОВЯТСЯ СИЛЬНЕЕ (+50% УРОНА)"}, 
	"cologne": {"name": "ОДЕКОЛОН XXX", "desc": "ШАНС 30% ПРИЗВАТЬ НАКАЧЕННОГО МЕДИКА\nОН БУДЕТ ВАС ЛЕЧИТЬ"}, 
	"xbox_gamepad": {"name": "ПУЛЬТ УПРАВЛЕНИЯ 'ЗАПАД'", "desc": "ЗАЩИТА (КИНЕТИКА/АНОМАЛИИ): +50%"}, 
	"ps_gamepad": {"name": "ПУЛЬТ УПРАВЛЕНИЯ 'ВОСТОК'", "desc": "УРОН (КИНЕТИКА/АНОМАЛИИ): +50%"}, 
	"huy_yogurt": {"name": "ЙОГУРТ 'Х.У.Й.'", "desc": "МАКСИМАЛЬНЫЙ ЭНЕРГОЗАПАС: +100 ЕД."}, 
	"soldering_iron": {"name": "ПАЯЛЬНИК", "desc": "ОСТАВЛЯЕТ ОГНЕННЫЙ ШЛЕЙФ\nУРОН: 1% МАКС. ХП/СЕК"}, 
	"natalia_iron": {"name": "УТЮГ НАТАЛЬЯ", "desc": "ШВЫРЯЕТ УТЮГ (25%)\nСТЯГИВАЕТ ВРАГОВ В ЧЕРНУЮ ДЫРУ"}, 
	"gambling_machine": {"name": "ГЭМБЛИНГ МАШИНА", "desc": "СТЯГИВАЕТ ВРАГОВ\nДЛЯ ДОДЕПА (7%)"}, 
	"dep_machine": {"name": "ДЭП МАШИНА", "desc": "РАНДОМНЫЙ БАФФ ИЛИ ДЕБАФФ\nВ НАЧАЛЕ ЭТАЖА"}, 
	"worms": {"name": "ГЛИСТЫ", "desc": "МАКС ХП -20%. АПТЕЧКИ НЕ РАБОТАЮТ.\nСПАВНИТ ГЛИСТОВ-ЛЕКАРЕЙ."}, 
	"gaben_mom_grave": {"name": "МОГИЛА МАТЕРИ ГАБЕНА", "desc": "СКОРОСТЬ -35%\nС ПРОТИВНИКОВ ПАДАЕТ ТОННА ЗОЛОТА"}, 
	"whip": {"name": "НЕЙРО-ХЛЫСТ", "desc": "ПОВЫШЕННЫЙ УРОН ПО БРОНИРОВАННЫМ\nИ ТЕНЕВЫМ ВРАГАМ"}, 
	"kamikaze_implant": {"name": "БРАКОВАННЫЙ ИМПЛАНТ", "desc": "ВРАГИ МОГУТ ВЗОРВАТЬСЯ\nИ ПОБЕЖАТЬ В СВОИХ (5%)"}, 
	"condoms": {"name": "ГАНДОНЫ", "desc": "ВРАГИ МОГУТ НЕ ПОЯВИТЬСЯ\nВ КОМНАТЕ (ДЕМ. КРИЗИС)"}, 
	"playboy": {"name": "ЖУРНАЛ ПЛЕЙБОЙ", "desc": "ПРИ ПОЛУЧЕНИИ УРОНА\nОТВЛЕКАЕТ ВСЕХ ВРАГОВ НА 3 СЕК"}, 
	"buyanov_dumplings": {"name": "ПЕЛЬМЕНИ ОТ БУЯНОВА", "desc": "МГНОВЕННЫЙ 100% ХИЛ\nПУЛИ ВЫЛЕТАЮТ С РАССИНХРОНОМ"}, 
	"monkey_king_stick": {"name": "ДРЫН КОРОЛЯ ОБЕЗЬЯН", "desc": "УРОН -35%. СКОР. АТАКИ +10%\nДОП. МАГ УРОН +10%"}, 
	"pilot": {"name": "ВЫ РЕШИЛИ СТАТЬ ПИЛОТОМ", "desc": "ОПЫТ +40%\nСКОРОСТЬ -10%"}, 
	"maxim_kiss": {"name": "ГУБКИ 'ПОЦЕЛУЙ МАКСИМА'", "desc": "РАДИУС ПОДБОРА +50%\nМАГ. РЕЗИСТ -5"}, 
	"bdsm_suit": {"name": "БДСМ КОСТЮМ", "desc": "ОТРАЖАЕТ 20% УРОНА\nБРОНЯ +15"}, 
	"midas_touch": {"name": "КАСАНИЕ МИДАСА", "desc": "ВРАГИ РЯДОМ ДАЮТ ДОП. ЗОЛОТО"}, 
	"tea_bag": {"name": "ПАКЕТИК ЧАЯ", "desc": "СКОРОСТЬ АТАКИ +10%\n[СТАК >10]: ЧАЕПИТИЕ (+СКОРОСТЬ)"}, 
	"fake_vodka": {"name": "ПАЛЁНАЯ ВОДКА", "desc": "Ну, чтоб руки не дрожали. ТОЧНОСТЬ +15%\n[СТАК >3]: БЕЛОЧКА (+УРОН, -ТОЧНОСТЬ)"}, 
	"shpringles": {"name": "ШПРИНГЛС", "desc": "УРОН +5%\n[СТАК =10]: ВЗРЫВНЫЕ ЧИПСЫ"}, 
	"bone": {"name": "КОСТЬ", "desc": "Плохое время. МАКС ХП -15\n[СТАК >5]: ПЛОХОЕ ВРЕМЯ (+ОГРОМНЫЙ УРОН)"}, 
	"red_scarf": {"name": "КРАСНЫЙ ШАРФ", "desc": "У ТЕБЯ ТЕПЕРЬ БОЛЬШАЯ КОСТЬ\nУРОН +10%, СКОРОСТЬ -5%"}, 
	"justice_hammer": {"name": "МОЛОТ СПРАВЕДЛИВОСТИ", "desc": "РАЗ В 15 СЕК КАРАЕТ\nВРАГА УРОНОМ 3.3x"}, 
	"cucumber": {"name": "ОГУРЕЦ", "desc": "Довольно скользкий и гладкий.\nОТДАЧА -5%, СКОРОСТЬ АТАКИ +10%"}, 
	"lentil_soup": {"name": "ЧЕЧЕВИЧНАЯ ПОХЛЁБКА", "desc": "Теперь ты старше меня.\nМАКС ХП +10, СКОРОСТЬ +10%, УРОН +10%"}, 
	"bread": {"name": "ХЛЕБ", "desc": "Эксперимент не был провальным.\nШАНС ВЫСТРЕЛА МЯКИШЕМ (АГРО)"}, 
	"fork": {"name": "ВИЛКА", "desc": "Вилкой в глаз...\nСКОРОСТЬ -10%, МАГ. УРОН +10%"}
}


var item_scene_map = {
	"res://Scenes/Item_Baby_Oil.tscn": "baby_oil", 
	"res://Scenes/Item_MGE_Photo.tscn": "mge_photo", 
	"res://Scenes/Item_Chingis_Eggs.tscn": "chingis_eggs", 
	"res://Scenes/Item_Plunger.tscn": "plunger", 
	"res://Scenes/Item_Maduro_Drink.tscn": "maduro_drink", 
	"res://Scenes/Item_Diary.tscn": "diary", 
	"res://Scenes/Item_Nails.tscn": "nails", 
	"res://Scenes/Item_Medpolis.tscn": "medpolis", 
	"res://Scenes/Item_Rubiks_Cube.tscn": "rubiks_cube", 
	"res://Scenes/Item_Gold_Chain.tscn": "gold_chain", 
	"res://Scenes/Item_Lightbulb.tscn": "lightbulb", 
	"res://Scenes/Item_Shishkin.tscn": "shishkin", 
	"res://Scenes/Item_Panties.tscn": "panties", 
	"res://Scenes/Item_Cologne.tscn": "cologne", 
	"res://Scenes/Item_Xbox_Gamepad.tscn": "xbox_gamepad", 
	"res://Scenes/Item_PS_Gamepad.tscn": "ps_gamepad", 
	"res://Scenes/Item_Huy_Yogurt.tscn": "huy_yogurt", 
	"res://Scenes/Item_Soldering_Iron.tscn": "soldering_iron"
}

var item_pool = [
	[preload("res://Scenes/Item_Baby_Oil.tscn"), 50], 
	[preload("res://Scenes/Item_MGE_Photo.tscn"), 50], 
	[preload("res://Scenes/Item_Chingis_Eggs.tscn"), 20], 
	[preload("res://Scenes/Item_Plunger.tscn"), 30], 
	[preload("res://Scenes/Item_Maduro_Drink.tscn"), 40], 
	[preload("res://Scenes/Item_Diary.tscn"), 30], 
	[preload("res://Scenes/Item_Nails.tscn"), 40], 
	[preload("res://Scenes/Item_Medpolis.tscn"), 35], 
	[preload("res://Scenes/Item_Rubiks_Cube.tscn"), 40], 
	[preload("res://Scenes/Item_Gold_Chain.tscn"), 25], 
	[preload("res://Scenes/Item_Lightbulb.tscn"), 35], 
	[preload("res://Scenes/Item_Shishkin.tscn"), 25], 
	[preload("res://Scenes/Item_Panties.tscn"), 30], 
	[preload("res://Scenes/Item_Cologne.tscn"), 35], 
	[preload("res://Scenes/Item_Xbox_Gamepad.tscn"), 30], 
	[preload("res://Scenes/Item_PS_Gamepad.tscn"), 30], 
	[preload("res://Scenes/Item_Huy_Yogurt.tscn"), 35], 
	[preload("res://Scenes/Item_Soldering_Iron.tscn"), 35]
]

var total_item_weight: int = 0

func _ready():
	get_tree().root.gui_embed_subwindows = true

	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		var b_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(b_idx, "Music")
		AudioServer.set_bus_send(b_idx, "Master")

	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		var b_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(b_idx, "SFX")
		AudioServer.set_bus_send(b_idx, "Master")

	if "++auto-test" in OS.get_cmdline_args():
		is_auto_test = true
		Engine.time_scale = 5.0
		call_deferred("_skip_menu")

	var canvas = CanvasLayer.new()
	canvas.layer = 128
	global_brightness_overlay = ColorRect.new()
	global_brightness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	global_brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	global_brightness_overlay.color = Color(0, 0, 0, 0)
	canvas.add_child(global_brightness_overlay)
	add_child(canvas)

	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	for item in item_pool:
		total_item_weight += item[1]

	get_tree().node_added.connect(_on_node_added)

	load_settings()
	load_game()
	load_meta_data()

func _get_player() -> Node3D:
	if not is_instance_valid(cached_player_node):
		cached_player_node = get_tree().get_first_node_in_group("player")
	return cached_player_node

func _on_node_added(node: Node):
	if node is WorldEnvironment:
		call_deferred("apply_graphics_settings")


	if node is CollisionObject3D:
		var scene_path = node.scene_file_path
		if scene_path != "" and item_scene_map.has(scene_path):
			call_deferred("_inject_item_logic", node, item_scene_map[scene_path])

func _inject_item_logic(node: Node, id: String):
	if node.has_meta("item_injected"): return
	node.set_meta("item_injected", true)

	var script = preload("res://Scripts/interactable_item.gd")

	if script:
		node.set_script(script)
		if node.has_method("_init_item"):
			node._init_item(id)

func _skip_menu():
	var game_scene_path = "res://Scenes/level_generator.tscn"
	reset_run()
	get_tree().change_scene_to_file(game_scene_path)





func get_final_max_health() -> float:
	return max(1.0, (base_max_health + bonus_max_health) * health_multiplier)

func get_final_max_mana() -> float:
	return max(0.0, (base_max_mana + bonus_max_mana) * mana_multiplier)

func get_final_max_stamina() -> float:
	return max(10.0, (base_max_stamina + bonus_max_stamina) * stamina_multiplier)

func get_final_stamina_regen() -> float:
	return max(5.0, (base_stamina_regen + bonus_stamina_regen) * stamina_regen_multiplier)

func get_final_speed(weapon_base_speed: float) -> float:
	return max(2.5, weapon_base_speed * speed_multiplier)

func get_final_jump(weapon_base_jump: float) -> float:
	return weapon_base_jump * jump_multiplier

func get_final_phys_damage(weapon_base_dmg: float) -> float:
	return weapon_base_dmg * phys_damage_multiplier

func get_final_magic_damage(base_magic_dmg: float) -> float:
	return base_magic_dmg * magic_damage_multiplier

func get_final_fire_rate(weapon_base_rate_delay: float) -> float:
	return weapon_base_rate_delay / max(0.1, fire_rate_multiplier)

func get_final_mag_size(weapon_base_mag: int) -> int:
	return max(1, int(weapon_base_mag * magazine_size_multiplier))

func get_final_friendly_chance() -> float:
	var chance = current_friendly_chance
	if inventory.has("mge_photo") and armor >= 3.0:
		chance += 0.25
	return chance

func get_white_party_chance() -> float:
	if not inventory.has("gold_chain"):
		return 0.0
	if luck >= 20.0:
		return 0.6
	return 0.1 * inventory["gold_chain"]


func get_enemy_hp_multiplier() -> float:

	return pow(1.3, current_level - 1)

func get_enemy_dmg_multiplier() -> float:

	return 1.0 + ((current_level - 1) * 0.15)

func get_enemy_count_multiplier() -> float:

	return 1.0 + ((current_level - 1) * 0.15)

func get_inflated_price(base_price: int) -> int:

	var level_tax = (current_level - 1) * 0.1
	var final_price = int(base_price * (total_market_mult + level_tax))
	return max(1, final_price)

func play_menu_music():
	if current_track_state == "menu": return
	current_track_state = "menu"
	_start_track(menu_music, 0.0)

func play_ambient_music():
	if current_track_state == "ambient": return
	current_track_state = "ambient"
	_start_track(ambient_music, -5.0)

func play_boss_music():
	if current_track_state == "boss": return
	current_track_state = "boss"
	_start_track(boss_music, 5.0)

func _start_track(stream_resource, target_vol):
	if music_tween and music_tween.is_valid():
		music_tween.kill()

	if music_player.stream != stream_resource:
		music_player.stream = stream_resource
		music_player.volume_db = target_vol
		music_player.play()
	else:
		music_player.volume_db = target_vol
		if not music_player.playing:
			music_player.play()

func _on_music_finished():
	if current_track_state in ["menu", "ambient", "boss"]:
		music_player.play()

func fade_out_music():
	var current_scene = get_tree().current_scene
	if not force_fade and current_scene and current_scene.name != "MainMenu" and current_track_state != "boss":
		return

	current_track_state = "fade"
	if not music_player.playing: return

	if music_tween and music_tween.is_valid():
		music_tween.kill()

	music_tween = get_tree().create_tween()
	music_tween.tween_property(music_player, "volume_db", -50.0, 1.5)
	music_tween.tween_callback(music_player.stop)

func play_combat_music():
	play_ambient_music()

func _process(delta: float):
	var current_scene = get_tree().current_scene

	if not current_scene or current_scene.name == "MainMenu":
		return

	run_time += delta

	if current_track_state == "menu":
		play_ambient_music()

	if ex:
		reset_run()
		ex = false

	market_timer += delta
	if market_timer >= 1.0:
		market_timer -= 1.0
		_update_market()

	if active_diary_buffs.size() > 0:
		for i in range(active_diary_buffs.size() - 1, -1, -1):
			var buff = active_diary_buffs[i]
			buff["time"] -= delta
			if buff["time"] <= 0:
				match buff["stat"]:
					"damage": phys_damage_multiplier -= buff["value"]
					"speed": speed_multiplier -= buff["value"]
					"fire_rate": fire_rate_multiplier -= buff["value"]
					"crit": crit_chance -= buff["value"]
					"armor": armor -= buff["value"]
				active_diary_buffs.remove_at(i)

				var p_node = _get_player()
				if p_node and p_node.has_method("show_notification"):
					p_node.show_notification("ЭФФЕКТ ЕЖЕДНЕВНИКА ИСТЕК", Color(0.5, 0.5, 0.5))

func _update_market():
	var time_in_minutes = run_time / 60.0
	var time_inflation_penalty = time_in_minutes * 0.05
	var wealth_penalty = float(money) / 1000.0

	var baseline = current_market_mult + time_inflation_penalty + wealth_penalty
	var noise = randf_range(-0.03, 0.03)

	total_market_mult = clamp(baseline + noise, 0.5, 3.0)
	market_history.append(total_market_mult)
	if market_history.size() > 50:
		market_history.pop_front()

func trigger_shop_purchase_inflation():
	current_market_mult += 0.02

func save_game():
	var config = ConfigFile.new()
	config.set_value("Save", "selected_weapon", selected_weapon)
	config.save(SAVE_PATH)

func load_game():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		selected_weapon = config.get_value("Save", "selected_weapon", "pistol")
		if selected_weapon == "knife":
			selected_weapon = "pistol"
		current_weapon_type = selected_weapon

func get_random_item_scene():
	if item_pool.is_empty(): return null
	var roll = randi_range(0, total_item_weight - 1)
	var current_weight = 0
	for item in item_pool:
		current_weight += item[1]
		if roll < current_weight:
			return item[0]
	return item_pool[0][0]




var active_synergies: Dictionary = {}

func add_item(item_id: String):
	inventory[item_id] = inventory.get(item_id, 0) + 1
	collected_items.append(item_id)

	var player = _get_player()
	apply_item_effects(item_id, player)

	inventory_updated.emit()

func apply_item_effects(item_id: String, player: Node = null):
	var count = inventory.get(item_id, 1)

	match item_id:
		"baby_oil": if player: player.set("has_baby_oil", true)
		"mge_photo": luck += 5.0
		"chingis_eggs": luck *= 3.0;magic_resist += 3.0
		"plunger": plunger_chance += 0.15
		"maduro_drink": speed_multiplier += 0.1
		"nails": bleed_chance += 0.05
		"rubiks_cube": magic_damage_multiplier += 0.05;magic_resist += 5.0
		"lightbulb": lightbulb_count += 1
		"shishkin": shishkin_chance += 0.02
		"panties": panties_count += 1; if player and player.has_method("update_panties_aura"): player.update_panties_aura()
		"cologne": cologne_count += 1
		"xbox_gamepad": armor += 15.0;magic_resist += 15.0
		"ps_gamepad": phys_damage_multiplier += 0.5;magic_damage_multiplier += 0.5
		"huy_yogurt": bonus_max_mana += 100.0; if player and player.has_method("heal_mana"): player.heal_mana(100.0)
		"soldering_iron": soldering_iron_count += 1

		"natalia_iron": natalia_iron_chance += 0.25
		"gambling_machine": gambling_machine_count += 1
		"dep_machine": dep_machine_count += 1
		"worms":
			if not has_worms:
				has_worms = true
				health_multiplier -= 0.2
		"gaben_mom_grave": speed_multiplier -= 0.35
		"whip": whip_count += 1
		"kamikaze_implant": kamikaze_chance += 0.05
		"condoms": condoms_count += 1
		"playboy": playboy_chance += 0.15
		"buyanov_dumplings":
			if player and player.has_method("heal"): player.heal(9999)
			buyanov_desync = true
		"monkey_king_stick":
			phys_damage_multiplier -= 0.35
			fire_rate_multiplier += 0.2
			magic_damage_multiplier += 0.1
		"pilot":
			exp_multiplier += 0.4
			speed_multiplier -= 0.1
		"maxim_kiss":
			pickup_radius_mult += 0.5
			magic_resist -= 5.0
		"bdsm_suit":
			thorns_damage_mult += 0.2
			armor += 15.0
		"midas_touch": midas_touch_count += 1
		"red_scarf":
			phys_damage_multiplier += 0.1
			speed_multiplier -= 0.05
		"justice_hammer": justice_hammer_count += 1
		"cucumber":
			recoil_multiplier -= 0.1
			fire_rate_multiplier += 0.1
		"lentil_soup":
			bonus_max_health += 10.0
			speed_multiplier += 0.1
			phys_damage_multiplier += 0.1
			armor += 5.0
		"bread": bread_chance += 0.17
		"fork":
			speed_multiplier -= 0.1
			magic_damage_multiplier += 0.1


		"tea_bag":
			fire_rate_multiplier += 0.05
			if count == 10:
				speed_multiplier += 0.2
				if player and player.has_method("show_notification"):
					player.show_notification("ЧАЕПИТИЕ: СКОРОСТЬ ++", Color.GREEN)

		"fake_vodka":
			if count <= 3:
				recoil_multiplier -= 0.15
				spread_multiplier -= 0.15
			elif count == 4:
				recoil_multiplier += 0.4
				phys_damage_multiplier += 0.4
				speed_multiplier -= 0.15
				if player and player.has_method("show_notification"):
					player.show_notification("БЕЛОЧКА: УРОН ++, ТОЧНОСТЬ --", Color.RED)

		"shpringles":
			phys_damage_multiplier += 0.05
			if count == 10:
				if player and player.has_method("show_notification"):
					player.show_notification("ШПРИНГЛС: АКТИВИРОВАНЫ ВЗРЫВНЫЕ ЧИПСЫ", Color.YELLOW)

		"bone":
			bonus_max_health -= 15.0
			if count == 6:
				phys_damage_multiplier += 0.4
				if player and player.has_method("show_notification"):
					player.show_notification("ПЛОХОЕ ВРЕМЯ: ОГРОМНЫЙ УРОН", Color.PURPLE)

	check_synergies()

	if player and player.has_method("recalculate_stats"):
		player.recalculate_stats()

func check_synergies():
	if inventory.has("baby_oil") and inventory.has("soldering_iron"):
		active_synergies["napalm"] = true

	if inventory.has("xbox_gamepad") and inventory.has("ps_gamepad"):
		if not active_synergies.has("crossplatform"):
			active_synergies["crossplatform"] = true
			phys_damage_multiplier += 1.0
			armor += 30.0
			get_tree().call_group("player_hud", "hide")

	if inventory.has("worms") and inventory.has("buyanov_dumplings"):
		if not active_synergies.has("deworming"):
			active_synergies["deworming"] = true
			health_multiplier += 0.2
			has_worms = false
			inventory.erase("worms")
			var p = _get_player()
			if p and p.has_method("show_notification"):
				p.show_notification("ДЕГЕЛЬМИНТИЗАЦИЯ: ГЛИСТЫ УНИЧТОЖЕНЫ", Color.AQUA)

	if get_final_speed(5.0) <= 2.5:
		if not active_synergies.has("wheelchair"):
			active_synergies["wheelchair"] = true
			jump_multiplier = 0.0
			var p = _get_player()
			if p and p.has_method("show_notification"):
				p.show_notification("РЕЖИМ КОЛЯСОЧНИКА: ПРЫЖКИ ОТКЛЮЧЕНЫ", Color.RED)


func trigger_diary_effect():
	if not inventory.has("diary"): return
	if active_diary_buffs.size() > 0: return

	var stats = ["damage", "speed", "fire_rate", "crit", "armor"]
	var chosen = stats.pick_random()
	var value = 0.0
	var text = ""

	match chosen:
		"damage":
			value = 0.2
			text = "УРОН +20%!"
			phys_damage_multiplier += value
		"speed":
			value = 0.15
			text = "СКОРОСТЬ +15%!"
			speed_multiplier += value
		"fire_rate":
			value = 0.2
			text = "СКОРОСТРЕЛЬНОСТЬ +20%!"
			fire_rate_multiplier += value
		"crit":
			value = 0.15
			text = "ШАНС КРИТА +15%!"
			crit_chance += value
		"armor":
			value = 10.0
			text = "БРОНЯ +10!"
			armor += value

	active_diary_buffs.append({"stat": chosen, "value": value, "time": 120.0})

	var player = _get_player()
	if player:
		if player.has_method("show_notification"):
			player.show_notification("ЕЖЕДНЕВНИК: " + text, Color(0.8, 0.2, 1.0))
		if player.has_method("recalculate_stats"):
			player.recalculate_stats()

func convert_score_to_crystals():
	var earned = int(score / 10.0)
	if earned > 0:
		meta_crystals += earned
		save_meta_data()

func save_meta_data():
	var file = FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"meta_crystals": meta_crystals, 
			"meta_upgrades": meta_upgrades
		}
		file.store_var(data)

func load_meta_data():
	if FileAccess.file_exists(META_SAVE_PATH):
		var file = FileAccess.open(META_SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if typeof(data) == TYPE_DICTIONARY:
				meta_crystals = data.get("meta_crystals", 0)
				var saved_upgrades = data.get("meta_upgrades", {})
				for key in meta_upgrades.keys():
					if saved_upgrades.has(key):
						meta_upgrades[key] = saved_upgrades[key]

	apply_meta_upgrades_to_base_stats()

func apply_meta_upgrades_to_base_stats():
	base_max_health = 100.0 * (1.0 + (meta_upgrades.get("health", 0) * 0.1))
	phys_damage_multiplier = 1.0 * (1.0 + (meta_upgrades.get("damage", 0) * 0.1))
	speed_multiplier = 1.0 + (meta_upgrades.get("speed", 0) * 0.1)
	fire_rate_multiplier = 1.0 + (meta_upgrades.get("fire_rate", 0) * 0.1)
	melee_damage = 50.0 * (1.0 + (meta_upgrades.get("melee_damage", 0) * 0.1))
	armor = 0.0 + (meta_upgrades.get("armor", 0) * 2.0)
	crit_chance = 0.05 + (meta_upgrades.get("crit_chance", 0) * 0.02)
	crit_damage_mult = 2.0 + (meta_upgrades.get("crit_damage", 0) * 0.2)
	spread_multiplier = 1.0 - (meta_upgrades.get("accuracy", 0) * 0.05)
	recoil_multiplier = 1.0 - (meta_upgrades.get("recoil", 0) * 0.05)
	luck = 1.0 + (meta_upgrades.get("luck", 0) * 0.1)
	reload_speed_multiplier = 1.0 + (meta_upgrades.get("reload_speed", 0) * 0.1)
	magazine_size_multiplier = 1.0 + (meta_upgrades.get("magazine_size", 0) * 0.15)




func spawn_from_pool(pool_name: String, scene_to_instantiate: PackedScene, pos: Vector3, parent_node: Node) -> Node3D:
	if not _pools.has(pool_name):
		_pools[pool_name] = []

	var current_pool = _pools[pool_name]

	for obj in current_pool:
		if is_instance_valid(obj) and not obj.visible:
			obj.global_position = pos
			obj.set_deferred("visible", true)
			obj.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			if obj is RigidBody3D:
				obj.set_deferred("freeze", false)
			return obj

	var max_objects = 50
	if current_pool.size() >= max_objects:
		var oldest = current_pool.pop_front()
		if is_instance_valid(oldest):
			oldest.global_position = pos
			oldest.set_deferred("visible", true)
			oldest.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			if oldest is RigidBody3D:
				oldest.set_deferred("freeze", false)
			current_pool.push_back(oldest)
			return oldest

	if scene_to_instantiate:
		var new_obj = scene_to_instantiate.instantiate()
		parent_node.add_child(new_obj)
		new_obj.global_position = pos
		current_pool.push_back(new_obj)
		return new_obj

	return null

func despawn_to_pool(obj: Node3D):
	if is_instance_valid(obj):
		obj.set_deferred("visible", false)
		obj.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

		if obj is RigidBody3D:
			obj.set_deferred("freeze", true)

		if obj is GPUParticles3D:
			obj.set_deferred("emitting", false)




func spawn_damage_number(amount: int, start_pos: Vector3, is_crit: bool = false, root_node: Node = null):

	if not show_damage_numbers:
		return

	if not root_node:
		root_node = get_tree().current_scene
		if not root_node: return

	var lbl = spawn_from_pool("damage_numbers", null, start_pos, root_node)

	if not lbl:
		lbl = Label3D.new()
		root_node.add_child(lbl)

		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.pixel_size = 0.015
		lbl.font_size = 72
		lbl.outline_size = 18

		lbl.render_priority = 100

		if not _pools.has("damage_numbers"):
			_pools["damage_numbers"] = []
		_pools["damage_numbers"].append(lbl)

	lbl.global_position = start_pos + Vector3(randf_range(-0.6, 0.6), randf_range(-0.2, 0.5), randf_range(-0.6, 0.6))
	lbl.set_deferred("visible", true)

	lbl.text = str(amount)
	lbl.modulate.a = 1.0

	if is_crit:
		lbl.modulate = Color(1.0, 0.85, 0.1)
		lbl.outline_modulate = Color(0.2, 0.0, 0.0)
		lbl.render_priority = 110
	else:
		lbl.modulate = Color(1.0, 1.0, 1.0)
		lbl.outline_modulate = Color(0.0, 0.0, 0.0)
		lbl.render_priority = 100

	var tw = lbl.create_tween().set_parallel(true)

	lbl.scale = Vector3.ZERO
	var target_scale = Vector3(1.3, 1.3, 1.3) if is_crit else Vector3(0.8, 0.8, 0.8)

	tw.tween_property(lbl, "scale", target_scale * 1.2, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", target_scale, 0.2).set_delay(0.1)

	var drift = Vector3(randf_range(-0.5, 0.5), randf_range(1.5, 2.5), randf_range(-0.5, 0.5))
	tw.tween_property(lbl, "global_position", lbl.global_position + drift, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tw.tween_property(lbl, "modulate:a", 0.0, 0.2).set_delay(0.5)

	tw.chain().tween_callback( func(): despawn_to_pool(lbl))


func reset_run():
	active_enemies.clear()

	for pool_name in _pools.keys():
		var pool_content = _pools[pool_name]
		if typeof(pool_content) == TYPE_ARRAY:
			for obj in pool_content:
				if is_instance_valid(obj) and obj is Node:
					obj.call_deferred("queue_free")
		elif typeof(pool_content) == TYPE_OBJECT:
			if is_instance_valid(pool_content) and pool_content is Node:
				pool_content.call_deferred("queue_free")

	_pools.clear()

	spawn_protection = true
	get_tree().create_timer(1.5).timeout.connect( func(): spawn_protection = false)

	score = 0
	current_level = 1
	money = 0
	run_time = 0.0
	player_health = -1.0
	player_mana = -1.0
	pistol_ammo = 15
	rifle_ammo = 40
	shotgun_ammo = 8

	market_history.clear()
	current_market_mult = 1.0
	total_market_mult = 1.0
	market_timer = 0.0


	bonus_max_health = 0.0
	health_multiplier = 1.0
	bonus_max_mana = 0.0
	mana_multiplier = 1.0
	bonus_max_stamina = 0.0
	stamina_multiplier = 1.0
	bonus_stamina_regen = 0.0
	stamina_regen_multiplier = 1.0

	armor = 0.0
	magic_resist = 0.0
	phys_damage_multiplier = 1.0
	magic_damage_multiplier = 1.0
	crit_chance = 0.05
	crit_damage_mult = 2.0
	speed_multiplier = 1.0
	jump_multiplier = 1.0
	fire_rate_multiplier = 1.0
	magazine_size_multiplier = 1.0
	recoil_multiplier = 1.0
	spread_multiplier = 1.0
	luck = 1.0

	apply_meta_upgrades_to_base_stats()


	exp_multiplier = 1.0
	pickup_radius_mult = 1.0
	thorns_damage_mult = 0.0
	has_worms = false
	buyanov_desync = false
	natalia_iron_chance = 0.0
	bread_chance = 0.0
	kamikaze_chance = 0.0
	playboy_chance = 0.0
	justice_hammer_count = 0
	midas_touch_count = 0
	whip_count = 0
	gambling_machine_count = 0
	dep_machine_count = 0
	condoms_count = 0
	active_synergies.clear()

	plunger_chance = 0.0
	bleed_chance = 0.0
	shishkin_chance = 0.0
	medpolis_room_counter = 0
	lightbulb_count = 0
	panties_count = 0
	cologne_count = 0
	soldering_iron_count = 0

	current_friendly_chance = 0.0
	match selected_starting_perk:
		"friendly_spawn":
			current_friendly_chance = 0.05

	inventory.clear()
	collected_items.clear()
	active_diary_buffs.clear()

	map_layout.clear()
	discovered_rooms.clear()
	current_room_pos = Vector2.ZERO
	boss_room_pos = Vector2.ZERO
	gold_room_pos = Vector2.ZERO
	shop_room_pos = Vector2.ZERO

	cached_player_node = null

	force_fade = true
	fade_out_music()
	force_fade = false




func apply_keybinds():
	for action in keybinds.keys():
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			var new_event = InputEventKey.new()
			new_event.physical_keycode = keybinds[action]
			InputMap.action_add_event(action, new_event)

func apply_audio_settings():
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		AudioServer.set_bus_mute(master_idx, master_volume <= 0.001)
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(max(0.0001, master_volume)))

	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, music_volume <= 0.001)
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(max(0.0001, music_volume)))

	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.001)
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(max(0.0001, sfx_volume)))

func apply_graphics_settings():
	call_deferred("_deferred_apply_graphics_settings")

func _deferred_apply_graphics_settings():
	var resolutions_array = [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(800, 600)]
	var target_size = resolutions_array[resolution_index] if resolution_index >= 0 and resolution_index < resolutions_array.size() else Vector2i(1920, 1080)

	var root = get_tree().root

	root.content_scale_size = target_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP

	if is_fullscreen:
		root.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		root.mode = Window.MODE_WINDOWED
		root.borderless = false
		root.size = target_size

		var screen_id = root.current_screen
		var screen_size = DisplayServer.screen_get_size(screen_id)
		@warning_ignore("integer_division")
		root.position = (screen_size / 2) - (target_size / 2)

	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		Engine.max_fps = 0
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 144

	match anti_aliasing:
		0:
			root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			root.msaa_3d = Viewport.MSAA_DISABLED
		1:
			root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			root.msaa_3d = Viewport.MSAA_DISABLED
		2:
			root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			root.msaa_3d = Viewport.MSAA_2X
		3:
			root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			root.msaa_3d = Viewport.MSAA_4X
		4:
			root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			root.msaa_3d = Viewport.MSAA_8X

	var base_3d_scale = 1.0
	match graphics_quality:
		0:
			base_3d_scale = 0.4
			root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			RenderingServer.directional_shadow_atlas_set_size(512, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			root.positional_shadow_atlas_size = 512

		1:
			base_3d_scale = 0.75
			root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			RenderingServer.directional_shadow_atlas_set_size(1024, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			root.positional_shadow_atlas_size = 1024

		2:
			base_3d_scale = 1.0
			root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
			root.positional_shadow_atlas_size = 4096

	root.scaling_3d_scale = base_3d_scale

	var env_nodes = root.find_children("*", "WorldEnvironment", true, false)
	for env_node in env_nodes:
		if env_node is WorldEnvironment and env_node.environment:
			var env = env_node.environment

			if not env.has_meta("orig_ambient_energy"):
				env.set_meta("orig_ambient_energy", env.ambient_light_energy)

			var base_energy = env.get_meta("orig_ambient_energy")
			var safe_energy = base_energy
			if safe_energy < 0.4:
				safe_energy = 0.6

			if graphics_quality == 0:
				env.ssao_enabled = false
				env.ssr_enabled = false
				env.glow_enabled = false
				env.sdfgi_enabled = false
				env.volumetric_fog_enabled = false
				env.ambient_light_energy = safe_energy * 1.2

			elif graphics_quality == 1:
				env.ssao_enabled = true
				env.ssr_enabled = false
				env.glow_enabled = true
				env.sdfgi_enabled = false
				env.volumetric_fog_enabled = false
				env.ambient_light_energy = safe_energy * 1.1

			else:
				env.ssao_enabled = true
				env.ssr_enabled = true
				env.glow_enabled = true
				env.ambient_light_energy = safe_energy

	if global_brightness_overlay:
		if brightness < 1.0:
			global_brightness_overlay.color = Color(0, 0, 0, 1.0 - brightness)
		elif brightness > 1.0:
			global_brightness_overlay.color = Color(1, 1, 1, (brightness - 1.0) * 0.5)
		else:
			global_brightness_overlay.color = Color(0, 0, 0, 0)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Graphics", "resolution_index", resolution_index)
	config.set_value("Graphics", "is_fullscreen", is_fullscreen)
	config.set_value("Graphics", "brightness", brightness)
	config.set_value("Graphics", "anti_aliasing", anti_aliasing)
	config.set_value("Graphics", "graphics_quality", graphics_quality)
	config.set_value("Graphics", "vsync", vsync)


	config.set_value("UI", "show_stats_as_percentage", show_stats_as_percentage)
	config.set_value("UI", "active_anim_type", active_anim_type)
	config.set_value("UI", "show_damage_numbers", show_damage_numbers)

	config.set_value("Graphics", "vhs_enabled", vhs_enabled)
	config.set_value("Graphics", "vhs_intensity", vhs_intensity)
	config.set_value("Graphics", "vhs_noise", vhs_noise)
	config.set_value("Graphics", "vhs_rgb", vhs_rgb)
	config.set_value("Graphics", "vhs_style", vhs_style)

	config.set_value("Audio", "master", master_volume)
	config.set_value("Audio", "music", music_volume)
	config.set_value("Audio", "sfx", sfx_volume)
	config.set_value("Mouse", "sensitivity", mouse_sensitivity)
	config.set_value("Crosshair", "color", crosshair_color)
	config.set_value("Crosshair", "length", crosshair_length)
	config.set_value("Crosshair", "thickness", crosshair_thickness)
	config.set_value("Crosshair", "base_gap", crosshair_base_gap)
	config.set_value("Crosshair", "dot", crosshair_dot)
	for action in keybinds.keys():
		config.set_value("Input", action, keybinds[action])
	config.save(SETTINGS_FILE)

func load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) == OK:
		resolution_index = config.get_value("Graphics", "resolution_index", 0)
		is_fullscreen = config.get_value("Graphics", "is_fullscreen", false)
		brightness = config.get_value("Graphics", "brightness", 1.0)
		anti_aliasing = config.get_value("Graphics", "anti_aliasing", 0)
		graphics_quality = config.get_value("Graphics", "graphics_quality", 1)
		vsync = config.get_value("Graphics", "vsync", true)


		show_stats_as_percentage = config.get_value("UI", "show_stats_as_percentage", true)
		active_anim_type = config.get_value("UI", "active_anim_type", -1)
		show_damage_numbers = config.get_value("UI", "show_damage_numbers", true)

		vhs_enabled = config.get_value("Graphics", "vhs_enabled", true)
		vhs_intensity = config.get_value("Graphics", "vhs_intensity", 1.0)
		vhs_noise = config.get_value("Graphics", "vhs_noise", 0.05)
		vhs_rgb = config.get_value("Graphics", "vhs_rgb", 0.1)
		vhs_style = config.get_value("Graphics", "vhs_style", 0)

		master_volume = config.get_value("Audio", "master", 1.0)
		music_volume = config.get_value("Audio", "music", 1.0)
		sfx_volume = config.get_value("Audio", "sfx", 1.0)
		mouse_sensitivity = config.get_value("Mouse", "sensitivity", 0.003)
		crosshair_color = config.get_value("Crosshair", "color", Color(0, 1, 0, 1))
		crosshair_length = config.get_value("Crosshair", "length", 10.0)
		crosshair_thickness = config.get_value("Crosshair", "thickness", 2.0)
		crosshair_base_gap = config.get_value("Crosshair", "base_gap", 5.0)
		crosshair_dot = config.get_value("Crosshair", "dot", true)
		for action in keybinds.keys():
			keybinds[action] = config.get_value("Input", action, keybinds[action])
	else:
		save_settings()

	apply_keybinds()
	apply_audio_settings()
	apply_graphics_settings()




var is_prewarmed: bool = false

var enemy_scene = preload("res://Scenes/enemy.tscn")
var ranged_enemy_scene = preload("res://Scenes/ranged_enemy.tscn")
var coin_scene = preload("res://Scenes/coin.tscn")

func warm_up_game():
	if is_prewarmed: return
	is_prewarmed = true

	var root = get_tree().current_scene
	if not root: return

	_prefill_pool("coins", coin_scene, 25, root)
	_prefill_pool("enemies", enemy_scene, 10, root)
	_prefill_pool("ranged_enemies", ranged_enemy_scene, 5, root)

	for i in range(30):
		spawn_damage_number(0, Vector3(0, -1000, 0), false, root)

	var camera = get_viewport().get_camera_3d()
	if not camera: return

	var warmup_room = Node3D.new()
	camera.add_child(warmup_room)
	warmup_room.position = Vector3(0, 0, -2.0)
	warmup_room.scale = Vector3(0.001, 0.001, 0.001)

	if enemy_scene: warmup_room.add_child(enemy_scene.instantiate())
	if ranged_enemy_scene: warmup_room.add_child(ranged_enemy_scene.instantiate())
	if coin_scene: warmup_room.add_child(coin_scene.instantiate())

	for p in warmup_room.find_children("*", "GPUParticles3D"):
		p.emitting = true

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	warmup_room.queue_free()

func _prefill_pool(pool_name: String, scene: PackedScene, count: int, root: Node):
	if not scene: return
	for i in range(count):
		var obj = scene.instantiate()
		root.add_child(obj)
		despawn_to_pool(obj)

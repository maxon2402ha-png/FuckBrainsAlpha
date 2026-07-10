extends ColorRect




const COLOR_BG = Color(0.01, 0.02, 0.01, 0.95)
const COLOR_GREEN = Color("#00ff41")
const COLOR_GREY = Color("#aaaaaa")
const COLOR_WARN = Color("#ff3333")
const COLOR_CYAN = Color("#00ffff")
const COLOR_SCROLL_BG = Color("#111111")
const COLOR_SCROLL_GRABBER = Color(0.8, 0.8, 0.8, 1.0)

const FONT_SIZE_CAT = 20
const FONT_SIZE_STAT = 16


@onready var map_draw_area = $MapDrawArea
@onready var items_grid = $ItemsPanel / MarginContainer / ItemsGrid
@onready var items_panel = $ItemsPanel
@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip / MarginContainer / Label

@onready var stats_panel = $StatsPanel
@onready var header_label = $StatsPanel / MarginContainer / StatsVBox / HeaderLabel
@onready var columns_hbox = $StatsPanel / MarginContainer / StatsVBox / ColumnsHBox
@onready var left_column = $StatsPanel / MarginContainer / StatsVBox / ColumnsHBox / LeftColumn
@onready var right_column = $StatsPanel / MarginContainer / StatsVBox / ColumnsHBox / RightColumn

var player_node: Node3D


var room_size = 50.0
var margin = 15.0
var map_offset_x = -50.0
var radar_angle: float = 0.0


var crt_overlay: ColorRect
var vhs_time = 0.0

var stats_list_content: VBoxContainer
var boot_tween: Tween
var animated_rows: Array = []
var base_panel_offset_l: float
var base_panel_offset_r: float

const BASE_PHYS_DAMAGE = 15.0
const BASE_MAGIC_DAMAGE = 10.0
const BASE_FIRE_RATE = 2.0
const BASE_RELOAD_SPEED = 2.0
const BASE_CRIT_DAMAGE = 200.0




var item_database = {
	"baby_oil": {"name": "ДЕТСКОЕ МАСЛО", "desc": "ОСТАВЛЯЕТ СКОЛЬЗКИЙ СЛЕД", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"mge_photo": {"name": "ФОТО МГЕ БРАТА", "desc": "УДАЧА: +5\nСИНЕРГИЯ С БРОНЕЙ", "scene": preload("res://Scenes/Item_MGE_Photo.tscn")}, 
	"chingis_eggs": {"name": "ТРИ ЯЙЦА ЧИНГИСХАНА", "desc": "УДАЧА: x3\nМАГ. ЗАЩИТА: +3", "scene": preload("res://Scenes/Item_Chingis_Eggs.tscn")}, 
	"plunger": {"name": "ВАНТУЗ", "desc": "ШАНС ВЫСТРЕЛА ВАНТУЗОМ: 15%\nОГЛУШЕНИЕ: 1.5 СЕК.", "scene": preload("res://Scenes/Item_Plunger.tscn")}, 
	"maduro_drink": {"name": "НАПИТОК МАДУРО", "desc": "СКОРОСТЬ ДВИЖЕНИЯ: +10%", "scene": preload("res://Scenes/Item_Maduro_Drink.tscn")}, 
	"diary": {"name": "ЕЖЕДНЕВНИК", "desc": "ПРИ УРОНЕ: СЛУЧАЙНЫЙ БАФФ (2 МИН.)", "scene": preload("res://Scenes/Item_Diary.tscn")}, 
	"nails": {"name": "ГВОЗДИ", "desc": "ШАНС КРОВОТЕЧЕНИЯ: 5%\nУРОН: 2% ОТ МАКС. ХП/СЕК", "scene": preload("res://Scenes/Item_Nails.tscn")}, 
	"medpolis": {"name": "МЕДПОЛИС", "desc": "КАЖДАЯ 5-Я ЗАЧИЩЕННАЯ КОМНАТА\nГАРАНТИРУЕТ АПТЕЧКУ", "scene": preload("res://Scenes/Item_Medpolis.tscn")}, 
	"rubiks_cube": {"name": "КУБИК РУБИКА", "desc": "АНОМАЛЬНЫЙ УРОН: +5%\nАНОМАЛЬНАЯ ЗАЩИТА: +5%", "scene": preload("res://Scenes/Item_Rubiks_Cube.tscn")}, 
	"gold_chain": {"name": "ЗОЛОТАЯ ЦЕПОЧКА", "desc": "БЕЛАЯ ВЕЧЕРИНКА ВМЕСТО ЗОЛОТОЙ: +10%\nЕСЛИ УДАЧА >= 20, ШАНС СТАНЕТ 60%", "scene": preload("res://Scenes/Item_Gold_Chain.tscn")}, 
	"lightbulb": {"name": "ЛАМПОЧКА", "desc": "ПОДСВЕЧИВАЕТ ЦЕЛЬ\nНАГРАДА ЗА УБИЙСТВО: +10$", "scene": preload("res://Scenes/Item_Lightbulb.tscn")}, 
	"shishkin": {"name": "ВСТАНИСЛАВ ШИШКИН", "desc": "ШАНС 2% ПРЕВРАТИТЬ ВРАГА\nВ СМЕРТЕЛЬНЫЙ СНАРЯД", "scene": preload("res://Scenes/Item_Shishkin.tscn")}, 
	"panties": {"name": "ИСПОЛЬЗОВАННЫЕ ТРУСЫ", "desc": "ТОКСИЧНАЯ АУРА (-30% УРОНА ВРАГОВ)\nБОССЫ СТАНОВЯТСЯ СИЛЬНЕЕ (+50% УРОНА)", "scene": preload("res://Scenes/Item_Panties.tscn")}, 
	"cologne": {"name": "ОДЕКОЛОН XXX", "desc": "ШАНС 30% ПРИЗВАТЬ НАКАЧЕННОГО МЕДИКА\nОН БУДЕТ ВАС ЛЕЧИТЬ", "scene": preload("res://Scenes/Item_Cologne.tscn")}, 
	"xbox_gamepad": {"name": "ПУЛЬТ УПРАВЛЕНИЯ 'ЗАПАД'", "desc": "ЗАЩИТА (КИНЕТИКА/АНОМАЛИИ): +50%", "scene": preload("res://Scenes/Item_Xbox_Gamepad.tscn")}, 
	"ps_gamepad": {"name": "ПУЛЬТ УПРАВЛЕНИЯ 'ВОСТОК'", "desc": "УРОН (КИНЕТИКА/АНОМАЛИИ): +50%", "scene": preload("res://Scenes/Item_PS_Gamepad.tscn")}, 
	"huy_yogurt": {"name": "ЙОГУРТ 'Х.У.Й.'", "desc": "МАКСИМАЛЬНЫЙ ЭНЕРГОЗАПАС: +100 ЕД.", "scene": preload("res://Scenes/Item_Huy_Yogurt.tscn")}, 
	"soldering_iron": {"name": "ПАЯЛЬНИК", "desc": "ОСТАВЛЯЕТ ОГНЕННЫЙ ШЛЕЙФ\nУРОН: 1% МАКС. ХП/СЕК", "scene": preload("res://Scenes/Item_Soldering_Iron.tscn")}, 

	"natalia_iron": {"name": "УТЮГ НАТАЛЬЯ", "desc": "ШВЫРЯЕТ УТЮГ (25%)\nСТЯГИВАЕТ ВРАГОВ В ЧЕРНУЮ ДЫРУ", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"gambling_machine": {"name": "ГЭМБЛИНГ МАШИНА", "desc": "СТЯГИВАЕТ ВРАГОВ\nДЛЯ ДОДЕПА (7%)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"dep_machine": {"name": "ДЭП МАШИНА", "desc": "РАНДОМНЫЙ БАФФ ИЛИ ДЕБАФФ\nВ НАЧАЛЕ ЭТАЖА", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"worms": {"name": "ГЛИСТЫ", "desc": "МАКС ХП -20%. АПТЕЧКИ НЕ РАБОТАЮТ.\nСПАВНИТ ГЛИСТОВ-ЛЕКАРЕЙ.", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"gaben_mom_grave": {"name": "МОГИЛА МАТЕРИ ГАБЕНА", "desc": "СКОРОСТЬ -35%\nС ПРОТИВНИКОВ ПАДАЕТ ТОННА ЗОЛОТА", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"whip": {"name": "НЕЙРО-ХЛЫСТ", "desc": "ПОВЫШЕННЫЙ УРОН ПО БРОНИРОВАННЫМ\nИ ТЕНЕВЫМ ВРАГАМ", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"kamikaze_implant": {"name": "БРАКОВАННЫЙ ИМПЛАНТ", "desc": "ВРАГИ МОГУТ ВЗОРВАТЬСЯ\nИ ПОБЕЖАТЬ В СВОИХ (5%)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"condoms": {"name": "ГАНДОНЫ", "desc": "ВРАГИ МОГУТ НЕ ПОЯВИТЬСЯ\nВ КОМНАТЕ (ДЕМ. КРИЗИС)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"playboy": {"name": "ЖУРНАЛ ПЛЕЙБОЙ", "desc": "ПРИ ПОЛУЧЕНИИ УРОНА\nОТВЛЕКАЕТ ВСЕХ ВРАГОВ НА 3 СЕК", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"buyanov_dumplings": {"name": "ПЕЛЬМЕНИ ОТ БУЯНОВА", "desc": "МГНОВЕННЫЙ 100% ХИЛ\nПУЛИ ВЫЛЕТАЮТ С РАССИНХРОНОМ", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"monkey_king_stick": {"name": "ДРЫН КОРОЛЯ ОБЕЗЬЯН", "desc": "УРОН -35%. СКОР. АТАКИ +10%\nДОП. МАГ УРОН +10%", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"pilot": {"name": "ВЫ РЕШИЛИ СТАТЬ ПИЛОТОМ", "desc": "ОПЫТ +40%\nСКОРОСТЬ -10%", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"maxim_kiss": {"name": "ГУБКИ 'ПОЦЕЛУЙ МАКСИМА'", "desc": "РАДИУС ПОДБОРА +50%\nМАГ. РЕЗИСТ -5", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"bdsm_suit": {"name": "БДСМ КОСТЮМ", "desc": "ОТРАЖАЕТ 20% УРОНА\nБРОНЯ +15", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"midas_touch": {"name": "КАСАНИЕ МИДАСА", "desc": "ВРАГИ РЯДОМ ДАЮТ ДОП. ЗОЛОТО", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"tea_bag": {"name": "ПАКЕТИК ЧАЯ", "desc": "СКОРОСТЬ АТАКИ +10%\n[СТАК >10]: ЧАЕПИТИЕ (+СКОРОСТЬ)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"fake_vodka": {"name": "ПАЛЁНАЯ ВОДКА", "desc": "Ну, чтоб руки не дрожали. ТОЧНОСТЬ +15%\n[СТАК >3]: БЕЛОЧКА (+УРОН, -ТОЧНОСТЬ)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"shpringles": {"name": "ШПРИНГЛС", "desc": "УРОН +5%\n[СТАК =10]: ВЗРЫВНЫЕ ЧИПСЫ", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"bone": {"name": "КОСТЬ", "desc": "Плохое время. МАКС ХП -15\n[СТАК >5]: ПЛОХОЕ ВРЕМЯ (+ОГРОМНЫЙ УРОН)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"red_scarf": {"name": "КРАСНЫЙ ШАРФ", "desc": "У ТЕБЯ ТЕПЕРЬ БОЛЬШАЯ КОСТЬ\nУРОН +10%, СКОРОСТЬ -5%", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"justice_hammer": {"name": "МОЛОТ СПРАВЕДЛИВОСТИ", "desc": "РАЗ В 15 СЕК КАРАЕТ\nВРАГА УРОНОМ 3.3x", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"cucumber": {"name": "ОГУРЕЦ", "desc": "Довольно скользкий и гладкий.\nОТДАЧА -5%, СКОРОСТЬ АТАКИ +10%", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"lentil_soup": {"name": "ЧЕЧЕВИЧНАЯ ПОХЛЁБКА", "desc": "Теперь ты старше меня.\nМАКС ХП +10, СКОРОСТЬ +10%, УРОН +10%", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"bread": {"name": "ХЛЕБ", "desc": "Эксперимент не был провальным.\nШАНС ВЫСТРЕЛА МЯКИШЕМ (АГРО)", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}, 
	"fork": {"name": "ВИЛКА", "desc": "Вилкой в глаз...\nСКОРОСТЬ -10%, МАГ. УРОН +10%", "scene": preload("res://Scenes/Item_Baby_Oil.tscn")}
}

func _ready():
	visible = false
	color = COLOR_BG

	self.set_anchors_preset(Control.PRESET_TOP_LEFT)
	self.size = Vector2(1920.0, 1080.0)
	self.pivot_offset = Vector2.ZERO
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()

	if header_label:
		header_label.text = "[ БИО-ТЕРМИНАЛ ОПЕРАТИВНИКА ] _"
		header_label.add_theme_font_size_override("font_size", 32)
		header_label.add_theme_color_override("font_color", COLOR_GREEN)
		header_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		header_label.add_theme_constant_override("shadow_offset_x", 3)
		header_label.add_theme_constant_override("shadow_offset_y", 3)

	if tooltip:
		tooltip.visible = false
		tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip.top_level = true
		tooltip.z_index = 100

	if map_draw_area: map_draw_area.draw.connect(_on_map_draw)

	if columns_hbox:
		columns_hbox.add_theme_constant_override("separation", 0)
		if left_column: left_column.queue_free()
		if right_column: right_column.queue_free()

		var scroll = ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

		var v_scroll = scroll.get_v_scroll_bar()
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = COLOR_SCROLL_BG
		var grabber_style = StyleBoxFlat.new()
		grabber_style.bg_color = COLOR_SCROLL_GRABBER

		v_scroll.add_theme_stylebox_override("scroll", bg_style)
		v_scroll.add_theme_stylebox_override("scroll_focus", bg_style)
		v_scroll.add_theme_stylebox_override("grabber", grabber_style)
		v_scroll.add_theme_stylebox_override("grabber_highlight", grabber_style)
		v_scroll.add_theme_stylebox_override("grabber_pressed", grabber_style)
		v_scroll.custom_minimum_size.x = 6

		columns_hbox.add_child(scroll)

		stats_list_content = VBoxContainer.new()
		stats_list_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_list_content.add_theme_constant_override("separation", 8)
		scroll.add_child(stats_list_content)

	if stats_panel:
		stats_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		stats_panel.offset_left = -520
		stats_panel.offset_right = -40
		stats_panel.offset_top = 40
		stats_panel.offset_bottom = -200
		base_panel_offset_l = stats_panel.offset_left
		base_panel_offset_r = stats_panel.offset_right

		var panel_bg = StyleBoxFlat.new()
		panel_bg.bg_color = Color(0.01, 0.01, 0.01, 0.98)
		panel_bg.border_width_left = 4;panel_bg.border_width_right = 4
		panel_bg.border_width_top = 4;panel_bg.border_width_bottom = 4
		panel_bg.border_color = COLOR_GREEN
		panel_bg.anti_aliasing = false
		stats_panel.add_theme_stylebox_override("panel", panel_bg)

	var old_marker = find_child("PlayerMarker", true, false)
	if old_marker: old_marker.visible = false

	player_node = get_tree().get_first_node_in_group("player")
	visibility_changed.connect(_on_visibility_changed)

	_setup_badtrip_shader()
	_apply_minimalist_theme(self)

func _on_window_resized() -> void :
	var vp_size = get_viewport_rect().size
	self.scale = vp_size / Vector2(1920.0, 1080.0)

func _process(delta):
	if not visible: return

	vhs_time += delta
	radar_angle += delta * 2.5

	if crt_overlay and crt_overlay.material:
		crt_overlay.material.set_shader_parameter("time", vhs_time)

	if header_label:
		var cursor = " █" if int(vhs_time * 2.0) % 2 == 0 else " _"
		header_label.text = "[ БИО-ТЕРМИНАЛ ОПЕРАТИВНИКА ]" + cursor

	if map_draw_area: map_draw_area.queue_redraw()

	if tooltip and tooltip.visible:
		var mouse_pos = get_global_mouse_position()
		var target_pos = mouse_pos + Vector2(25, - tooltip.size.y - 20)
		tooltip.global_position = tooltip.global_position.lerp(target_pos, 25.0 * delta)




func update_stats_data():
	if not is_inside_tree() or not stats_list_content: return
	if not player_node or not is_instance_valid(player_node):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0: player_node = players[0]
		else: return

	for child in stats_list_content.get_children():
		stats_list_content.remove_child(child)
		child.queue_free()
	animated_rows.clear()

	var cur_hp = int(player_node.current_health)
	var max_hp = int(Global.get_final_max_health())
	var cur_mp = int(player_node.current_mana)
	var max_mp = int(Global.get_final_max_mana())
	var cur_st = int(player_node.current_stamina)
	var max_st = int(Global.get_final_max_stamina())
	var regen_st = Global.get_final_stamina_regen()


	_add_category("СИСТЕМЫ ОБОЛОЧКИ")
	_add_stat_row("ЦЕЛОСТНОСТЬ:", "%d / %d ЕД." % [cur_hp, max_hp], COLOR_WARN if cur_hp < max_hp * 0.3 else Color.WHITE)
	_add_stat_row("ЭНЕРГОЗАПАС:", "%d / %d ЕД." % [cur_mp, max_mp if max_mp > 0 else 1], COLOR_CYAN)
	_add_stat_row("СТАМИНА:", "%d / %d ЕД." % [cur_st, max_st], Color.WHITE)
	_add_stat_row("ВОССТАНОВЛЕНИЕ СТАМИНЫ:", "%.1f ЕД/СЕК" % regen_st, Color.WHITE)
	_add_spacer()

	_add_category("ЗАЩИТНЫЕ ПОЛЯ")
	_add_stat_row("КИНЕТИКА (БРОНЯ):", "%d ЕД." % int(Global.armor), Color.WHITE)
	_add_stat_row("АНОМАЛИИ (ПСИ):", "%d ЕД." % int(Global.magic_resist), Color("#aa55ff"))
	if Global.thorns_damage_mult > 0:
		_add_stat_row("ОТРАЖЕНИЕ УРОНА (ШИПЫ):", "%d%%" % int(Global.thorns_damage_mult * 100), COLOR_WARN)
	_add_spacer()

	_add_category("ФИЗИОЛОГИЯ И СТАТУС")
	_add_stat_row("СКОРОСТЬ ПРИВОДОВ:", "%.1f М/С" % Global.get_final_speed(player_node.base_walk_speed), Color.WHITE)
	_add_stat_row("СИЛА ПРЫЖКА:", "%.1f ЕД." % Global.get_final_jump(player_node.jump_velocity), Color.WHITE)
	_add_stat_row("ИНДЕКС УДАЧИ:", "%.1f ЕД." % Global.luck, Color.WHITE)
	_add_stat_row("ДИПЛОМАТИЯ МГЕ:", "%.1f%%" % (Global.get_final_friendly_chance() * 100.0), COLOR_CYAN)
	if Global.pickup_radius_mult > 1.0:
		_add_stat_row("РАДИУС ПОДБОРА:", "x%.1f" % Global.pickup_radius_mult, Color.WHITE)
	if Global.exp_multiplier > 1.0:
		_add_stat_row("МНОЖИТЕЛЬ ОПЫТА:", "x%.1f" % Global.exp_multiplier, Color.YELLOW)
	_add_spacer()

	_add_category("БОЕВЫЕ ДИРЕКТИВЫ")
	var f_dmg = Global.get_final_phys_damage(BASE_PHYS_DAMAGE)
	var m_dmg = Global.get_final_magic_damage(BASE_MAGIC_DAMAGE)
	_add_stat_row("ФИЗИЧЕСКИЙ УРОН (БАЗА):", "%.1f ЕД." % f_dmg, Color.WHITE)
	_add_stat_row("АНОМАЛЬНЫЙ УРОН:", "%.1f ЕД." % m_dmg, COLOR_CYAN)
	_add_stat_row("УРОН Ф.И.Н.К.А.:", "%.1f ЕД." % Global.melee_damage, COLOR_WARN)
	_add_stat_row("Ш. КРИТ. ПРОБОЯ:", "%.1f%%" % (Global.crit_chance * 100.0), Color.WHITE)
	_add_stat_row("СИЛА КРИТ. ПРОБОЯ:", "%.0f%%" % (BASE_CRIT_DAMAGE * Global.crit_damage_mult), Color.WHITE)
	_add_spacer()

	_add_category("ОРУЖЕЙНЫЕ МОДУЛИ")
	var f_rate = Global.get_final_fire_rate(BASE_FIRE_RATE)
	var r_speed = BASE_RELOAD_SPEED / max(0.1, Global.reload_speed_multiplier)
	_add_stat_row("ТЕМП ОГНЯ:", "%.1f В/С" % f_rate, Color.WHITE)
	_add_stat_row("ОХЛАЖДЕНИЕ:", "%.1f СЕК" % r_speed, Color.WHITE)
	_add_stat_row("ОБЪЕМ МАГАЗИНА:", "%d%%" % int(Global.magazine_size_multiplier * 100.0), Color.WHITE)
	_add_stat_row("ТОЧНОСТЬ (РАЗБРОС):", "%d%%" % int(Global.spread_multiplier * 100.0), Color.WHITE)
	_add_stat_row("СТАБИЛИЗАЦИЯ:", "%d%%" % int(Global.recoil_multiplier * 100.0), Color.WHITE)
	_add_spacer()

	_add_category("АКТИВНЫЕ МУТАЦИИ")
	var has_muts = false
	if Global.plunger_chance > 0: _add_stat_row("> ШАНС ВАНТУЗА:", "%d%%" % int(Global.plunger_chance * 100), COLOR_GREEN);has_muts = true
	if Global.bleed_chance > 0: _add_stat_row("> ШАНС КРОВОТЕЧЕНИЯ:", "%d%%" % int(Global.bleed_chance * 100), COLOR_GREEN);has_muts = true
	if Global.shishkin_chance > 0: _add_stat_row("> ВЕРОЯТНОСТЬ ШИШКИНА:", "%d%%" % int(Global.shishkin_chance * 100), COLOR_GREEN);has_muts = true
	if Global.get_white_party_chance() > 0: _add_stat_row("> БЕЛАЯ ВЕЧЕРИНКА:", "%d%%" % int(Global.get_white_party_chance() * 100), COLOR_GREEN);has_muts = true
	if Global.panties_count > 0: _add_stat_row("> АУРА ТРУСОВ (СТАК):", "%d" % Global.panties_count, COLOR_GREEN);has_muts = true
	if Global.cologne_count > 0: _add_stat_row("> МЕДИКИ ОДЕКОЛОНА:", "%d" % Global.cologne_count, COLOR_GREEN);has_muts = true
	if Global.soldering_iron_count > 0: _add_stat_row("> ТЕРМОСЛЕД ПАЯЛЬНИКА:", "%d" % Global.soldering_iron_count, COLOR_GREEN);has_muts = true

	if Global.natalia_iron_chance > 0: _add_stat_row("> СИНГУЛЯРНОСТЬ НАТАЛЬИ:", "%d%%" % int(Global.natalia_iron_chance * 100), COLOR_GREEN);has_muts = true
	if Global.bread_chance > 0: _add_stat_row("> ПРОВОКАЦИЯ МЯКИШОМ:", "%d%%" % int(Global.bread_chance * 100), COLOR_GREEN);has_muts = true
	if Global.kamikaze_chance > 0: _add_stat_row("> ВЗЛОМ ИМПЛАНТОВ:", "%d%%" % int(Global.kamikaze_chance * 100), COLOR_GREEN);has_muts = true
	if Global.playboy_chance > 0: _add_stat_row("> ОТВЛЕЧЕНИЕ ПЛЕЙБОЕМ:", "%d%%" % int(Global.playboy_chance * 100), COLOR_GREEN);has_muts = true
	if Global.justice_hammer_count > 0: _add_stat_row("> МОЛОТ СПРАВЕДЛИВОСТИ:", "АКТИВЕН", COLOR_GREEN);has_muts = true
	if Global.midas_touch_count > 0: _add_stat_row("> КАСАНИЕ МИДАСА:", "АКТИВНО", COLOR_GREEN);has_muts = true
	if Global.whip_count > 0: _add_stat_row("> НЕЙРО-ХЛЫСТ:", "АКТИВЕН", COLOR_GREEN);has_muts = true
	if Global.gambling_machine_count > 0: _add_stat_row("> ГЭМБЛИНГ-ДОДЕП:", "АКТИВЕН", COLOR_GREEN);has_muts = true
	if Global.dep_machine_count > 0: _add_stat_row("> ДЭП-МАШИНА:", "АКТИВНА", COLOR_GREEN);has_muts = true
	if Global.condoms_count > 0: _add_stat_row("> ДЕМОГРАФИЧЕСКИЙ КРИЗИС:", "АКТИВЕН", COLOR_GREEN);has_muts = true
	if Global.has_worms: _add_stat_row("> ИНВАЗИЯ ГЛИСТОВ:", "АКТИВНА", COLOR_WARN);has_muts = true
	if Global.buyanov_desync: _add_stat_row("> РАССИНХРОН БУЯНОВА:", "АКТИВЕН", COLOR_WARN);has_muts = true

	if not has_muts:
		_add_stat_row("> МУТАЦИЙ НЕ ОБНАРУЖЕНО", "", COLOR_GREY)
	_add_spacer(30)

	update_items_ui()
	_play_boot_animation()

func _add_category(text: String, box_color: Color = COLOR_GREEN):
	var hbox = HBoxContainer.new()
	var box = Label.new()
	box.text = "█"
	box.add_theme_font_size_override("font_size", FONT_SIZE_CAT)
	box.add_theme_color_override("font_color", box_color)
	box.add_theme_color_override("font_shadow_color", Color.BLACK)
	box.add_theme_constant_override("shadow_offset_x", 2)
	box.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(box)

	var lbl = Label.new()
	lbl.text = " " + text
	lbl.add_theme_font_size_override("font_size", FONT_SIZE_CAT)
	lbl.add_theme_color_override("font_color", COLOR_GREEN)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	hbox.add_child(lbl)

	stats_list_content.add_child(hbox)
	animated_rows.append(hbox)

func _add_stat_row(stat_name: String, val_str: String, val_color: Color = Color.WHITE):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = stat_name
	name_lbl.add_theme_font_size_override("font_size", FONT_SIZE_STAT)
	name_lbl.add_theme_color_override("font_color", COLOR_GREY)
	name_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	name_lbl.add_theme_constant_override("shadow_offset_x", 2)
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)

	if val_str != "":
		var val_lbl = Label.new()
		val_lbl.text = val_str
		val_lbl.add_theme_font_size_override("font_size", FONT_SIZE_STAT)
		val_lbl.add_theme_color_override("font_color", val_color)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		val_lbl.add_theme_constant_override("shadow_offset_x", 2)
		val_lbl.add_theme_constant_override("shadow_offset_y", 2)
		hbox.add_child(val_lbl)

	stats_list_content.add_child(hbox)
	animated_rows.append(hbox)

func _add_spacer(height: float = 12.0):
	var sp = Control.new()
	sp.custom_minimum_size.y = height
	stats_list_content.add_child(sp)




func _on_visibility_changed():
	if visible:
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		if tooltip: tooltip.visible = false

func _play_boot_animation():
	if not stats_panel or animated_rows.is_empty(): return
	if boot_tween and boot_tween.is_running(): boot_tween.kill()
	boot_tween = create_tween()

	stats_panel.offset_left = base_panel_offset_l + 100
	stats_panel.offset_right = base_panel_offset_r + 100
	stats_panel.modulate.a = 0.0

	boot_tween.parallel().tween_property(stats_panel, "offset_left", base_panel_offset_l, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	boot_tween.parallel().tween_property(stats_panel, "offset_right", base_panel_offset_r, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	boot_tween.parallel().tween_property(stats_panel, "modulate:a", 1.0, 0.15)

	_screen_shake(0.15, 8.0)

	for i in range(animated_rows.size()):
		var row = animated_rows[i]
		row.modulate.a = 0.0
		row.position.x += 20
		var delay = i * 0.015

		boot_tween.parallel().tween_property(row, "modulate:a", 1.0, 0.05).set_delay(delay)
		boot_tween.parallel().tween_property(row, "position:x", row.position.x - 20, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).set_delay(delay)

func _screen_shake(duration: float, intensity: float):
	var tw_shake = create_tween()
	var orig_pos = position
	var steps = 6
	var step_dur = duration / steps
	for i in range(steps):
		var offset = Vector2(floor(randf_range( - intensity, intensity)), floor(randf_range( - intensity, intensity)))
		tw_shake.tween_property(self, "position", orig_pos + offset, step_dur)
		intensity *= 0.7
	tw_shake.tween_property(self, "position", orig_pos, step_dur)




func _setup_badtrip_shader():
	crt_overlay = ColorRect.new()
	crt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_overlay.z_index = 10
	add_child(crt_overlay)

	var shader = Shader.new()
	shader.code = "\n\tshader_type canvas_item;\n\tuniform float time;\n\tuniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;\n\n\tvec2 curve(vec2 uv) {\n\t\tuv = (uv - 0.5) * 2.0;\n\t\tuv *= 1.1;\t\n\t\tuv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);\n\t\tuv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);\n\t\tuv  = (uv / 2.0) + 0.5;\n\t\tuv =  uv *0.92 + 0.04;\n\t\treturn uv;\n\t}\n\n\tvoid fragment() {\n\t\tvec2 uv = curve(SCREEN_UV);\n\t\t\n\t\tif (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {\n\t\t\tCOLOR = vec4(0.0, 0.0, 0.0, 1.0);\n\t\t} else {\n\t\t\tfloat shift = 0.0015;\n\t\t\tfloat r = texture(SCREEN_TEXTURE, vec2(uv.x + shift, uv.y)).r;\n\t\t\tfloat g = texture(SCREEN_TEXTURE, uv).g;\n\t\t\tfloat b = texture(SCREEN_TEXTURE, vec2(uv.x - shift, uv.y)).b;\n\t\t\t\n\t\t\tvec3 color = vec3(r, g, b);\n\t\t\t\n\t\t\tfloat scanline = sin(uv.y * 800.0) * 0.04;\n\t\t\tcolor -= scanline;\n\t\t\t\n\t\t\tfloat noise = fract(sin(dot(uv + time, vec2(12.9898,78.233))) * 43758.5453);\n\t\t\tcolor += noise * 0.02;\n\t\t\t\n\t\t\tfloat vig = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);\n\t\t\tvig = clamp(pow(16.0 * vig, 0.2), 0.0, 1.0);\n\t\t\tcolor *= vig;\n\t\t\t\n\t\t\tCOLOR = vec4(color, 1.0);\n\t\t}\n\t}\n\t"









































	var mat = ShaderMaterial.new()
	mat.shader = shader
	crt_overlay.material = mat

func _on_map_draw():
	if not map_draw_area: return
	var center = map_draw_area.size / 2.0
	center.x += map_offset_x

	var grid_step = 60.0
	var grid_color = Color(0.0, 1.0, 0.2, 0.15)
	for x in range(0, int(map_draw_area.size.x), int(grid_step)):
		map_draw_area.draw_line(Vector2(x, 0), Vector2(x, map_draw_area.size.y), grid_color, 1.0)
	for y in range(0, int(map_draw_area.size.y), int(grid_step)):
		map_draw_area.draw_line(Vector2(0, y), Vector2(map_draw_area.size.x, y), grid_color, 1.0)

	for r in [120.0, 240.0, 360.0]:
		map_draw_area.draw_arc(center, r, 0, TAU, 16, COLOR_GREEN * 0.5, 2.0)

	if not Global.map_layout.is_empty():
		for pos in Global.map_layout:
			var is_discovered = pos in Global.discovered_rooms
			if not is_discovered and not is_adjacent_to_discovered(pos): continue
			var offset_grid = pos - Global.current_room_pos
			var draw_pos = center + (offset_grid * (room_size + margin)) - Vector2(room_size / 2.0, room_size / 2.0)

			var rect_color = Color(0.0, 0.4, 0.1, 0.6) if is_discovered else Color(0.0, 0.1, 0.05, 0.4)
			var border_color = COLOR_GREEN

			if is_discovered:
				if pos == Global.boss_room_pos: rect_color = COLOR_WARN;border_color = Color.WHITE
				elif pos == Global.current_room_pos: rect_color = COLOR_CYAN;border_color = Color.WHITE

			map_draw_area.draw_rect(Rect2(draw_pos, Vector2(room_size, room_size)), rect_color)
			map_draw_area.draw_rect(Rect2(draw_pos, Vector2(room_size, room_size)), border_color, false, 2.0)

	var radar_radius = 450.0
	var radar_pts = PackedVector2Array([center])
	var tail_length = 0.5
	var segments = 8
	for i in range(segments + 1):
		var angle = radar_angle - (tail_length * (1.0 - float(i) / segments))
		radar_pts.append(center + Vector2(cos(angle), sin(angle)) * radar_radius)

	var radar_colors = PackedColorArray([Color(0, 0, 0, 0)])
	for i in range(segments + 1):
		var alpha = 0.0 + (float(i) / segments) * 0.4
		radar_colors.append(Color(0.0, 1.0, 0.2, alpha))

	map_draw_area.draw_polygon(radar_pts, radar_colors)

	var end_point = center + Vector2(cos(radar_angle), sin(radar_angle)) * radar_radius
	map_draw_area.draw_line(center, end_point, COLOR_GREEN, 3.0)

	if is_instance_valid(player_node):
		var p_rot = - player_node.global_rotation.y
		var p1 = Vector2(0, -16).rotated(p_rot)
		var p2 = Vector2(12, 12).rotated(p_rot)
		var p3 = Vector2(0, 6).rotated(p_rot)
		var p4 = Vector2(-12, 12).rotated(p_rot)
		var pts = PackedVector2Array([center + p1, center + p2, center + p3, center + p4])

		map_draw_area.draw_colored_polygon(pts, Color.WHITE)
		map_draw_area.draw_polyline(PackedVector2Array([center + p1, center + p2, center + p3, center + p4, center + p1]), COLOR_GREEN, 2.0)

func is_adjacent_to_discovered(pos: Vector2) -> bool:
	for dir in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		if (pos + dir) in Global.discovered_rooms: return true
	return false




func update_items_ui():
	if not items_grid: return
	for child in items_grid.get_children():
		items_grid.remove_child(child)
		child.queue_free()

	if Global.inventory.is_empty():
		var empty_label = Label.new()
		empty_label.text = "[ НЕТ ОБЪЕКТОВ В ПАМЯТИ ]"
		empty_label.add_theme_font_size_override("font_size", 22)
		empty_label.add_theme_color_override("font_color", COLOR_GREY)
		items_grid.add_child(empty_label)
		return

	for raw_item_id in Global.inventory.keys():
		var data = item_database.get(raw_item_id)
		if data and data.has("scene"):
			var slot = ColorRect.new()
			slot.custom_minimum_size = Vector2(100, 100)
			slot.color = Color(0.01, 0.05, 0.01, 0.95)

			slot.mouse_entered.connect(_on_item_hovered.bind(data, Global.inventory[raw_item_id], slot))
			slot.mouse_exited.connect(_on_item_unhovered.bind(slot))

			var vp_c = SubViewportContainer.new()
			vp_c.set_anchors_preset(Control.PRESET_FULL_RECT)
			vp_c.stretch = true
			vp_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(vp_c)

			var vp = SubViewport.new()
			vp.transparent_bg = true;vp.own_world_3d = true
			vp_c.add_child(vp)

			var cam = Camera3D.new()
			cam.look_at_from_position(Vector3(0, 0.5, 1.5), Vector3.ZERO)
			vp.add_child(cam)

			var light = DirectionalLight3D.new()
			light.light_color = Color.WHITE
			light.light_energy = 2.0
			light.rotation_degrees = Vector3(-45, 45, 0)
			vp.add_child(light)

			var model = data["scene"].instantiate()
			if model:
				_disable_collision(model)
				vp.add_child(model)

			var border = ReferenceRect.new()
			border.name = "Border"
			border.set_anchors_preset(Control.PRESET_FULL_RECT)
			border.border_color = COLOR_GREEN
			border.border_width = 3.0
			border.editor_only = false
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(border)

			slot.pivot_offset = slot.custom_minimum_size / 2.0

			if Global.inventory[raw_item_id] > 1:
				var count_label = Label.new()
				count_label.text = "x" + str(Global.inventory[raw_item_id])
				count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
				count_label.add_theme_font_size_override("font_size", 24)
				count_label.add_theme_color_override("font_color", Color.WHITE)
				count_label.add_theme_color_override("font_shadow_color", Color.BLACK)
				count_label.add_theme_constant_override("shadow_offset_x", 2)
				count_label.add_theme_constant_override("shadow_offset_y", 2)
				slot.add_child(count_label)

			items_grid.add_child(slot)

func _disable_collision(node):
	if node is CollisionShape3D: node.disabled = true
	for child in node.get_children(): _disable_collision(child)

func _on_item_hovered(item_data, count, slot_node):
	var tw = create_tween()
	tw.tween_property(slot_node, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)

	var border = slot_node.get_node_or_null("Border")
	if border: border.border_color = Color.WHITE
	slot_node.z_index = 10

	if tooltip_label is Label:
		tooltip_label.text = "=== %s ===\nВ НАЛИЧИИ: %d шт.\n\n%s" % [item_data["name"], count, item_data["desc"]]
	elif tooltip_label is RichTextLabel:
		tooltip_label.text = "[font_size=24][color=#00ff41]%s[/color]\n[color=#ffffff]В НАЛИЧИИ: %d шт.[/color]\n\n[color=#aaaaaa]%s[/color][/font_size]" % [item_data["name"], count, item_data["desc"]]

	tooltip.visible = true
	tooltip.move_to_front()

func _on_item_unhovered(slot_node):
	var tw = create_tween()
	tw.tween_property(slot_node, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
	var border = slot_node.get_node_or_null("Border")
	if border: border.border_color = COLOR_GREEN
	slot_node.z_index = 0
	tooltip.visible = false

func _apply_minimalist_theme(node: Node):
	if node.name == "ItemsPanel": return

	if node is Panel or node is ScrollContainer:
		node.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if node is Label or node is RichTextLabel:
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_color_override("font_shadow_color", Color.BLACK)
		node.add_theme_constant_override("shadow_offset_x", 2)
		node.add_theme_constant_override("shadow_offset_y", 2)

	if node.name == "Tooltip":
		var tt_style = StyleBoxFlat.new()
		tt_style.bg_color = Color(0.01, 0.01, 0.01, 0.95)
		tt_style.border_width_left = 3;tt_style.border_width_right = 3
		tt_style.border_width_top = 3;tt_style.border_width_bottom = 3
		tt_style.border_color = COLOR_GREEN
		tt_style.anti_aliasing = false
		node.add_theme_stylebox_override("panel", tt_style)

	for child in node.get_children():
		if child == header_label or child == crt_overlay: continue
		_apply_minimalist_theme(child)

extends Control

var upgrades_info = {
	"health": {"name": "Макс. Здоровье", "base_cost": 15}, 
	"damage": {"name": "Урон Оружия", "base_cost": 20}, 
	"speed": {"name": "Скорость Бега", "base_cost": 10}, 
	"fire_rate": {"name": "Скорострельность", "base_cost": 15}, 
	"crit_chance": {"name": "Шанс Крита", "base_cost": 15}, 
	"crit_damage": {"name": "Урон Крита", "base_cost": 20}, 
	"armor": {"name": "Броня (Защита)", "base_cost": 25}, 
	"accuracy": {"name": "Точность (Разброс)", "base_cost": 10}, 
	"recoil": {"name": "Контроль Отдачи", "base_cost": 10}, 
	"melee_damage": {"name": "Урон Ножом", "base_cost": 10}, 
	"luck": {"name": "Удача", "base_cost": 30}
}

var max_level = 10
var container: VBoxContainer
var money_label: Label

func _ready():
	setup_ui_structure()
	refresh_ui()
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if is_visible_in_tree(): refresh_ui()

func refresh_ui():
	if not money_label or not container: return


	money_label.text = "[ DATA_CRYSTALS: " + str(Global.meta_crystals) + " ]"

	for child in container.get_children():
		child.queue_free()
	for upgrade_id in upgrades_info.keys():
		var card = create_upgrade_card(upgrade_id)
		container.add_child(card)

func setup_ui_structure():


	money_label = Label.new()
	money_label.text = "[ DATA_CRYSTALS: 0 ]"
	money_label.position = Vector2(0, -10)
	money_label.add_theme_font_size_override("font_size", 24)
	_stylize_label(money_label)

	money_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(money_label)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 30)
	scroll.size = Vector2(530, 370)


	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(scroll)

	container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 20)
	scroll.add_child(container)

func create_upgrade_card(id: String) -> Control:
	var info = upgrades_info[id]
	var current_lvl = Global.meta_upgrades.get(id, 0)
	var cost = info["base_cost"] + (current_lvl * info["base_cost"])

	var hbox = HBoxContainer.new()


	var name_label = Label.new()
	name_label.custom_minimum_size = Vector2(320, 0)

	var bar_str = generate_terminal_bar(current_lvl, max_level)
	name_label.text = info["name"] + " (Ур. " + str(current_lvl) + "/" + str(max_level) + ")\n" + bar_str

	_stylize_label(name_label)
	hbox.add_child(name_label)


	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 45)
	_stylize_button(btn)

	if current_lvl >= max_level:
		btn.text = "[ МАКСИМУМ ]"
		btn.disabled = true
	else:
		btn.text = "КУПИТЬ: " + str(cost) + " DATA"
		if Global.meta_crystals < cost:
			btn.disabled = true
		else:
			btn.pressed.connect( func(): buy_upgrade(id, cost))

	hbox.add_child(btn)
	return hbox

func buy_upgrade(id: String, cost: int):
	if Global.meta_crystals >= cost and Global.meta_upgrades[id] < max_level:
		Global.meta_crystals -= cost
		Global.meta_upgrades[id] += 1
		Global.save_meta_data()
		refresh_ui()






func generate_terminal_bar(current_level: int, max_val: int) -> String:
	var bar = "["
	for i in range(max_val):
		if i < current_level:
			bar += "█"
		else:
			bar += "-"
	bar += "]"
	return bar

func _stylize_label(lbl: Label):
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)

func _stylize_button(btn: Button):
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("disabled", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.2, 0.2))
	btn.add_theme_color_override("font_pressed_color", Color(0.6, 0.0, 0.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 4)

	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	if not btn.mouse_entered.is_connected(_on_button_hover.bind(btn)):
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
	if not btn.mouse_exited.is_connected(_on_button_unhover.bind(btn)):
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))

func _on_button_hover(btn: Button):

	if not btn.disabled and not btn.text.begins_with("> "):
		btn.text = "> " + btn.text

func _on_button_unhover(btn: Button):
	if btn.text.begins_with("> "):
		btn.text = btn.text.substr(2)

extends Control


var available_perks = {
	"none": {
		"name": "БЕЗ ПЕРКА", 
		"desc": "ИГРАТЬ БЕЗ НАЧАЛЬНЫХ БОНУСОВ."
	}, 
	"friendly_spawn": {
		"name": "ДРУЖЕЛЮБНЫЙ ЗОМБИ", 
		"desc": "ШАНС 5% НА СПАВН СОЮЗНОГО ЗОМБИ\nВ КАЖДОЙ КОМНАТЕ."
	}, 
	"magic_dmg_boost": {
		"name": "МАГИЧЕСКАЯ ПУЛЯ", 
		"desc": "УВЕЛИЧИВАЕТ ВЕСЬ НАНОСИМЫЙ\nМАГИЧЕСКИЙ УРОН НА 5."
	}
}

var container: VBoxContainer
var desc_label: Label
var buttons_dict = {}

func _ready():

	var title = Label.new()
	title.text = "ВЫБОР СТАРТОВОГО ПЕРКА:"
	title.position = Vector2(0, 0)
	title.add_theme_font_size_override("font_size", 18)
	_stylize_label(title)
	add_child(title)


	container = VBoxContainer.new()
	container.position = Vector2(0, 30)
	container.add_theme_constant_override("separation", 5)
	add_child(container)


	desc_label = Label.new()
	desc_label.position = Vector2(250, 30)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_stylize_label(desc_label)
	desc_label.text = ""
	add_child(desc_label)


	for perk_id in available_perks.keys():
		create_perk_button(perk_id)

	refresh_buttons()

func create_perk_button(id: String):
	var btn = Button.new()
	_stylize_button(btn)


	btn.pressed.connect( func(): select_perk(id))


	btn.mouse_entered.connect( func(): _on_perk_hover(id, btn))
	btn.mouse_exited.connect( func(): _on_perk_unhover(btn))

	container.add_child(btn)
	buttons_dict[id] = btn

func select_perk(id: String):
	Global.selected_starting_perk = id

	if Global.has_method("save_meta_data"):
		Global.save_meta_data()
	refresh_buttons()

func refresh_buttons():

	for id in buttons_dict.keys():
		var btn = buttons_dict[id]
		var info = available_perks[id]


		var _clean_text = btn.text.replace("> ", "")

		if Global.selected_starting_perk == id:
			btn.text = "[X] " + info["name"]

			btn.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		else:
			btn.text = "[ ] " + info["name"]

			btn.add_theme_color_override("font_color", Color.WHITE)





func _on_perk_hover(id: String, btn: Button):
	if not btn.text.begins_with("> "):
		btn.text = "> " + btn.text

	var info = available_perks[id]

	desc_label.text = "ИНФО ПРОТОКОЛ:\n" + info["desc"]

func _on_perk_unhover(btn: Button):
	if btn.text.begins_with("> "):
		btn.text = btn.text.substr(2)
	desc_label.text = ""

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
	btn.add_theme_color_override("font_outline_color", Color.BLACK)
	btn.add_theme_constant_override("outline_size", 4)

	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

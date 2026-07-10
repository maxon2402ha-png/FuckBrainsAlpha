extends CanvasLayer

var panel: Panel
var log_text: RichTextLabel
var input_line: LineEdit


var command_history: Array[String] = []
var history_index: int = 0
var previous_mouse_mode: int = Input.MOUSE_MODE_VISIBLE


var item_scenes = {
	"baby_oil": "res://Scenes/Item_Baby_Oil.tscn", 
	"mge_photo": "res://Scenes/Item_MGE_Photo.tscn", 
	"chingis_eggs": "res://Scenes/Item_Chingis_Eggs.tscn", 
	"plunger": "res://Scenes/Item_Plunger.tscn", 
	"maduro_drink": "res://Scenes/Item_Maduro_Drink.tscn", 
	"diary": "res://Scenes/Item_Diary.tscn", 
	"nails": "res://Scenes/Item_Nails.tscn", 
	"medpolis": "res://Scenes/Item_Medpolis.tscn", 
	"rubiks_cube": "res://Scenes/Item_Rubiks_Cube.tscn", 
	"gold_chain": "res://Scenes/Item_Gold_Chain.tscn", 
	"lightbulb": "res://Scenes/Item_Lightbulb.tscn", 
	"shishkin": "res://Scenes/Item_Shishkin.tscn", 
	"panties": "res://Scenes/Item_Panties.tscn", 
	"cologne": "res://Scenes/Item_Cologne.tscn", 
	"xbox_gamepad": "res://Scenes/Item_Xbox_Gamepad.tscn", 
	"ps_gamepad": "res://Scenes/Item_PS_Gamepad.tscn", 
	"huy_yogurt": "res://Scenes/Item_Huy_Yogurt.tscn", 
	"soldering_iron": "res://Scenes/Item_Soldering_Iron.tscn"
}


var enemy_scenes = {
	"zombie": "res://Scenes/ranged_enemy.tscn", 
	"boss": "res://Scenes/boss_monstro.tscn", 
	"melee": "res://Scenes/enemy.tscn"
}

func _ready():
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0, 350)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.95)
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 1.0, 0.2, 0.8)
	panel.add_theme_stylebox_override("panel", style)


	panel.gui_input.connect( func(e): if e is InputEventMouseButton and e.pressed: input_line.grab_focus())

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("margin_left", 10)
	vbox.add_theme_constant_override("margin_right", 10)
	panel.add_child(vbox)

	log_text = RichTextLabel.new()
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.bbcode_enabled = true
	log_text.scroll_following = true

	log_text.focus_mode = Control.FOCUS_NONE
	vbox.add_child(log_text)

	input_line = LineEdit.new()
	input_line.placeholder_text = "Введите команду (help)..."
	input_line.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	var line_style = StyleBoxFlat.new()
	line_style.bg_color = Color(0, 0, 0, 1)
	input_line.add_theme_stylebox_override("normal", line_style)
	vbox.add_child(input_line)

	add_child(panel)
	panel.hide()

	print_log("[color=#55ff55]=== СИСТЕМА ОТЛАДКИ АКТИВИРОВАНА ===[/color]")
	print_log("Нажмите [color=yellow]~ (Тильда/Ё)[/color] для закрытия.")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_QUOTELEFT or event.physical_keycode == KEY_ASCIITILDE:
			toggle_console()
			get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void :
	if not panel.visible: return

	if event is InputEventKey and event.pressed:

		if event.physical_keycode == KEY_ESCAPE:
			toggle_console()
			get_viewport().set_input_as_handled()
			return


		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_text_submitted(input_line.text)
			get_viewport().set_input_as_handled()
			return


		if event.keycode == KEY_PAGEUP:
			var scroll = log_text.get_v_scroll_bar()
			scroll.value -= scroll.page * 0.5
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_PAGEDOWN:
			var scroll = log_text.get_v_scroll_bar()
			scroll.value += scroll.page * 0.5
			get_viewport().set_input_as_handled()
			return


		if event.keycode == KEY_UP:
			get_viewport().set_input_as_handled()
			if command_history.size() > 0:
				history_index -= 1
				if history_index < 0: history_index = 0
				input_line.text = command_history[history_index]
				input_line.caret_column = input_line.text.length()

		elif event.keycode == KEY_DOWN:
			get_viewport().set_input_as_handled()
			if command_history.size() > 0:
				history_index += 1
				if history_index >= command_history.size():
					history_index = command_history.size()
					input_line.text = ""
				else:
					input_line.text = command_history[history_index]
					input_line.caret_column = input_line.text.length()

func toggle_console():
	panel.visible = !panel.visible
	if panel.visible:

		previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		input_line.grab_focus()
		input_line.clear()
		history_index = command_history.size()
		get_tree().paused = true
	else:

		Input.mouse_mode = previous_mouse_mode
		get_tree().paused = false

func print_log(text: String):
	log_text.append_text(text + "\n")

func _on_text_submitted(text: String):
	var trimmed_text = text.strip_edges()

	if trimmed_text != "":
		if command_history.is_empty() or command_history.back() != trimmed_text:
			command_history.append(trimmed_text)
		history_index = command_history.size()

	input_line.clear()
	input_line.grab_focus()


	if trimmed_text != "":
		print_log("> " + text)

		var args = trimmed_text.split(" ", false)
		if args.size() > 0:
			var cmd = args[0].to_lower()

			match cmd:
				"help":
					print_log("[color=#aaffaa]Доступные команды:[/color]")
					print_log("  [color=yellow]spawn [предмет][/color] - выбросить предмет")
					print_log("  [color=yellow]items[/color] - список предметов")
					print_log("  [color=yellow]enemy [имя][/color] - заспавнить врага")
					print_log("  [color=yellow]enemies[/color] - список врагов")
					print_log("  [color=yellow]heal[/color] - восстановить здоровье")
					print_log("  [color=yellow]god[/color] - включить/выключить бессмертие")
					print_log("  [color=yellow]money [число][/color] - выдать валюту")
					print_log("  [color=yellow]killall[/color] - убить всех врагов")
					print_log("  [color=yellow]next[/color] - переход на следующий этаж")
					print_log("  [color=yellow]stats[/color] - разовый вывод системных ресурсов")
					print_log("  [color=yellow]monitor[/color] - вкл/выкл мониторинг производительности")
					print_log("  [color=yellow]clear[/color] - очистить консоль")

				"monitor":
					if has_node("/root/SysMonitor"):
						SysMonitor.toggle_monitor()
						var state_str = "ВКЛЮЧЕН" if SysMonitor.is_active else "ВЫКЛЮЧЕН"
						print_log("[color=cyan]SYS.MONITOR %s[/color]" % state_str)
					else:
						print_log("[color=red]Ошибка: Узел SysMonitor не найден в Autoload.[/color]")

				"stats":
					var fps = Engine.get_frames_per_second()
					var nodes = get_tree().get_node_count()
					var orphans = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
					var mem = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024 / 1024

					print_log("[color=cyan]=== СИСТЕМНЫЕ РЕСУРСЫ ===[/color]")
					print_log("FPS: [color=yellow]%d[/color]" % fps)
					print_log("Узлов в сцене: [color=yellow]%d[/color]" % nodes)
					print_log("Потерянные узлы: [color=red]%d[/color]" % orphans)
					print_log("Память (RAM): [color=yellow]%d MB[/color]" % mem)

				"god":
					var player = get_tree().get_first_node_in_group("player")
					if player:
						if player.has_meta("god_mode") and player.get_meta("god_mode"):
							player.set_meta("god_mode", false)
							print_log("[color=yellow]Режим бога ОТКЛЮЧЕН.[/color]")
						else:
							player.set_meta("god_mode", true)
							player.current_health = 9999.0
							if player.has_method("update_health_ui"): player.update_health_ui()
							print_log("[color=green]Режим бога ВКЛЮЧЕН (Здоровье 9999).[/color]")
					else:
						print_log("[color=red]Игрок не найден![/color]")

				"items":
					print_log("[color=#aaffaa]Список предметов (ID):[/color]")
					for item in item_scenes.keys(): print_log("  - " + item)

				"spawn":
					if args.size() < 2:
						print_log("[color=red]Ошибка: Укажите ID предмета.[/color]")
					else:
						var item_name = args[1].to_lower()
						if item_scenes.has(item_name): spawn_item(item_name)
						else: print_log("[color=red]Ошибка: Предмет '%s' не найден.[/color]" % item_name)

				"enemies":
					print_log("[color=#aaffaa]Список врагов (ID):[/color]")
					for e in enemy_scenes.keys(): print_log("  - " + e)

				"enemy":
					if args.size() < 2:
						print_log("[color=red]Ошибка: Укажите ID врага.[/color]")
					else:
						var enemy_name = args[1].to_lower()
						if enemy_scenes.has(enemy_name): spawn_enemy(enemy_name)
						else: print_log("[color=red]Ошибка: Враг '%s' не найден.[/color]" % enemy_name)

				"heal":
					var player = get_tree().get_first_node_in_group("player")
					if player:
						player.current_health = Global.get_final_max_health()
						if player.has_method("update_health_ui"): player.update_health_ui()
						print_log("[color=green]Здоровье полностью восстановлено![/color]")
					else:
						print_log("[color=red]Игрок не найден![/color]")

				"money":
					var amount = 1000
					if args.size() > 1 and args[1].is_valid_int(): amount = args[1].to_int()
					Global.money += amount
					if Global.has_user_signal("money_updated"): Global.emit_signal("money_updated")
					print_log("[color=green]Выдано %d $. Баланс: %d[/color]" % [amount, Global.money])

				"killall", "clear_room":
					var killed = 0
					var targets = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("boss")
					for t in targets:
						if is_instance_valid(t) and t.has_method("die") and not t.get("is_dead"):
							t.die()
							killed += 1
					print_log("[color=green]Директива выполнена. Уничтожено: %d[/color]" % killed)

				"next", "skip":
					if Global.get("current_level") != null: Global.current_level += 1
					else: Global.set("current_level", 2)
					print_log("[color=green]Инициирован переход на сектор 0%d...[/color]" % Global.current_level)
					toggle_console()
					if has_node("/root/LoadingScreen"):
						LoadingScreen.change_scene("res://Scenes/level_generator.tscn", "> SYS.FORCED_JUMP")
					else:
						get_tree().change_scene_to_file("res://Scenes/level_generator.tscn")

				"clear":
					log_text.text = ""

				_:
					print_log("[color=red]Неизвестная команда: '%s'.[/color]" % cmd)

func spawn_item(item_name: String):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print_log("[color=red]Ошибка: Игрок не найден![/color]")
		return

	var scene_path = item_scenes[item_name]
	var item_scene = load(scene_path)

	if item_scene:
		var item_instance = item_scene.instantiate()
		player.get_parent().add_child(item_instance)
		var spawn_pos = player.global_position + Vector3(0, 1.5, 0)
		var forward_dir = - player.transform.basis.z.normalized()
		item_instance.global_position = spawn_pos + forward_dir * 1.5
		print_log("[color=green]Предмет '%s' заспавнен![/color]" % item_name)
	else:
		print_log("[color=red]ОШИБКА: Не удалось загрузить %s[/color]" % scene_path)

func spawn_enemy(enemy_name: String):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print_log("[color=red]Ошибка: Игрок не найден![/color]")
		return

	var scene_path = enemy_scenes[enemy_name]
	var enemy_scene = load(scene_path)

	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()
		player.get_parent().add_child(enemy_instance)

		var spawn_pos = player.global_position + Vector3(0, 0.5, 0)
		var forward_dir = - player.transform.basis.z.normalized()
		enemy_instance.global_position = spawn_pos + forward_dir * 5.0

		print_log("[color=green]Враг '%s' успешно заспавнен![/color]" % enemy_name)
	else:
		print_log("[color=red]ОШИБКА: Не удалось загрузить %s[/color]" % scene_path)

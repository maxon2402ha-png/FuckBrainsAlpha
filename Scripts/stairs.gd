extends Area3D

var is_transitioning: bool = false

func _process(delta):

	rotation_degrees.y += 45 * delta

func _on_body_entered(body):

	if is_transitioning:
		return


	if body.name == "Player" or body.is_in_group("player"):
		is_transitioning = true

		if Global.current_level < Global.MAX_LEVELS:
			Global.current_level += 1
			print("Переход на уровень: ", Global.current_level)


			if get_tree().root.has_node("LoadingScreen"):

				LoadingScreen.change_scene("res://Scenes/level_generator.tscn", "> ГЕНЕРАЦИЯ ЭТАЖА " + str(Global.current_level) + "...")
			else:

				push_error("ОШИБКА: LoadingScreen не найден в Autoload! Загружаю уровень напрямую.")
				get_tree().change_scene_to_file("res://Scenes/level_generator.tscn")

		else:
			print("ПОБЕДА! ВЫ ПРОШЛИ ИГРУ!")

			if get_tree().root.has_node("LoadingScreen"):
				LoadingScreen.change_scene("res://Scenes/main_menu.tscn", "> ЭКСТРАКЦИЯ ЗАВЕРШЕНА. ВОЗВРАТ...")
			else:
				get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

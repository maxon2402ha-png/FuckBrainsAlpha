extends Control

func _on_btn_pistol_pressed():
	Global.selected_weapon = "pistol"
	start_game()

func _on_btn_rifle_pressed():
	Global.selected_weapon = "rifle"
	start_game()

func start_game():
	get_tree().change_scene_to_file("res://Scenes/level_generator.tscn")

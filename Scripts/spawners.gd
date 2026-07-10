extends Node3D



var zombie_scene = preload("res://Scenes/enemy.tscn")


var spawn_interval = 3.0
var timer = 0.0


var spawn_points = []

func _ready():

	for child in get_children():
		if child is Marker3D:
			spawn_points.append(child)

func _process(delta):

	timer += delta

	if timer >= spawn_interval:
		spawn_zombie()
		timer = 0.0


		if spawn_interval > 0.5:
			spawn_interval -= 0.05

func spawn_zombie():

	if spawn_points.size() == 0:
		return


	var random_point = spawn_points.pick_random()


	var zombie = zombie_scene.instantiate()


	zombie.position = random_point.position



	get_parent().add_child(zombie)

	print("Родился новый зомби!")

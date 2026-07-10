extends Node3D


@onready var doors = {
	"North": $DoorNorth, 
	"South": $DoorSouth, 
	"East": $DoorEast, 
	"West": $DoorWest
}


var enemy_scene = preload("res://Scenes/enemy.tscn")
var item_scene = preload("res://Scenes/upgrade_item.tscn")
var medkit_scene = preload("res://Scenes/medkit.tscn")

var is_cleared = false
var active_enemies = 0
var connected_rooms = []


var spawn_range = 8.0

func _ready():

	pass

func open_passage(direction):
	connected_rooms.append(direction)
	doors[direction].visible = false
	doors[direction].set_collision_layer_value(1, false)

func close_passage(direction):
	doors[direction].visible = true
	doors[direction].set_collision_layer_value(1, true)



func _on_player_detector_body_entered(body):
	if is_cleared: return

	if body.is_in_group("player"):
		start_room_battle()

func start_room_battle():
	print("Бой начался!")


	for dir in connected_rooms:
		doors[dir].visible = true
		doors[dir].set_collision_layer_value(1, true)

	spawn_enemies()

func spawn_enemies():

	var count = randi_range(2, 5)
	active_enemies = count

	for i in range(count):
		var enemy = enemy_scene.instantiate()
		add_child(enemy)



		var random_x = randf_range( - spawn_range, spawn_range)
		var random_z = randf_range( - spawn_range, spawn_range)



		if abs(random_x) < 2.0 and abs(random_z) < 2.0:
			random_x += 3.0


		enemy.position = Vector3(random_x, 1.0, random_z)


		enemy.rotation.y = randf_range(0, TAU)


		if enemy.has_method("set_room"):
			enemy.set_room(self)

func on_enemy_killed():
	active_enemies -= 1
	if active_enemies <= 0:
		room_cleared()

func room_cleared():
	print("Победа!")
	is_cleared = true


	for dir in connected_rooms:
		doors[dir].visible = false
		doors[dir].set_collision_layer_value(1, false)

	spawn_rewards()

func spawn_rewards():
	var roll = randf()
	var reward = null

	if roll < 0.2:
		reward = item_scene.instantiate()
	elif roll < 0.8:
		reward = medkit_scene.instantiate()

	if reward:
		add_child(reward)

		reward.position = Vector3(0, 1, 0)

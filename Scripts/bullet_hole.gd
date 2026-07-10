extends Node3D

func _ready():

	await get_tree().create_timer(10.0).timeout
	queue_free()

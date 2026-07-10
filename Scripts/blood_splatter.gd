extends Node3D

@onready var particles = $GoreBurst

func _ready():

	particles.emitting = true


	await get_tree().create_timer(particles.lifetime + 0.1).timeout
	queue_free()

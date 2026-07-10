extends Node3D

func _ready():

	rotation_degrees.y = randf_range(0, 360)


	var tween = create_tween()
	tween.tween_interval(15.0)
	tween.tween_property($Decal, "albedo_mix", 0.0, 3.0)
	tween.tween_callback(queue_free)

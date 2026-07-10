extends Area3D

var life_time: float = 4.0
var slow_factor: float = 0.3

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var timer = get_tree().create_timer(life_time)
	timer.timeout.connect(destroy_puddle)

func _on_body_entered(body):
	if body.is_in_group("enemies") or body.is_in_group("boss"):
		if body.has_method("apply_slow"):
			body.apply_slow(slow_factor)

func _on_body_exited(body):
	if body.is_in_group("enemies") or body.is_in_group("boss"):
		if body.has_method("remove_slow"):
			body.remove_slow()

func destroy_puddle():

	for body in get_overlapping_bodies():
		if body.is_in_group("enemies") or body.is_in_group("boss"):
			if body.has_method("remove_slow"):
				body.remove_slow()
	queue_free()

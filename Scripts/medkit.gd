extends Area3D

var heal_amount = 50

func _process(delta):
	rotate_y(2.0 * delta)


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("heal"):
			body.heal(heal_amount)
			queue_free()

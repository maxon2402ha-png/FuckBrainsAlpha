extends Area3D

func _ready():

	pass

func _process(delta):

	rotation_degrees.y += 90 * delta

	position.y += sin(Time.get_ticks_msec() / 150.0) * 0.005


func _on_body_entered(body):

	if body.is_in_group("player") or body.name == "Player":
		apply_upgrade()

		queue_free()

func apply_upgrade():


	Global.add_item("speed_syringe")

extends Area3D

var velocity: Vector3 = Vector3.ZERO
var fall_gravity: float = 12.0
var damage: float = 15.0
var life_time: float = 4.0

func _ready():

	body_entered.connect(_on_body_entered)

func _physics_process(delta):

	velocity.y -= fall_gravity * delta
	global_position += velocity * delta

	life_time -= delta
	if life_time <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies") or body.is_in_group("boss"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()

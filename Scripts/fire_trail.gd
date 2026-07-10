extends Area3D

var lifetime: float = 4.0
var tick_timer: float = 0.0

func _ready():

	if get_child_count() == 0:
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 1.0
		shape.height = 1.0
		col.shape = shape
		add_child(col)

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

	tick_timer -= delta
	if tick_timer <= 0:
		tick_timer = 0.5
		for body in get_overlapping_bodies():
			if (body.is_in_group("enemies") or body.is_in_group("boss")) and not body.get("is_dead"):
				if body.has_method("take_damage") and "max_health" in body:

					var dmg = body.max_health * 0.005 * Global.soldering_iron_count
					body.take_damage(dmg)

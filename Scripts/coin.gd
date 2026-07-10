extends Node3D

var velocity: Vector3 = Vector3.ZERO
var gravity: float = 28.0
var value: int = 1
var friction: float = 0.8

enum State{POPPING, WAITING, HOMING}
var current_state = State.POPPING
var wait_timer: float = 0.0
var homing_speed: float = 0.0
var player: Node3D = null

@onready var mesh = find_child("Mesh*", true, false)

func _ready():
	_reset_and_launch()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_reset_and_launch()

func _reset_and_launch():
	current_state = State.POPPING
	homing_speed = 5.0
	wait_timer = randf_range(0.4, 0.7)

	velocity = Vector3(randf_range(-5.0, 5.0), randf_range(8.0, 14.0), randf_range(-5.0, 5.0))
	player = get_tree().get_first_node_in_group("player")
	if mesh: mesh.scale = Vector3.ONE

func _physics_process(delta):
	if not visible: return

	match current_state:
		State.POPPING:

			velocity.y -= gravity * delta
			var next_pos = global_position + velocity * delta


			var space_state = get_world_3d().direct_space_state

			var query = PhysicsRayQueryParameters3D.create(global_position, next_pos + Vector3.DOWN * 0.1)
			query.collision_mask = 1

			var result = space_state.intersect_ray(query)

			if result and velocity.y < 0:

				global_position.y = result.position.y + 0.1
				if velocity.y < -3.0:
					velocity.y = - velocity.y * 0.5
					velocity.x *= friction
					velocity.z *= friction
				else:

					current_state = State.WAITING
			else:
				global_position = next_pos


			if mesh:
				mesh.rotate_y(delta * 10.0)
				mesh.rotate_x(delta * 5.0)

		State.WAITING:
			wait_timer -= delta
			if wait_timer <= 0:
				current_state = State.HOMING

		State.HOMING:
			if is_instance_valid(player) and not player.get("is_dead"):
				var target_pos = player.global_position + Vector3(0, 1.2, 0)
				var dir = global_position.direction_to(target_pos)


				homing_speed += delta * 45.0
				global_position += dir * homing_speed * delta


				if mesh: mesh.look_at(target_pos, Vector3.UP)

				if global_position.distance_to(target_pos) < 1.2:
					collect()
			else:
				Global.despawn_to_pool(self)

func collect():
	Global.add_money(value)
	if is_instance_valid(player) and player.has_node("HitmarkerPlayer"):
		var audio = player.get_node("HitmarkerPlayer")
		audio.pitch_scale = randf_range(1.6, 2.0)
		audio.play()
	Global.despawn_to_pool(self)

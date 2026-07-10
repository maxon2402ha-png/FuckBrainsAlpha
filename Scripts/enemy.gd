extends CharacterBody3D

signal enemy_died


enum State{IDLE, CHASE, STRAFE, SEARCH, ATTACK, LUNGE, DEAD}
var current_state = State.CHASE


var max_health: float = 30.0
var current_health: float = 30.0
var damage: float = 15.0


var move_speed: float = 7.0
var strafe_speed: float = 5.0
var speed_multiplier: float = 1.0
var current_strafe_speed: float = 5.0
const GRAVITY = 25.0
const JUMP_VELOCITY = 6.0


var cached_flash_mat: StandardMaterial3D = null

var attack_range: float = 2.4
var strafe_range: float = 4.0

var attack_cooldown: float = 0.0
var attack_speed: float = 1.0
var stun_timer: float = 0.0
var is_attacking: bool = false

var strafe_dir: Vector3 = Vector3.ZERO
var strafe_timer: float = 0.0

var hunt_speed_bonus: float = 1.0

var is_elite: bool = false
var lunge_cooldown: float = 0.0
var lunge_timer: float = 0.0
var lunge_dir: Vector3 = Vector3.ZERO

var target_node: Node3D = null
var last_known_position: Vector3 = Vector3.INF
var search_timer: float = 0.0

var path_update_timer: float = 0.0
const PATH_UPDATE_RATE: float = 0.15

@onready var nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")

var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var pre_collision_vel: Vector3 = Vector3.ZERO
var dodge_dir: Vector3 = Vector3.ZERO

var prop_kick_timer: float = 0.0

var visual_pivot: Node3D = null
var flinch_tween: Tween = null

@onready var anim_player = find_child("AnimationPlayer*", true, false)
var current_anim_name: String = ""

var groan_sound = preload("res://Assets/Sound/groan.mp3")
var die_sound = preload("res://Assets/Sound/die.mp3")
var attack_sound = preload("res://Assets/Sound/attack.mp3")
var coin_scene = preload("res://Scenes/coin.tscn")
var blood_scene = preload("res://Scenes/blood_splatter.tscn")

var my_room = null
var is_friendly: bool = false
var base_mat_override = null

var is_lightbulb_target: bool = false
var lightbulb_light: OmniLight3D = null

var is_leaving: bool = false
var is_dead = false
var is_bleeding = false

var groan_timer = 0.0
@onready var audio_player = $ZombieSound


var is_shishkin_projectile: bool = false
var shishkin_target: Node3D = null
var is_kamikaze: bool = false

func _ready():

	if Global.condoms_count > 0:
		if randf() < 0.4 and randf() < 0.3:
			queue_free()
			return

	global_position += Vector3(randf_range(-0.2, 0.2), 0.1, randf_range(-0.2, 0.2))

	var base_hp = 30.0
	var base_dmg = 15.0

	max_health = base_hp * Global.get_enemy_hp_multiplier()
	current_health = max_health
	damage = base_dmg * Global.get_enemy_dmg_multiplier()

	if randf() < 0.15 and not is_friendly: make_elite()


	if Global.kamikaze_chance > 0 and randf() < Global.kamikaze_chance:
		make_kamikaze()

	groan_timer = randf_range(5.0, 15.0)
	path_update_timer = randf_range(0.0, PATH_UPDATE_RATE)

	if audio_player: audio_player.volume_db = -18.0

	if not nav_agent:
		nav_agent = NavigationAgent3D.new()
		add_child(nav_agent)

	if nav_agent:
		nav_agent.path_desired_distance = 1.5
		nav_agent.target_desired_distance = 1.0
		nav_agent.avoidance_enabled = false
		nav_agent.radius = 1.2 if is_elite else 0.8

	strafe_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	current_strafe_speed = strafe_speed

	var old_anim = find_child("AnimationPlayer*", true, false)
	if old_anim: old_anim.stop()

	for child in get_children():
		if child is Node3D and child != $CollisionShape3D and not child is NavigationAgent3D and child.name != "HeadTarget" and child.name != "ZombieSound":
			visual_pivot = child
			break

	if not visual_pivot:
		visual_pivot = self

	play_smart_anim(["idle", "stand"])



func apply_bread_taunt():
	if is_dead: return
	add_to_group("taunted")
	set_model_color(Color(0.8, 0.5, 0.1), true)
	spawn_custom_text("АГРО!", Color.ORANGE)

	get_tree().create_timer(5.0).timeout.connect( func():
		if is_inside_tree() and not is_dead:
			remove_from_group("taunted")
			set_model_color(Color.WHITE)
	)

func apply_stun(duration: float):
	if is_dead: return
	stun_timer = max(stun_timer, duration)
	spawn_custom_text("ОГЛУШЕН", Color.YELLOW)

func apply_shishkin_launch(target: Node3D):
	if is_dead or not is_instance_valid(target): return
	is_shishkin_projectile = true
	shishkin_target = target
	collision_mask = 0
	set_model_color(Color.RED, true)
	spawn_custom_text("ЗАПУСК!", Color.RED)
	if audio_player:
		audio_player.stream = attack_sound
		audio_player.pitch_scale = 1.5
		audio_player.play()

func make_kamikaze():
	is_kamikaze = true
	make_friendly()
	set_model_color(Color(1.0, 0.2, 0.0), true)
	move_speed *= 1.5
	spawn_custom_text("СБОЙ ИМПЛАНТА", Color.RED)



func play_smart_anim(keywords: Array, anim_speed: float = 1.0, force: bool = false):
	if not anim_player: return
	var anim_list = anim_player.get_animation_list()
	if anim_list.is_empty(): return

	if not force and anim_player.is_playing() and ("attack" in current_anim_name.to_lower() or "melee" in current_anim_name.to_lower() or "punch" in current_anim_name.to_lower() or "die" in current_anim_name.to_lower() or "death" in current_anim_name.to_lower()):
		var is_important = false
		for kw in keywords:
			if kw.to_lower() in ["die", "death"]: is_important = true
		if not is_important: return

	var found = false
	for kw in keywords:
		for anim in anim_list:
			if kw.to_lower() in anim.to_lower():
				if current_anim_name != anim or not anim_player.is_playing() or force:
					anim_player.play(anim, 0.25)
					current_anim_name = anim
				anim_player.speed_scale = anim_speed
				found = true
				return

	if not found:
		var fallback = anim_list[0]
		if current_anim_name != fallback or not anim_player.is_playing() or force:
			anim_player.play(fallback, 0.25)
			current_anim_name = fallback
		anim_player.speed_scale = anim_speed

func _apply_safe_movement():
	if is_nan(velocity.x) or is_nan(velocity.y) or is_nan(velocity.z):
		velocity = Vector3.ZERO

	velocity.x = clamp(velocity.x, -25.0, 25.0)
	velocity.y = clamp(velocity.y, -40.0, 25.0)
	velocity.z = clamp(velocity.z, -25.0, 25.0)

	pre_collision_vel = velocity
	move_and_slide()
	push_rigid_bodies()

func _physics_process(delta):
	if not is_on_floor() and not is_shishkin_projectile:
		velocity.y -= GRAVITY * delta

	if is_dead:
		_apply_safe_movement()
		return

	if is_leaving or not is_inside_tree(): return

	if global_position.y < -15.0:
		die()
		return


	if is_shishkin_projectile:
		if is_instance_valid(shishkin_target) and not shishkin_target.get("is_dead"):
			var dir = global_position.direction_to(shishkin_target.global_position)
			velocity = dir * 35.0
			var dist = global_position.distance_to(shishkin_target.global_position)

			if dist < 1.5:
				if shishkin_target.has_method("take_damage"):
					shishkin_target.take_damage(9999.0)
				die()
			_apply_safe_movement()
		else:
			die()
		return

	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 15.0 * delta)
		_apply_safe_movement()
		return


	if is_kamikaze and is_instance_valid(target_node):
		if global_position.distance_to(target_node.global_position) <= attack_range + 0.5:
			take_damage(9999.0)
			return

	groan_timer -= delta
	if groan_timer <= 0:
		if randf() < 0.05 and audio_player and not audio_player.playing:
			audio_player.stream = groan_sound
			audio_player.pitch_scale = randf_range(0.6, 0.8) if is_elite else randf_range(0.9, 1.2)
			audio_player.play()
		groan_timer = randf_range(10.0, 20.0)

	path_update_timer -= delta
	if path_update_timer <= 0.0:
		target_node = find_best_target()
		path_update_timer = PATH_UPDATE_RATE

		if is_instance_valid(target_node):
			var target_vel = target_node.get("velocity") if "velocity" in target_node else Vector3.ZERO
			var dist = global_position.distance_to(target_node.global_position)
			var look_ahead_time = clamp(dist / move_speed, 0.0, 1.0)
			last_known_position = target_node.global_position + (target_vel * look_ahead_time * 0.6)

		if nav_agent and last_known_position != Vector3.INF:
			nav_agent.target_position = last_known_position

	var dist_to_target = INF

	if prop_kick_timer > 0:
		prop_kick_timer -= delta
	elif is_instance_valid(target_node):
		try_kick_prop()

	if is_attacking:
		current_state = State.ATTACK
	elif is_instance_valid(target_node):
		dist_to_target = global_position.distance_to(target_node.global_position)
		var has_los = check_line_of_sight(target_node)

		if has_los:
			hunt_speed_bonus = lerp(hunt_speed_bonus, 1.0, delta * 2.0)

			if dist_to_target <= attack_range:
				current_state = State.ATTACK
			elif dist_to_target <= (9.0 if is_elite else 7.0) and dist_to_target > 3.0 and lunge_cooldown <= 0 and is_on_floor():
				var target_look_dir = - target_node.global_transform.basis.z.normalized()
				var dir_to_enemy = target_node.global_position.direction_to(global_position)
				var dot_prod = target_look_dir.dot(dir_to_enemy)

				if dot_prod < 0.2 or randf() < 0.005:
					current_state = State.LUNGE
					_start_lunge()
			elif attack_cooldown > 0 and dist_to_target < strafe_range:
				current_state = State.STRAFE
			else:
				current_state = State.CHASE
		else:
			if current_state in [State.CHASE, State.STRAFE, State.LUNGE, State.ATTACK]:
				current_state = State.SEARCH
				search_timer = 6.0
	elif last_known_position != Vector3.INF:
		current_state = State.SEARCH
	else:
		current_state = State.IDLE

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
			play_smart_anim(["idle", "stand"])

		State.CHASE, State.SEARCH:
			var final_speed = move_speed * speed_multiplier
			if current_state == State.SEARCH:
				hunt_speed_bonus = lerp(hunt_speed_bonus, 1.35, delta * 0.5)
				final_speed *= hunt_speed_bonus
				search_timer -= delta
				if search_timer <= 0 or global_position.distance_to(last_known_position) < 2.0:
					last_known_position = Vector3.INF
					current_state = State.IDLE

			process_movement(delta, final_speed)

		State.STRAFE:
			process_strafe(delta)

		State.LUNGE:
			_process_lunge(delta)

		State.ATTACK:
			_process_attack_state(delta)

	if attack_cooldown > 0: attack_cooldown -= delta
	if lunge_cooldown > 0: lunge_cooldown -= delta

	anti_stuck_system(delta)
	_apply_safe_movement()

func _process_attack_state(delta):
	if is_instance_valid(target_node):
		face_target(delta, target_node.global_position)
		var dir = global_position.direction_to(target_node.global_position)
		dir.y = 0;dir = dir.normalized()

		if is_attacking:
			velocity.x = lerp(velocity.x, dir.x * (move_speed * 1.5), 12.0 * delta)
			velocity.z = lerp(velocity.z, dir.z * (move_speed * 1.5), 12.0 * delta)
		else:
			if attack_cooldown <= 0:
				attack_target(target_node)
			else:
				velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
				velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
	else:
		is_attacking = false
		current_state = State.IDLE

func _start_lunge():
	lunge_timer = 0.4
	var p_vel = target_node.get("velocity") if target_node.get("velocity") != null else Vector3.ZERO
	p_vel.y = 0
	var aim_pos = target_node.global_position + (p_vel * 0.4)

	if not global_position.is_equal_approx(aim_pos):
		lunge_dir = global_position.direction_to(aim_pos)
		lunge_dir.y = 0;lunge_dir = lunge_dir.normalized()
		velocity.y = JUMP_VELOCITY
		play_smart_anim(["jump", "lunge", "dash", "run"], 1.5, true)

func _process_lunge(delta):
	lunge_timer -= delta
	if is_instance_valid(target_node) and global_position.distance_to(target_node.global_position) <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		current_state = State.ATTACK
		lunge_timer = 0.0
		lunge_cooldown = randf_range(1.5, 2.5)
	else:
		var lunge_speed = 14.0 if is_elite else 10.0
		velocity.x = lerp(velocity.x, lunge_dir.x * lunge_speed * speed_multiplier, 10.0 * delta)
		velocity.z = lerp(velocity.z, lunge_dir.z * lunge_speed * speed_multiplier, 10.0 * delta)

		if lunge_dir.length_squared() > 0.01 and visual_pivot != self:
			var target_angle = atan2( - lunge_dir.x, - lunge_dir.z) + PI
			visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_angle, 10.0 * delta)

	if lunge_timer <= 0 and current_state == State.LUNGE:
		current_state = State.CHASE
		lunge_cooldown = randf_range(1.5, 2.5)

func try_kick_prop():
	if not is_instance_valid(target_node): return
	var dist_to_target = global_position.distance_to(target_node.global_position)
	if dist_to_target < 3.0 or dist_to_target > 15.0: return

	var space_state = get_world_3d().direct_space_state
	var forward_dir = - global_transform.basis.z.normalized()

	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 1.0
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere_shape
	query.transform = Transform3D(Basis(), global_position + Vector3(0, 1.0, 0) + forward_dir * 1.5)
	query.exclude = [self.get_rid()]

	var results = space_state.intersect_shape(query, 1)
	if results.size() > 0 and results[0].collider is RigidBody3D:
		var col = results[0].collider
		var dir_to_player = global_position.direction_to(target_node.global_position + Vector3(0, 1.0, 0))
		var kick_dir = (dir_to_player * 1.0 + Vector3.UP * 0.2).normalized()
		var force = 30.0 * col.mass
		col.apply_central_impulse(kick_dir * force)
		col.angular_velocity = Vector3.ZERO
		if col.has_method("get_kicked"): col.get_kicked(global_position, "enemy")
		prop_kick_timer = randf_range(3.0, 5.0)

func process_movement(delta, speed_val: float):
	if nav_agent and not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		if is_instance_valid(target_node) and target_node.global_position.y < global_position.y - 1.0 and global_position.distance_to(target_node.global_position) < 15.0:
			next_pos = target_node.global_position

		if global_position.is_equal_approx(next_pos): return

		var dir = global_position.direction_to(next_pos)
		dir.y = 0;dir = dir.normalized()

		var final_dir = dir
		var separation_force = get_separation_force()
		final_dir = (final_dir + separation_force * 1.0).normalized()

		if dodge_dir != Vector3.ZERO:
			final_dir = (final_dir + dodge_dir * 1.5).normalized()
			dodge_dir = dodge_dir.lerp(Vector3.ZERO, 2.0 * delta)

		velocity.x = lerp(velocity.x, final_dir.x * speed_val, 5.0 * delta)
		velocity.z = lerp(velocity.z, final_dir.z * speed_val, 5.0 * delta)

		if final_dir.length_squared() > 0.01 and visual_pivot != self:
			var target_angle = atan2( - final_dir.x, - final_dir.z) + PI
			visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_angle, 6.0 * delta)

			play_smart_anim(["run", "sprint", "walk", "move"], (speed_val / move_speed))
	else:
		velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
		play_smart_anim(["idle", "stand"])

func process_strafe(delta):
	strafe_timer -= delta

	if strafe_timer <= 0:
		strafe_dir.x = sign(randf_range(-1.0, 1.0))
		if strafe_dir.x == 0: strafe_dir.x = 1.0
		strafe_dir.z = randf_range(-0.3, 0.2)
		strafe_timer = randf_range(1.5, 3.0)
		current_strafe_speed = strafe_speed * speed_multiplier * randf_range(0.9, 1.2)

	if is_on_wall():
		strafe_dir.x *= -1.0
		strafe_timer = 1.0

	if not is_instance_valid(target_node): return
	if global_position.is_equal_approx(target_node.global_position): return

	var dir_to_target = global_position.direction_to(target_node.global_position)
	dir_to_target.y = 0;dir_to_target = dir_to_target.normalized()

	var right_vector = dir_to_target.cross(Vector3.UP).normalized()
	var strafe_vec = (right_vector * strafe_dir.x) + (dir_to_target * strafe_dir.z)

	var separation = get_separation_force()
	var final_dir = (strafe_vec * 0.8 + separation * 1.5).normalized()

	velocity.x = lerp(velocity.x, final_dir.x * current_strafe_speed, 6.0 * delta)
	velocity.z = lerp(velocity.z, final_dir.z * current_strafe_speed, 6.0 * delta)

	face_target(delta, target_node.global_position)

	if strafe_dir.x < -0.1: play_smart_anim(["strafe_right", "leftstrafe", "right", "walk", "run"], 1.2)
	elif strafe_dir.x > 0.1: play_smart_anim(["strafe_left", "rightstrafe", "left", "walk", "run"], 1.2)
	else: play_smart_anim(["run", "walk", "move"], 1.2)

func anti_stuck_system(delta):
	if is_instance_valid(target_node) and global_position.distance_to(target_node.global_position) <= attack_range + 1.0:
		stuck_timer = 0.0;last_position = global_position;return

	var dist_moved = Vector2(global_position.x, global_position.z).distance_to(Vector2(last_position.x, last_position.z))
	var is_trying_to_move = current_state in [State.CHASE, State.STRAFE, State.SEARCH]

	if is_trying_to_move and dist_moved < 0.02 * (delta * 60.0):
		stuck_timer += delta
		if stuck_timer > 0.3:
			var space_state = get_world_3d().direct_space_state
			var forward = Vector3.ZERO
			var right = Vector3.ZERO
			if visual_pivot != self:
				forward = visual_pivot.global_transform.basis.z.normalized()
				right = visual_pivot.global_transform.basis.x.normalized()
			else:
				forward = - global_transform.basis.z.normalized()
				right = global_transform.basis.x.normalized()

			var start = global_position + Vector3(0, 0.5, 0)

			var left_ray = PhysicsRayQueryParameters3D.create(start, start + (forward - right).normalized() * 2.0)
			var right_ray = PhysicsRayQueryParameters3D.create(start, start + (forward + right).normalized() * 2.0)
			left_ray.exclude = [get_rid()];right_ray.exclude = [get_rid()]

			var hit_left = space_state.intersect_ray(left_ray)
			var hit_right = space_state.intersect_ray(right_ray)

			if hit_left and not hit_right: dodge_dir = right
			elif hit_right and not hit_left: dodge_dir = - right
			else: dodge_dir = (right * (1 if randf() > 0.5 else -1)).normalized()

		if stuck_timer > 1.0 and is_on_floor():
			velocity.y = JUMP_VELOCITY
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	last_position = global_position

func get_separation_force() -> Vector3:
	if is_attacking: return Vector3.ZERO

	var force = Vector3.ZERO
	var neighbor_count = 0
	var avoid_radius = 2.0 if is_elite else 1.5

	var space_state = get_world_3d().direct_space_state
	var sphere = SphereShape3D.new()
	sphere.radius = avoid_radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = global_transform
	query.exclude = [self.get_rid()]

	var results = space_state.intersect_shape(query, 6)
	for res in results:
		if res.collider is CharacterBody3D and res.collider.is_in_group("enemies"):
			var other_pos = res.collider.global_position
			if global_position.is_equal_approx(other_pos): continue

			var push_dir = other_pos.direction_to(global_position)
			push_dir.y = 0
			var dist = global_position.distance_to(other_pos)
			if dist < 0.1: dist = 0.1
			force += push_dir * (avoid_radius / dist)
			neighbor_count += 1

	if neighbor_count > 0: force = force / neighbor_count

	if force.length() > 2.0:
		force = force.normalized() * 2.0

	return force

func face_target(delta, target_pos: Vector3):
	if global_position.is_equal_approx(target_pos): return
	var look_dir = global_position.direction_to(target_pos)
	look_dir.y = 0
	if look_dir.length_squared() > 0.01 and visual_pivot != self:
		var target_yaw = atan2( - look_dir.x, - look_dir.z) + PI
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_yaw, 10.0 * delta)

func check_line_of_sight(target: Node3D) -> bool:
	if not is_instance_valid(target): return false
	var space_state = get_world_3d().direct_space_state
	var start = global_position + Vector3(0, 1.0, 0)
	var end = target.global_position + Vector3(0, 1.0, 0)
	var query = PhysicsRayQueryParameters3D.create(start, end, 1)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	if result: return result.collider == target
	return true

func find_best_target() -> Node3D:
	var best_target = null
	var best_score = INF


	var taunted = get_tree().get_nodes_in_group("taunted")
	for t in taunted:
		if is_instance_valid(t) and t != self and not t.get("is_dead"):
			var d = global_position.distance_to(t.global_position)
			if d < best_score: best_score = d;best_target = t
	if best_target: return best_target

	if is_friendly:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != self and not e.get("is_dead"):
				var d = global_position.distance_to(e.global_position)
				if d < best_score: best_score = d;best_target = e
		if best_target == null: best_target = get_tree().get_first_node_in_group("player")
	else:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			best_score = global_position.distance_to(player.global_position)
			best_target = player

		var friendlies = get_tree().get_nodes_in_group("friendlies")
		for f in friendlies:
			if is_instance_valid(f) and not f.get("is_dead") and not f.get("is_leaving"):
				var d = global_position.distance_to(f.global_position)
				var score = d + 15.0
				if score < best_score: best_score = score;best_target = f
	return best_target

func attack_target(target):
	if is_dead or is_leaving or not is_inside_tree(): return

	is_attacking = true

	var punches = []
	if anim_player:
		for anim in anim_player.get_animation_list():
			var lower = anim.to_lower()
			if "punch" in lower or "attack" in lower or "melee" in lower:
				punches.append(anim)

	if punches.size() > 0:
		var chosen_punch = punches.pick_random()
		anim_player.play(chosen_punch, 0.2)
		anim_player.speed_scale = 1.0 / attack_speed
		current_anim_name = chosen_punch
	else:
		play_smart_anim(["attack", "melee", "punch"], 1.0 / attack_speed, true)

	if audio_player and is_inside_tree():
		audio_player.stop()
		audio_player.pitch_scale = 0.8 if is_elite else 1.0
		audio_player.stream = attack_sound
		audio_player.volume_db = -10.0 if is_elite else -12.0
		audio_player.play()

	var tree = get_tree()
	if tree: await tree.create_timer(0.35).timeout

	is_attacking = false
	attack_cooldown = attack_speed + randf_range(-0.1, 0.1)

	if not is_inside_tree() or is_dead or stun_timer > 0: return

	if is_instance_valid(target) and global_position.distance_to(target.global_position) <= attack_range + 0.8:
		var final_dmg = damage
		if is_in_group("boss"): final_dmg *= (1.0 + (0.5 * Global.panties_count))
		elif Global.panties_count > 0:
			var player = get_tree().get_first_node_in_group("player")
			if player and global_position.distance_to(player.global_position) <= 8.0:
				final_dmg *= pow(0.7, Global.panties_count)

		if target.has_method("take_damage"): target.take_damage(final_dmg, "Enemy", self)

func spawn_retro_blood(hit_pos: Vector3, hit_dir: Vector3):
	if not blood_scene or not is_inside_tree(): return
	var blood = blood_scene.instantiate()
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	root.add_child(blood)
	blood.global_position = hit_pos if hit_pos != Vector3.ZERO else global_position + Vector3(0, 1.0, 0)
	if hit_dir != Vector3.ZERO and hit_dir.length_squared() > 0.01:
		var look_target = blood.global_position + hit_dir
		if abs(hit_dir.y) < 0.99:
			blood.look_at(look_target, Vector3.UP)
		else:
			blood.look_at(look_target, Vector3.RIGHT)

func take_damage(amount: float, is_crit = false, hit_pos = Vector3.ZERO, _hit_dir = Vector3.ZERO, _hit_bone = null) -> bool:
	if is_dead or not is_inside_tree() or is_leaving: return false

	var is_headshot = false
	if hit_pos != Vector3.ZERO and has_node("HeadTarget"):
		var head_pos = $HeadTarget.global_position
		if hit_pos.distance_to(head_pos) <= 0.45 * scale.y:
			is_headshot = true;amount *= 2.0;is_crit = true
			if audio_player and is_inside_tree():
				audio_player.stream = die_sound
				audio_player.pitch_scale = randf_range(1.8, 2.2)
				audio_player.volume_db = -10.0
				audio_player.play()

	current_health -= amount


	Global.spawn_damage_number(int(amount), global_position + Vector3(0, 1.5, 0), is_crit)

	flash_red()

	if _hit_dir != Vector3.ZERO: spawn_retro_blood(hit_pos, _hit_dir)
	else: spawn_retro_blood(global_position + Vector3(0, 1.0, 0), Vector3.UP)

	if _hit_dir != Vector3.ZERO:
		var push_force = 3.0 if is_crit else 1.5
		velocity += _hit_dir * push_force

		if visual_pivot and visual_pivot != self:
			if flinch_tween and flinch_tween.is_valid(): flinch_tween.kill()
			flinch_tween = create_tween()

			var local_dir = visual_pivot.global_transform.basis.inverse() * _hit_dir
			var pitch = local_dir.z * (0.1 if is_crit else 0.05)
			var roll = - local_dir.x * (0.1 if is_crit else 0.05)

			flinch_tween.tween_property(visual_pivot, "rotation:x", pitch, 0.05).set_ease(Tween.EASE_OUT)
			flinch_tween.parallel().tween_property(visual_pivot, "rotation:z", roll, 0.05).set_ease(Tween.EASE_OUT)
			flinch_tween.chain().tween_property(visual_pivot, "rotation:x", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
			flinch_tween.parallel().tween_property(visual_pivot, "rotation:z", 0.0, 0.2).set_trans(Tween.TRANS_SINE)

	if current_health <= 0: die()
	return is_headshot

func set_model_color(color: Color, emission: bool = false):
	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if not model_node: return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emission:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0

	mat.rim_enabled = true;mat.rim = 0.6
	base_mat_override = mat

	var meshes = []
	if model_node is MeshInstance3D: meshes.append(model_node)
	else:
		for child in model_node.get_children():
			if child is MeshInstance3D: meshes.append(child)
	for mesh in meshes: mesh.material_override = mat

func leave_room():
	if is_dead or is_leaving: return
	is_leaving = true
	current_state = State.IDLE
	collision_layer = 0;collision_mask = 0
	spawn_custom_text("Я СДЕЛАЛ СВОЕ ДЕЛО!", Color(0.8, 0.8, 0.8))

	var tree = get_tree()
	if tree:
		var tween = tree.create_tween()
		tween.tween_property(self, "scale", Vector3.ZERO, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)

func spawn_custom_text(text_str: String, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.text = text_str;label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test = true
	label.font_size = 60;label.outline_size = 15;label.modulate = color

	get_parent().add_child(label)
	var start_pos = global_position + Vector3(0, 2.5 * scale.y, 0)
	var end_pos = start_pos + Vector3(0, 1.5, 0)
	label.global_position = start_pos

	var tree = get_tree()
	if tree:
		var tween = tree.create_tween()
		if tween:
			tween.set_parallel(true)
			tween.tween_property(label, "global_position", end_pos, 1.0).set_ease(Tween.EASE_OUT)
			tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)
			tween.chain().tween_callback(label.queue_free)

func make_lightbulb_target():
	is_lightbulb_target = true
	lightbulb_light = OmniLight3D.new()
	lightbulb_light.light_color = Color(1.0, 1.0, 0.2)
	lightbulb_light.light_energy = 4.0;lightbulb_light.omni_range = 5.0
	add_child(lightbulb_light)
	lightbulb_light.position = Vector3(0, 2.5, 0)
	set_model_color(Color(1.0, 1.0, 0.2), true)

func make_elite():
	is_elite = true
	max_health *= 2.5;current_health = max_health
	damage *= 1.5;move_speed *= 1.3;scale *= 1.2
	set_model_color(Color(0.8, 0.1, 0.1), true)

func make_friendly():
	is_friendly = true
	remove_from_group("enemies")
	add_to_group("friendlies")
	max_health *= 2.0;current_health = max_health;damage *= 1.5
	set_model_color(Color(0.2, 1.0, 0.2))

func apply_slow(factor: float): speed_multiplier = factor
func remove_slow(): speed_multiplier = 1.0

func set_stats(hp_multiplier: float, dmg_multiplier: float):
	max_health *= hp_multiplier
	current_health = max_health
	damage *= dmg_multiplier

func investigate_sound(sound_pos: Vector3):
	if is_dead or current_state in [State.ATTACK, State.LUNGE]: return
	last_known_position = sound_pos
	current_state = State.SEARCH
	search_timer = 6.0

func flash_red():
	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if not model_node: return

	if not cached_flash_mat:
		cached_flash_mat = StandardMaterial3D.new()
		cached_flash_mat.albedo_color = Color.WHITE
		cached_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var meshes = []
	if model_node is MeshInstance3D: meshes.append(model_node)
	else:
		for child in model_node.get_children():
			if child is MeshInstance3D: meshes.append(child)

	for mesh in meshes: mesh.material_override = cached_flash_mat

	var tree = get_tree()
	if tree: await tree.create_timer(0.1).timeout

	if is_instance_valid(self) and not is_dead:
		for mesh in meshes: mesh.material_override = base_mat_override

func die():
	if is_dead: return
	is_dead = true

	remove_from_group("enemies")
	enemy_died.emit()

	collision_layer = 0
	collision_mask = 1


	if is_kamikaze or is_shishkin_projectile:
		spawn_custom_text("БУМ!", Color.RED)
		var enemies = get_tree().get_nodes_in_group("enemies")
		var player = get_tree().get_first_node_in_group("player")


		for e in enemies:
			if is_instance_valid(e) and not e.get("is_dead") and e != self:
				if global_position.distance_to(e.global_position) < 4.0:
					if e.has_method("take_damage"): e.take_damage(200.0)
		if player and global_position.distance_to(player.global_position) < 4.0:
			if player.has_method("take_damage"): player.take_damage(50.0)

	var main_col = get_node_or_null("CollisionShape3D")
	if main_col: main_col.set_deferred("disabled", true)

	var root = get_tree().current_scene if get_tree().current_scene else get_parent()

	if not is_friendly:
		var is_elite_enemy = get("is_elite") if "is_elite" in self else false
		var base_score = 25 if is_elite_enemy else 10


		if Global.midas_touch_count > 0:
			var player = get_tree().get_first_node_in_group("player")
			if player and global_position.distance_to(player.global_position) < 4.0:
				base_score *= 2
				spawn_custom_text("МИДАС!", Color.GOLD)

		Global.score += base_score * Global.exp_multiplier
		spawn_coin_shower()
		if is_lightbulb_target: Global.add_money(10 * Global.lightbulb_count)

	if die_sound and root:
		var temp_sound = AudioStreamPlayer3D.new()
		temp_sound.stream = die_sound;temp_sound.unit_size = 10.0
		var is_elite_enemy = get("is_elite") if "is_elite" in self else false
		temp_sound.volume_db = -10.0 if is_elite_enemy else -15.0
		temp_sound.pitch_scale = randf_range(1.5, 2.0)
		root.add_child(temp_sound)
		temp_sound.global_position = global_position
		temp_sound.play()
		temp_sound.finished.connect(temp_sound.queue_free)

	play_smart_anim(["death", "die", "dead"], 1.0, true)

	get_tree().create_timer(10.0).timeout.connect(queue_free)

func set_room(room_node): my_room = room_node
func get_health_percent() -> float: return current_health / max_health

func apply_bleed(dmg_per_tick: float, duration: float):
	if is_bleeding or is_dead: return
	is_bleeding = true
	var timer = 0.0
	while timer < duration:
		var tree = get_tree()
		if not tree: break
		await tree.create_timer(1.0).timeout
		if is_dead or not is_inside_tree(): break
		take_damage(dmg_per_tick)
		timer += 1.0
	is_bleeding = false

func push_rigid_bodies():
	var speed_length = Vector2(pre_collision_vel.x, pre_collision_vel.z).length()

	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()

		if collider.is_in_group("items") or collider.name.to_lower().begins_with("item") or collider.name.to_lower().begins_with("coin"):
			if is_instance_valid(collider) and not collider.is_queued_for_deletion():
				add_collision_exception_with(collider)
			velocity = pre_collision_vel
			continue

		if speed_length < 0.5: continue

		if collider is RigidBody3D:
			if collider.mass > 200.0: continue
			if collider.sleeping: collider.sleeping = false

			var push_dir = - col.get_normal();push_dir.y = 0.2;push_dir = push_dir.normalized()
			var hit_offset = col.get_position() - collider.global_position

			var is_elite_enemy = (get("is_elite") == true)
			var zombie_mass = 150.0 if is_elite_enemy else 80.0
			var mass_ratio = clamp(zombie_mass / collider.mass, 0.5, 10.0)

			var velocity_diff = pre_collision_vel.dot(push_dir) - collider.linear_velocity.dot(push_dir)
			if velocity_diff > 0:
				var push_force = velocity_diff * mass_ratio * 5.0
				push_force = clamp(push_force, 0.0, 120.0 if is_elite_enemy else 90.0)
				collider.apply_impulse(push_dir * push_force, hit_offset)

				velocity.x = pre_collision_vel.x * 0.8
				velocity.z = pre_collision_vel.z * 0.8

func spawn_coin_shower():
	if not coin_scene or not is_inside_tree(): return
	var amount = randi_range(1, 2)


	if Global.midas_touch_count > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < 4.0:
			amount *= 2

	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	var player = get_tree().get_first_node_in_group("player")
	var spawn_offset = Vector3.ZERO

	if player and global_position.distance_to(player.global_position) < 1.5:
		var dir_away = player.global_position.direction_to(global_position)
		dir_away.y = 0
		spawn_offset = dir_away.normalized() * 1.5

	for i in range(amount):
		var spawn_pos = global_position + spawn_offset + Vector3(randf_range(-0.3, 0.3), 1.5, randf_range(-0.3, 0.3))


		var coin = Global.spawn_from_pool("coins", coin_scene, spawn_pos, root)


		if not coin:
			coin = coin_scene.instantiate()
			root.add_child(coin)
			coin.global_position = spawn_pos

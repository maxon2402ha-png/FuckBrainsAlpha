extends CharacterBody3D

signal enemy_died

var max_health: float = 20.0
var current_health: float = 20.0
var speed: float = 4.5
var attack_damage: float = 4.0

var attack_range: float = 15.0
var attack_speed: float = 2.5
var shots_in_burst: int = 3
var burst_fire_rate: float = 0.15
var aim_time: float = 0.8

var flee_range: float = 5.0
var speed_multiplier: float = 1.0

var ideal_distance_min: float = 7.0
var ideal_distance_max: float = 12.0
var lose_los_timer: float = 0.0

const GRAVITY = 25.0
const JUMP_VELOCITY = 6.0

enum State{IDLE, CHASE, SEARCH, ATTACK, FLEE}
var current_state = State.IDLE

var target_node: Node3D = null
var last_known_position: Vector3 = Vector3.INF
var search_timer: float = 0.0


var path_update_timer: float = 0.0
const PATH_UPDATE_RATE: float = 0.2

var attack_cooldown: float = 0.0
var stun_timer: float = 0.0

var strafe_dir: Vector3 = Vector3.ZERO
var strafe_timer: float = 0.0

var stuck_timer: float = 0.0
var last_position: Vector3 = Vector3.ZERO
var pre_collision_vel: Vector3 = Vector3.ZERO
var dodge_dir: Vector3 = Vector3.ZERO

var is_charging_shot: bool = false
var charge_timer: float = 0.0
var current_burst_count: int = 0
var is_first_tick = true

var ragdoll_timer: float = 0.0


var flinch_rotation: Vector3 = Vector3.ZERO
var flinch_position: Vector3 = Vector3.ZERO

@onready var muzzle = find_child("Muzzle*", true, false)
@onready var anim_player = find_child("AnimationPlayer*", true, false)
var current_anim_name: String = ""

var visual_pivot: Node3D = null
var skeleton: Skeleton3D = null

var groan_sound = preload("res://Assets/Sound/groan.mp3")
var die_sound = preload("res://Assets/Sound/die.mp3")
var attack_sound = preload("res://Assets/Sound/attack.mp3")
var coin_scene = preload("res://Scenes/coin.tscn")
var blood_scene = preload("res://Scenes/blood_splatter.tscn")

var my_room = null
var is_friendly: bool = false
var base_mat_override = null
var is_lightbulb_target: bool = false
var is_leaving: bool = false
var is_dead = false
var is_bleeding = false
var groan_timer = 0.0

@onready var audio_player = $ZombieSound
@onready var nav_agent = $NavigationAgent3D


var visibility_enabler: VisibleOnScreenEnabler3D


var is_shishkin_projectile: bool = false
var shishkin_target: Node3D = null
var is_kamikaze: bool = false

func _ready():

	if Global.condoms_count > 0:
		if randf() < 0.4 and randf() < 0.3:
			queue_free()
			return

	var base_hp = 20.0
	var base_dmg = 4.0

	max_health = base_hp * Global.get_enemy_hp_multiplier()
	current_health = max_health
	attack_damage = base_dmg * Global.get_enemy_dmg_multiplier()


	if Global.kamikaze_chance > 0 and randf() < Global.kamikaze_chance:
		make_kamikaze()

	aim_time = randf_range(0.6, 1.4)
	attack_speed = randf_range(2.0, 3.0)

	groan_timer = randf_range(5.0, 15.0)
	path_update_timer = randf_range(0.0, PATH_UPDATE_RATE)

	collision_layer = 4
	collision_mask = 1

	if audio_player: audio_player.volume_db = -18.0

	if not nav_agent:
		nav_agent = NavigationAgent3D.new()
		add_child(nav_agent)

	if nav_agent:
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = attack_range - 2.0
		nav_agent.avoidance_enabled = false

	strafe_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	_apply_rim_lighting(self)

	var old_anim = find_child("AnimationPlayer*", true, false)
	if old_anim: old_anim.stop()

	visual_pivot = Node3D.new()
	visual_pivot.name = "VisualPivot"
	add_child(visual_pivot)

	var children_to_move = []
	for child in get_children():
		if child != visual_pivot and child != $CollisionShape3D and not child is NavigationAgent3D and not child is Timer and child.name != "ZombieSound" and not child is VisibleOnScreenEnabler3D:
			children_to_move.append(child)

	for child in children_to_move:
		remove_child(child)
		visual_pivot.add_child(child)

	skeleton = visual_pivot.find_child("Skeleton3D*", true, false)
	if not skeleton:
		skeleton = visual_pivot.find_child("GeneralSkeleton", true, false)

	if skeleton:
		skeleton.physical_bones_stop_simulation()
		var bones = skeleton.find_children("*", "PhysicalBone3D")
		for bone in bones:
			bone.collision_layer = 4
			bone.collision_mask = 0
			add_collision_exception_with(bone)
			for other_bone in bones:
				if bone != other_bone:
					bone.add_collision_exception_with(other_bone)
			for shape in bone.get_children():
				if shape is CollisionShape3D:
					shape.set_deferred("disabled", false)
					if shape.shape and shape.shape is CapsuleShape3D:
						var fat_shape = shape.shape.duplicate()
						fat_shape.radius *= 1.5
						shape.shape = fat_shape


	if not is_kamikaze: set_model_color(Color(1.0, 0.5, 0.0))

	_setup_visibility_optimization()
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
	if is_charging_shot: cancel_shot()

func apply_shishkin_launch(target: Node3D):
	if is_dead or not is_instance_valid(target): return
	is_shishkin_projectile = true
	shishkin_target = target
	collision_mask = 0
	set_model_color(Color.RED, true)
	spawn_custom_text("ЗАПУСК!", Color.RED)
	if is_charging_shot: cancel_shot()
	if audio_player:
		audio_player.stream = attack_sound
		audio_player.pitch_scale = 1.5
		audio_player.play()

func make_kamikaze():
	is_kamikaze = true
	make_friendly()
	set_model_color(Color(1.0, 0.2, 0.0), true)
	speed *= 2.0
	spawn_custom_text("СБОЙ ИМПЛАНТА", Color.RED)



func _setup_visibility_optimization():
	visibility_enabler = VisibleOnScreenEnabler3D.new()
	visibility_enabler.enable_mode = VisibleOnScreenEnabler3D.ENABLE_MODE_ALWAYS
	visibility_enabler.enable_node_path = self.get_path()
	add_child(visibility_enabler)

	var aabb = AABB(Vector3(-1.5, 0, -1.5), Vector3(3.0, 3.0, 3.0))
	visibility_enabler.aabb = aabb

func get_muzzle_pos() -> Vector3:
	if is_instance_valid(muzzle):
		return muzzle.global_position
	return global_position + Vector3(0, 1.3, 0)

func play_smart_anim(keywords: Array, anim_speed: float = 1.0):
	if not anim_player: return
	var anim_list = anim_player.get_animation_list()
	if anim_list.is_empty(): return

	if anim_player.is_playing() and ("shoot" in current_anim_name.to_lower() or "fire" in current_anim_name.to_lower() or "die" in current_anim_name.to_lower() or "death" in current_anim_name.to_lower()):
		var is_important = false
		for kw in keywords:
			if kw.to_lower() in ["shoot", "fire", "die", "death"]: is_important = true
		if not is_important: return

	var found = false
	for kw in keywords:
		for anim in anim_list:
			if kw.to_lower() in anim.to_lower():
				if current_anim_name != anim or not anim_player.is_playing():
					anim_player.play(anim, 0.15)
					current_anim_name = anim
				anim_player.speed_scale = anim_speed
				found = true
				return

	if not found:
		var fallback = anim_list[0]
		if current_anim_name != fallback or not anim_player.is_playing():
			anim_player.play(fallback, 0.2)
			current_anim_name = fallback
		anim_player.speed_scale = anim_speed

func _physics_process(delta):
	if is_dead or is_leaving or not is_inside_tree(): return

	if is_first_tick:
		global_position += Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		is_first_tick = false

	if global_position.y < -15.0:
		die()
		return

	if not is_on_floor() and not is_shishkin_projectile:
		velocity.y -= GRAVITY * delta


	if is_shishkin_projectile:
		if is_instance_valid(shishkin_target) and not shishkin_target.get("is_dead"):
			var dir = global_position.direction_to(shishkin_target.global_position)
			velocity = dir * 35.0
			var dist = global_position.distance_to(shishkin_target.global_position)

			if dist < 1.5:
				if shishkin_target.has_method("take_damage"): shishkin_target.take_damage(9999.0)
				die()
			_apply_safe_movement()
		else:
			die()
		return

	if ragdoll_timer > 0:
		ragdoll_timer -= delta
		if ragdoll_timer <= 0 and skeleton:
			skeleton.physical_bones_stop_simulation()

	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 15.0 * delta)

	if skeleton:
		flinch_rotation = flinch_rotation.lerp(Vector3.ZERO, 10.0 * delta)
		flinch_position = flinch_position.lerp(Vector3.ZERO, 10.0 * delta)
		skeleton.position = flinch_position
		skeleton.rotation = flinch_rotation


	if is_kamikaze and is_instance_valid(target_node):
		if global_position.distance_to(target_node.global_position) <= 2.0:
			take_damage(9999.0)
			return

		process_movement(delta, speed * speed_multiplier)
		anti_stuck_system(delta)
		_apply_safe_movement()
		return

	groan_timer -= delta
	if groan_timer <= 0:
		if randf() < 0.05 and audio_player and not audio_player.playing:
			audio_player.stream = groan_sound
			audio_player.pitch_scale = randf_range(0.9, 1.2)
			audio_player.play()
		groan_timer = randf_range(10.0, 20.0)

	if attack_cooldown > 0: attack_cooldown -= delta

	path_update_timer -= delta
	if path_update_timer <= 0.0:
		target_node = find_best_target()
		path_update_timer = PATH_UPDATE_RATE

		if target_node and check_line_of_sight(target_node):
			last_known_position = target_node.global_position
		if nav_agent and last_known_position != Vector3.INF:
			nav_agent.target_position = last_known_position

	var dist_to_target = INF
	var has_los = false

	if target_node:
		dist_to_target = global_position.distance_to(target_node.global_position)
		has_los = check_line_of_sight(target_node)

		if has_los:
			lose_los_timer = 0.0

			if current_state != State.ATTACK:
				if dist_to_target < flee_range: current_state = State.FLEE
				elif dist_to_target <= attack_range and attack_cooldown <= 0: current_state = State.ATTACK
				else: current_state = State.CHASE
		else:
			if current_state == State.ATTACK and is_charging_shot:
				lose_los_timer += delta
				if lose_los_timer > 0.4:
					is_charging_shot = false
					current_state = State.SEARCH
					search_timer = 4.0
			else:
				if current_state in [State.CHASE, State.ATTACK, State.FLEE]:
					current_state = State.SEARCH
					search_timer = 4.0
	elif last_known_position != Vector3.INF:
		current_state = State.SEARCH
	else:
		current_state = State.IDLE

	if current_state != State.ATTACK:
		is_charging_shot = false

	strafe_timer -= delta
	if strafe_timer <= 0:
		strafe_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
		strafe_timer = randf_range(1.0, 2.5)

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
			play_smart_anim(["idle", "stand"])

		State.FLEE:
			process_flee(delta, speed * speed_multiplier * 1.3)

		State.CHASE, State.SEARCH:
			process_movement(delta, speed * speed_multiplier)

			if current_state == State.SEARCH:
				search_timer -= delta
				if search_timer <= 0 or global_position.distance_to(last_known_position) < 2.0:
					last_known_position = Vector3.INF
					current_state = State.IDLE

		State.ATTACK:
			process_attack(delta)

	anti_stuck_system(delta)
	_apply_safe_movement()

func _apply_safe_movement():
	if is_nan(velocity.x) or is_nan(velocity.y) or is_nan(velocity.z):
		velocity = Vector3.ZERO

	velocity.x = clamp(velocity.x, -15.0, 15.0)
	velocity.y = clamp(velocity.y, -40.0, 15.0)
	velocity.z = clamp(velocity.z, -15.0, 15.0)

	pre_collision_vel = velocity
	move_and_slide()
	push_rigid_bodies()

func rotate_model_smoothly(target_dir: Vector3, delta: float, speed_factor: float = 10.0):
	if target_dir.length_squared() > 0.01 and visual_pivot:
		var target_angle = atan2( - target_dir.x, - target_dir.z) + PI
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_angle, speed_factor * delta)

func process_movement(delta, current_speed: float):
	var local_speed_mod = 1.0 if stun_timer <= 0 else 0.15

	if nav_agent and not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		if target_node and target_node.global_position.y < global_position.y - 1.0 and global_position.distance_to(target_node.global_position) < 15.0:
			next_pos = target_node.global_position
		var dir = global_position.direction_to(next_pos)
		dir.y = 0;dir = dir.normalized()

		if dodge_dir != Vector3.ZERO:
			dir = (dir + dodge_dir * 1.5).normalized()
			dodge_dir = dodge_dir.lerp(Vector3.ZERO, 3.0 * delta)

		var final_dir = (dir + strafe_dir * 0.4).normalized()
		final_dir = (final_dir + get_separation_force() * 1.5).normalized()

		velocity.x = lerp(velocity.x, final_dir.x * current_speed * local_speed_mod, 8.0 * delta)
		velocity.z = lerp(velocity.z, final_dir.z * current_speed * local_speed_mod, 8.0 * delta)
		rotate_model_smoothly(final_dir, delta)
		play_smart_anim(["run", "walk", "move"], speed_multiplier)
	else:
		velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
		play_smart_anim(["idle", "stand"])

func process_flee(delta, current_speed: float):
	if not is_instance_valid(target_node): return
	var local_speed_mod = 1.0 if stun_timer <= 0 else 0.15

	var dir_away = (global_position - target_node.global_position).normalized()
	dir_away.y = 0
	var space_state = get_world_3d().direct_space_state
	var back_ray = PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.5, 0), global_position + Vector3(0, 0.5, 0) + dir_away * 3.0)
	back_ray.exclude = [get_rid()]
	var hit = space_state.intersect_ray(back_ray)

	var final_dir = Vector3.ZERO
	if hit:
		var wall_normal = hit.normal
		wall_normal.y = 0
		var cross_dir = wall_normal.cross(Vector3.UP).normalized()
		if strafe_dir.dot(cross_dir) > 0: final_dir = cross_dir
		else: final_dir = - cross_dir
	else:
		final_dir = (dir_away + strafe_dir * 0.6).normalized()

	final_dir = (final_dir + get_separation_force() * 1.5).normalized()
	velocity.x = lerp(velocity.x, final_dir.x * current_speed * local_speed_mod, 8.0 * delta)
	velocity.z = lerp(velocity.z, final_dir.z * current_speed * local_speed_mod, 8.0 * delta)

	var dir_to_target = global_position.direction_to(target_node.global_position)
	dir_to_target.y = 0
	rotate_model_smoothly(dir_to_target.normalized(), delta, 12.0)
	play_smart_anim(["run", "walk", "move"], speed_multiplier * 1.3)

func process_attack(delta):
	if not is_instance_valid(target_node): return

	var dir_to_target = global_position.direction_to(target_node.global_position)
	dir_to_target.y = 0;dir_to_target = dir_to_target.normalized()
	var dist = global_position.distance_to(target_node.global_position)

	rotate_model_smoothly(dir_to_target, delta, 14.0)

	if is_charging_shot:
		var right_vector = dir_to_target.cross(Vector3.UP).normalized()
		var move_dir = Vector3.ZERO

		if dist < ideal_distance_min: move_dir = - dir_to_target + (right_vector * strafe_dir.x * 0.6)
		elif dist > ideal_distance_max: move_dir = dir_to_target + (right_vector * strafe_dir.x * 0.6)
		else: move_dir = right_vector * sign(strafe_dir.x)

		move_dir = move_dir.normalized()
		var combat_speed = speed * speed_multiplier * 0.55
		if stun_timer > 0: combat_speed *= 0.15

		velocity.x = lerp(velocity.x, move_dir.x * combat_speed, 5.0 * delta)
		velocity.z = lerp(velocity.z, move_dir.z * combat_speed, 5.0 * delta)

		charge_timer -= delta

		if Vector2(velocity.x, velocity.z).length() > 0.5:
			var local_vel = Vector3.ZERO
			if visual_pivot:
				local_vel = visual_pivot.global_transform.basis.inverse() * velocity

			if local_vel.x < -1.0: play_smart_anim(["strafe_right", "right", "walk"])
			elif local_vel.x > 1.0: play_smart_anim(["strafe_left", "left", "walk"])
			elif local_vel.z < -1.0: play_smart_anim(["walk_back", "backward", "walk"])
			else: play_smart_anim(["walk", "run"])
		else:
			play_smart_anim(["aim", "idle", "stand"])

		if charge_timer <= 0: fire_ranged_shot()
	else:
		velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 10.0 * delta)

		play_smart_anim(["idle", "stand"])

		if attack_cooldown <= 0:
			is_charging_shot = true
			if current_burst_count == 0:
				charge_timer = aim_time
			else:
				charge_timer = burst_fire_rate

func cancel_shot():
	is_charging_shot = false

func fire_ranged_shot():
	is_charging_shot = false

	if is_dead or not is_inside_tree() or not is_instance_valid(target_node): return

	play_smart_anim(["shoot", "fire", "attack"])

	if audio_player and is_inside_tree():
		audio_player.stop();audio_player.pitch_scale = randf_range(1.2, 1.5)
		audio_player.stream = attack_sound;audio_player.volume_db = -10.0;audio_player.play()

	var final_dmg = attack_damage
	if is_in_group("boss"): final_dmg *= (1.0 + (0.5 * Global.panties_count))
	elif Global.panties_count > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) <= 8.0:
			final_dmg *= pow(0.7, Global.panties_count)

	var start_pos = get_muzzle_pos()
	var raw_target_pos = target_node.global_position + Vector3(0, 1.0, 0)

	if target_node.get("velocity") != null:
		var p_vel = target_node.velocity;p_vel.y = 0
		var predict_offset = p_vel * 0.15
		if predict_offset.length() > 1.5: predict_offset = predict_offset.normalized() * 1.5
		raw_target_pos += predict_offset

	var aim_dir = start_pos.direction_to(raw_target_pos)

	var spread_angle = 0.0075
	var right = aim_dir.cross(Vector3.UP).normalized()
	var up = right.cross(aim_dir).normalized()
	var radius = sqrt(randf()) * spread_angle
	var angle = randf() * TAU
	var offset_x = cos(angle) * radius; var offset_y = sin(angle) * radius
	var final_aim_dir = (aim_dir + right * offset_x + up * offset_y).normalized()

	var target_pos = start_pos + final_aim_dir * attack_range
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start_pos, target_pos)
	query.exclude = [self.get_rid()]
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	var end_pos = target_pos

	if result:
		end_pos = result.position
		var target = result.collider
		var hit_bone = null

		if target is PhysicalBone3D:
			hit_bone = target
			target = target.owner

		if target and target.has_method("take_damage"):
			if target.is_in_group("player"):

				target.take_damage(final_dmg, "Laser", self)
			else:
				target.take_damage(final_dmg, false, result.position, final_aim_dir)
				if hit_bone and target.get("skeleton"):
					target.skeleton.physical_bones_start_simulation([hit_bone.name])
					hit_bone.apply_impulse(final_aim_dir * 15.0, result.position - hit_bone.global_position)
					target.set("ragdoll_timer", 0.3)

	draw_tracer(start_pos, end_pos)

	current_burst_count += 1
	if current_burst_count >= shots_in_burst:
		current_burst_count = 0
		attack_cooldown = attack_speed + randf_range(-0.2, 0.2)
	else:
		attack_cooldown = burst_fire_rate

func draw_tracer(start_pos: Vector3, end_pos: Vector3):
	if not is_inside_tree(): return
	var dist = start_pos.distance_to(end_pos)
	if dist < 0.5: return

	var mesh_inst = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.04;mesh.bottom_radius = 0.04;mesh.height = dist
	mesh_inst.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0);mat.emission_enabled = true;mat.emission = Color(1.0, 0.4, 0.0)
	mat.emission_energy_multiplier = 5.0;mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.surface_set_material(0, mat)
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	root.add_child(mesh_inst)

	mesh_inst.global_position = start_pos.lerp(end_pos, 0.5)
	var dir = start_pos.direction_to(end_pos)
	var up_vec = Vector3.UP
	if abs(dir.y) > 0.99: up_vec = Vector3.RIGHT
	mesh_inst.look_at(end_pos, up_vec)
	mesh_inst.basis = mesh_inst.basis * Basis(Vector3.RIGHT, PI / 2.0)

	var tween = get_tree().create_tween()
	if tween:
		tween.set_parallel(true)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.15)
		tween.tween_property(mesh_inst, "scale", Vector3(0.0, 1.0, 0.0), 0.15)
		tween.chain().tween_callback(mesh_inst.queue_free)
	else:
		mesh_inst.queue_free()

func check_line_of_sight(target: Node3D) -> bool:
	if not is_instance_valid(target): return false
	var space_state = get_world_3d().direct_space_state
	var start = get_muzzle_pos()
	var end = target.global_position + Vector3(0, 1.0, 0)
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)
	if result: return result.collider == target
	return true

func anti_stuck_system(delta):
	var dist_moved = Vector2(global_position.x, global_position.z).distance_to(Vector2(last_position.x, last_position.z))
	var is_trying_to_move = current_state in [State.CHASE, State.SEARCH, State.FLEE]

	if is_trying_to_move and dist_moved < 0.02 * (delta * 60.0):
		stuck_timer += delta
		if stuck_timer > 0.2:
			var space_state = get_world_3d().direct_space_state
			var forward = - global_transform.basis.z.normalized()
			var start = global_position + Vector3(0, 0.5, 0)

			var left_ray = PhysicsRayQueryParameters3D.create(start, start + (forward - global_transform.basis.x).normalized() * 2.0)
			var right_ray = PhysicsRayQueryParameters3D.create(start, start + (forward + global_transform.basis.x).normalized() * 2.0)
			left_ray.exclude = [get_rid()];right_ray.exclude = [get_rid()]

			var hit_left = space_state.intersect_ray(left_ray)
			var hit_right = space_state.intersect_ray(right_ray)

			if hit_left and not hit_right: dodge_dir = global_transform.basis.x.normalized()
			elif hit_right and not hit_left: dodge_dir = - global_transform.basis.x.normalized()
			else: dodge_dir = (global_transform.basis.x * (1 if randf() > 0.5 else -1)).normalized()

		if stuck_timer > 0.8 and is_on_floor():
			velocity.y = JUMP_VELOCITY
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	last_position = global_position

func get_separation_force() -> Vector3:
	var force = Vector3.ZERO
	var neighbor_count = 0
	var avoid_radius = 1.5

	var space_state = get_world_3d().direct_space_state
	var sphere = SphereShape3D.new()
	sphere.radius = avoid_radius
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere;query.transform = global_transform;query.exclude = [self.get_rid()]

	var results = space_state.intersect_shape(query, 4)
	for res in results:
		if res.collider is CharacterBody3D and res.collider.is_in_group("enemies"):
			var push_dir = res.collider.global_position.direction_to(global_position)
			push_dir.y = 0
			var dist = global_position.distance_to(res.collider.global_position)
			if dist < 0.1: dist = 0.1
			force += push_dir * (avoid_radius / dist)
			neighbor_count += 1

	if neighbor_count > 0: force = force / neighbor_count
	return force

func find_best_target() -> Node3D:
	var best_target = null; var best_score = INF


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
			best_score = global_position.distance_to(player.global_position);best_target = player
		var friendlies = get_tree().get_nodes_in_group("friendlies")
		for f in friendlies:
			if is_instance_valid(f) and not f.get("is_dead") and not f.get("is_leaving"):
				var d = global_position.distance_to(f.global_position)
				var score = d + 15.0
				if score < best_score: best_score = score;best_target = f
	return best_target

func spawn_retro_blood(hit_pos: Vector3, hit_dir: Vector3):
	if not blood_scene or not is_inside_tree(): return
	var blood = blood_scene.instantiate()
	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	root.add_child(blood)
	blood.global_position = hit_pos if hit_pos != Vector3.ZERO else global_position + Vector3(0, 1.0, 0)
	if hit_dir != Vector3.ZERO and hit_dir.length_squared() > 0.01:
		var look_target = blood.global_position + hit_dir
		if abs(hit_dir.y) < 0.99: blood.look_at(look_target, Vector3.UP)
		else: blood.look_at(look_target, Vector3.RIGHT)

func take_damage(amount: float, is_crit = false, hit_pos = Vector3.ZERO, _hit_dir = Vector3.ZERO, hit_bone = null) -> bool:
	if is_dead or not is_inside_tree() or is_leaving: return false

	var is_headshot = false
	if hit_pos != Vector3.ZERO and has_node("HeadTarget"):
		var head_pos = $HeadTarget.global_position
		if hit_pos.distance_to(head_pos) <= 0.45 * scale.y:
			is_headshot = true
			amount *= 2.0
			is_crit = true

	var final_is_crit = false
	if typeof(is_crit) == TYPE_BOOL: final_is_crit = is_crit
	current_health -= amount


	Global.spawn_damage_number(int(amount), global_position + Vector3(0, 1.5, 0), final_is_crit)
	flash_red()

	if _hit_dir != Vector3.ZERO:
		spawn_retro_blood(hit_pos, _hit_dir)
	else:
		spawn_retro_blood(global_position + Vector3(0, 1.0, 0), Vector3.UP)

	if _hit_dir != Vector3.ZERO:
		var push_force = 5.0 if final_is_crit else 3.0
		velocity += _hit_dir * push_force

		stun_timer = max(stun_timer, 0.4)
		if is_charging_shot: cancel_shot()

		if visual_pivot:
			var local_dir = visual_pivot.global_transform.basis.inverse() * _hit_dir
			flinch_rotation = Vector3(local_dir.z, 0, - local_dir.x) * (0.6 if final_is_crit else 0.3)
			flinch_position = local_dir * (0.4 if final_is_crit else 0.15)

		if hit_bone and hit_bone is PhysicalBone3D and skeleton:
			skeleton.physical_bones_start_simulation([hit_bone.name])
			var bone_push = 25.0 if final_is_crit else 15.0
			hit_bone.apply_impulse(_hit_dir * bone_push, hit_pos - hit_bone.global_position)
			ragdoll_timer = 0.3

	if current_health <= 0: die()
	return is_headshot

func flash_red():
	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if not model_node: return
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color.RED;red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var meshes = []
	if model_node is MeshInstance3D: meshes.append(model_node)
	else:
		for child in model_node.get_children():
			if child is MeshInstance3D: meshes.append(child)
	for mesh in meshes: mesh.material_override = red_mat
	var tree = get_tree()
	if tree: await tree.create_timer(0.1).timeout
	if is_instance_valid(self) and not is_dead:
		for mesh in meshes: mesh.material_override = base_mat_override

func die(_impact_dir = Vector3.ZERO):
	if is_dead: return
	is_dead = true

	if has_method("cancel_shot"): cancel_shot()

	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)


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

	spawn_retro_blood(global_position + Vector3(0, 1.0, 0), Vector3.UP)

	if skeleton:
		skeleton.physical_bones_stop_simulation()

	var main_col = get_node_or_null("CollisionShape3D")
	if main_col:
		main_col.set_deferred("disabled", true)

	if anim_player: anim_player.stop()

	remove_from_group("enemies")
	enemy_died.emit()

	var root = get_tree().current_scene if get_tree().current_scene else get_parent()
	if not is_friendly:
		var base_score = 15


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
		temp_sound.stream = die_sound
		temp_sound.unit_size = 10.0
		temp_sound.volume_db = -5.0
		temp_sound.pitch_scale = randf_range(1.5, 2.0)
		root.add_child(temp_sound)
		temp_sound.global_position = global_position
		temp_sound.play()
		temp_sound.finished.connect(temp_sound.queue_free)


	if visual_pivot:
		var base_scale = visual_pivot.scale
		var shape_tween = create_tween()
		var spin_tween = create_tween()

		spin_tween.set_loops(2)
		spin_tween.tween_property(visual_pivot, "rotation", visual_pivot.rotation + Vector3(TAU, TAU, 0), 0.25)

		shape_tween.tween_property(visual_pivot, "scale", Vector3(base_scale.x * 2.5, base_scale.y * 0.1, base_scale.z * 2.5), 0.15).set_trans(Tween.TRANS_SINE)
		shape_tween.tween_property(visual_pivot, "scale", Vector3(base_scale.x * 0.1, base_scale.y * 3.5, base_scale.z * 0.1), 0.15).set_trans(Tween.TRANS_EXPO)
		shape_tween.tween_property(visual_pivot, "scale", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)

		shape_tween.finished.connect(queue_free)
	else:
		call_deferred("queue_free")


func set_model_color(color: Color, emission: bool = false):
	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if not model_node: return
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color;mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if emission:
		mat.emission_enabled = true;mat.emission = color;mat.emission_energy_multiplier = 2.0
	mat.rim_enabled = true;mat.rim = 0.6;mat.rim_tint = 0.8
	base_mat_override = mat
	var meshes = []
	if model_node is MeshInstance3D: meshes.append(model_node)
	else:
		for child in model_node.get_children():
			if child is MeshInstance3D: meshes.append(child)
	for mesh in meshes: mesh.material_override = mat

func _apply_rim_lighting(node: Node):
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if not mat and node.mesh: mat = node.mesh.surface_get_material(0)
		if mat and mat is StandardMaterial3D:
			var unique_mat = mat.duplicate()
			unique_mat.rim_enabled = true;unique_mat.rim = 0.6;unique_mat.rim_tint = 0.8
			node.set_surface_override_material(0, unique_mat)
	for child in node.get_children(): _apply_rim_lighting(child)

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
		if collider.is_in_group("items") or "item" in collider.name.to_lower() or "coin" in collider.name.to_lower():
			add_collision_exception_with(collider);velocity = pre_collision_vel;continue
		if speed_length < 0.5: continue
		if collider is RigidBody3D:
			if collider.mass > 200.0: continue
			if collider.sleeping: collider.sleeping = false
			var push_dir = - col.get_normal();push_dir.y = 0.2;push_dir = push_dir.normalized()
			var hit_offset = col.get_position() - collider.global_position
			var zombie_mass = 80.0
			var mass_ratio = clamp(zombie_mass / collider.mass, 0.5, 10.0)
			var velocity_diff = pre_collision_vel.dot(push_dir) - collider.linear_velocity.dot(push_dir)
			if velocity_diff > 0:
				var push_force = velocity_diff * mass_ratio * 3.0
				push_force = clamp(push_force, 0.0, 90.0)
				collider.apply_impulse(push_dir * push_force, hit_offset)
				velocity.x = pre_collision_vel.x * 0.8;velocity.z = pre_collision_vel.z * 0.8

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

func make_friendly():
	is_friendly = true
	remove_from_group("enemies");add_to_group("friendlies")
	max_health *= 2.0;current_health = max_health;attack_damage *= 1.5
	set_model_color(Color(0.2, 1.0, 0.2))

func apply_slow(factor: float): speed_multiplier = factor
func remove_slow(): speed_multiplier = 1.0

func set_stats(hp_multiplier: float, dmg_multiplier: float):
	max_health *= hp_multiplier;current_health = max_health;attack_damage *= dmg_multiplier

func investigate_sound(sound_pos: Vector3):
	if is_dead or current_state in [State.ATTACK, State.FLEE]: return
	last_known_position = sound_pos;current_state = State.SEARCH;search_timer = 4.0

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
	var lightbulb_light = OmniLight3D.new()
	lightbulb_light.light_color = Color(1.0, 1.0, 0.2)
	lightbulb_light.light_energy = 4.0;lightbulb_light.omni_range = 5.0
	add_child(lightbulb_light)
	lightbulb_light.position = Vector3(0, 2.5, 0)
	set_model_color(Color(1.0, 1.0, 0.2), true)

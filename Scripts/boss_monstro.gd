extends CharacterBody3D

signal enemy_died


var max_health: float = 180.0
var current_health: float = 180.0

enum State{IDLE, HOPPING, PREP_PUKE, PUKING, PREP_LEAP, IN_AIR, STAGE_TRANSITION, PREP_DASH, DASH, BULLET_HELL}
var current_state = State.IDLE

var state_timer: float = 0.0
var hop_timer: float = 0.0
var gravity: float = 25.0
var stun_timer: float = 0.0

var projectile_scene = preload("res://Scenes/boss_projectile.tscn")
var die_sound = preload("res://Assets/Sound/die.mp3")
var attack_sound = preload("res://Assets/Sound/attack.mp3")
var coin_scene = preload("res://Scenes/coin.tscn")
var blood_scene = preload("res://Scenes/blood_splatter.tscn")

var is_dead = false
var target_player = null
var my_room = null

var boss_scale: float = 3.0
var current_stage: int = 1
var is_invulnerable: bool = false

var dash_dir: Vector3 = Vector3.ZERO
var dash_chain: int = 0
var bh_tick: float = 0.0
var spiral_angle: float = 0.0

var is_lightbulb_target: bool = false
var lightbulb_light: OmniLight3D = null
var is_bleeding: bool = false

@onready var nav_agent = get_node_or_null("NavigationAgent3D")
@onready var audio = $BossSound
@onready var anim_player = find_child("AnimationPlayer", true, false)

var anim_idle = "Blood master anim|Armature|mixamo_com|Layer0"
var anim_walk = "Blood master anim|Armature|mixamo_com|Layer0"
var anim_attack = "Blood master anim|Armature|mixamo_com|Layer0_002"
var anim_jump = "Blood master anim|Armature|mixamo_com|Layer0_002"
var anim_death = "stop"

var speed_multiplier: float = 1.0

var base_col_radius = 0.0
var base_col_height = 0.0
var base_col_pos = Vector3.ZERO

func _ready():
	add_to_group("boss")
	add_to_group("enemies")
	current_health = max_health
	state_timer = 2.0
	play_anim(anim_idle)

	if nav_agent:
		nav_agent.path_desired_distance = 2.0
		nav_agent.target_desired_distance = 4.0

	_apply_rim_lighting(self, 0.5, 0.3)

	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		base_col_radius = col.shape.radius
		base_col_height = col.shape.height
		base_col_pos = col.position

	apply_scale_safely()





func apply_slow(factor: float):
	if current_stage > 1: speed_multiplier = max(0.8, factor)
	else: speed_multiplier = factor

func remove_slow():
	if current_stage == 3: speed_multiplier = 0.8
	elif current_stage == 2: speed_multiplier = 1.8
	else: speed_multiplier = 1.0

func make_friendly(): pass
func apply_shishkin_launch(_target): pass
func investigate_sound(_pos: Vector3): pass

func make_lightbulb_target():
	is_lightbulb_target = true
	lightbulb_light = OmniLight3D.new()
	lightbulb_light.light_color = Color(1.0, 1.0, 0.2)
	lightbulb_light.light_energy = 8.0
	lightbulb_light.omni_range = 10.0
	add_child(lightbulb_light)
	lightbulb_light.position = Vector3(0, 3.5, 0)

	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if model_node:
		var glow_mat = StandardMaterial3D.new()
		glow_mat.albedo_color = Color(1.0, 1.0, 0.2, 0.3)
		glow_mat.emission_enabled = true
		glow_mat.emission = Color(1.0, 1.0, 0.0)
		glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		var meshes = []
		if model_node is MeshInstance3D: meshes.append(model_node)
		else:
			for child in model_node.get_children():
				if child is MeshInstance3D: meshes.append(child)
		for mesh in meshes: mesh.material_overlay = glow_mat

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





func ignore_character_collisions():
	if not is_inside_tree() or is_dead: return
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and p is CollisionObject3D: add_collision_exception_with(p)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e != self and is_instance_valid(e) and e is CollisionObject3D: add_collision_exception_with(e)

func apply_scale_safely():
	for child in get_children():
		if child is Node3D and not child is CollisionShape3D:
			child.scale = Vector3(boss_scale, boss_scale, boss_scale)

	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D and base_col_radius > 0:
		var new_shape = col.shape.duplicate()
		new_shape.radius = base_col_radius * boss_scale
		new_shape.height = base_col_height * boss_scale
		col.shape = new_shape
		col.position = base_col_pos * boss_scale

func play_anim(keyword: String, anim_speed: float = 1.0):
	if not anim_player: return
	if keyword == "stop":
		anim_player.stop()
		return
	if anim_player.has_animation(keyword):
		anim_player.play(keyword, -1, anim_speed)
		return
	for anim_name in anim_player.get_animation_list():
		if keyword.to_lower() in anim_name.to_lower():
			anim_player.play(anim_name, -1, anim_speed)
			return

func set_stats(hp_multiplier: float, _dmg_multiplier: float):
	max_health = 180.0 * hp_multiplier
	current_health = max_health

func heal(amount: float):
	current_health = min(current_health + amount, max_health)

func _physics_process(delta):
	if is_dead or not is_inside_tree() or not is_instance_valid(self): return

	ignore_character_collisions()

	if not is_on_floor():
		if current_state == State.IN_AIR: gravity = 40.0
		else: gravity = 25.0
		velocity.y -= gravity * delta

	if stun_timer > 0:
		stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 20.0 * delta)
		move_and_slide()
		return

	target_player = get_tree().get_first_node_in_group("player")

	if not is_instance_valid(target_player) or not target_player.is_inside_tree():
		if is_inside_tree(): move_and_slide()
		return

	if current_stage == 3 and Engine.get_physics_frames() % 60 == 0:
		current_health -= 1.5
		if current_health <= 0:
			die()
			return

	match current_state:
		State.IDLE:
			velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
			state_timer -= delta
			if state_timer <= 0: choose_next_attack()

		State.HOPPING:
			process_hopping(delta)
			state_timer -= delta * speed_multiplier
			if state_timer <= 0: choose_next_attack()

		State.PREP_PUKE:
			velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
			look_at_player(delta * 5.0)
			state_timer -= delta * speed_multiplier
			if state_timer <= 0:
				current_state = State.PUKING
				fire_puke()

		State.PREP_DASH:
			velocity.x = lerp(velocity.x, 0.0, 15.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 15.0 * delta)


			if state_timer > 0.3:
				look_at_player(delta * 12.0)
				var p_vel = target_player.get("velocity") if target_player.get("velocity") != null else Vector3.ZERO
				p_vel.y = 0
				var aim_pos = target_player.global_position + (p_vel * 0.3)
				dash_dir = global_position.direction_to(aim_pos).normalized()
				dash_dir.y = 0

			state_timer -= delta * speed_multiplier
			if state_timer <= 0:
				current_state = State.DASH
				state_timer = 0.55

				play_anim(anim_jump, 2.5)
				if audio:
					audio.stream = attack_sound
					audio.pitch_scale = randf_range(1.2, 1.5)
					audio.play()

		State.DASH:

			velocity.x = dash_dir.x * 15.0 * speed_multiplier
			velocity.z = dash_dir.z * 15.0 * speed_multiplier

			if global_position.distance_to(target_player.global_position) < 3.5:
				if target_player.has_method("take_damage"):

					var dash_dmg = 4.0 * (1.0 + (0.5 * Global.panties_count))
					target_player.take_damage(dash_dmg, "Boss Dash")
					if target_player.has_method("add_camera_trauma"): target_player.add_camera_trauma(0.6)
					heal(15.0)
					spawn_custom_text("+15 HP", Color.GREEN)
					dash_chain = 3

			state_timer -= delta
			if state_timer <= 0 or is_on_wall():
				velocity.x = 0;velocity.z = 0
				dash_chain += 1
				if dash_chain < 3:
					current_state = State.PREP_DASH
					state_timer = 0.6
				else:
					current_state = State.IDLE
					state_timer = 2.0

		State.BULLET_HELL:
			velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
			bh_tick -= delta
			state_timer -= delta

			if bh_tick <= 0:
				fire_360_ring()
				bh_tick = 0.35

			if state_timer <= 0:
				current_state = State.IDLE
				state_timer = 1.0

		State.PREP_LEAP:
			velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
			look_at_player(delta * 8.0)
			state_timer -= delta * speed_multiplier
			if state_timer <= 0:
				current_state = State.IN_AIR
				velocity.y = 15.0 + (current_stage * 3.0)
				play_anim(anim_jump, 1.5 * speed_multiplier)

				var target_pos = target_player.global_position
				target_pos.y = global_position.y
				var dir = global_position.direction_to(target_pos)
				var dist = global_position.distance_to(target_pos)

				var jump_force = clamp(dist * (0.3 + (current_stage * 0.05)), 2.0, 15.0) * speed_multiplier
				velocity.x = dir.x * jump_force
				velocity.z = dir.z * jump_force

		State.IN_AIR:
			if velocity.y > 0:
				var target_pos = target_player.global_position
				target_pos.y = global_position.y
				var dir = global_position.direction_to(target_pos)
				var air_control = 3.0 + current_stage
				velocity.x = lerp(velocity.x, dir.x * air_control * speed_multiplier, 2.0 * delta)
				velocity.z = lerp(velocity.z, dir.z * air_control * speed_multiplier, 2.0 * delta)

			if is_on_floor() and velocity.y <= 0:
				trigger_slam_shockwave()
				play_anim(anim_idle)
				current_state = State.IDLE
				state_timer = randf_range(1.0, 1.8) / speed_multiplier

		State.STAGE_TRANSITION:
			velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
			state_timer -= delta
			if state_timer <= 0:
				is_invulnerable = false
				current_state = State.IDLE
				state_timer = 0.5

	var max_spd = 5.0 + (current_stage * 2.5)

	if current_state != State.DASH:
		velocity.x = clamp(velocity.x, - max_spd, max_spd)
		velocity.z = clamp(velocity.z, - max_spd, max_spd)

	velocity.y = clamp(velocity.y, -40.0, 30.0)

	if not is_inside_tree(): return
	move_and_slide()

	if is_on_wall(): velocity.x = 0;velocity.z = 0
	if is_on_ceiling() and velocity.y > 0: velocity.y = -5.0

	push_rigid_bodies()

func _apply_rim_lighting(node: Node, rim_amount: float, rim_tint: float):
	if node is MeshInstance3D:
		var mat = node.get_active_material(0)
		if not mat and node.mesh:
			mat = node.mesh.surface_get_material(0)

		if mat and mat is StandardMaterial3D:
			var unique_mat = mat.duplicate()
			unique_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			unique_mat.rim_enabled = true
			unique_mat.rim = rim_amount
			unique_mat.rim_tint = rim_tint
			node.set_surface_override_material(0, unique_mat)

	for child in node.get_children():
		_apply_rim_lighting(child, rim_amount, rim_tint)


func check_stage_transition():
	if current_stage == 1 and current_health <= max_health * 0.66:
		enter_stage(2)
	elif current_stage == 2 and current_health <= max_health * 0.33:
		enter_stage(3)

func enter_stage(stage: int):
	current_stage = stage
	current_state = State.STAGE_TRANSITION
	state_timer = 2.5
	is_invulnerable = true

	play_anim(anim_attack, 0.5)

	if audio:
		audio.stream = attack_sound
		audio.pitch_scale = 0.6 if stage == 2 else 0.3
		audio.volume_db = 5.0
		audio.play()

	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if model_node:
		var effect_mat = StandardMaterial3D.new()
		effect_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		effect_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		if stage == 2:
			boss_scale = 1.8
			speed_multiplier = 1.8
			effect_mat.albedo_color = Color(0.05, 0.05, 0.05, 0.95)
			effect_mat.rim_enabled = true
			effect_mat.rim = 1.0
			effect_mat.rim_tint = 1.0
			spawn_custom_text("ФАЗА 2: ТЕНЕВОЙ ОХОТНИК", Color(1.0, 0.0, 0.0))
		elif stage == 3:
			boss_scale = 4.5
			speed_multiplier = 0.8
			effect_mat.albedo_color = Color(1.0, 0.2, 0.0, 0.4)
			effect_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			spawn_custom_text("ФАЗА 3: ЖИВАЯ БОМБА", Color(1.0, 0.5, 0.0))

		var meshes = []
		if model_node is MeshInstance3D: meshes.append(model_node)
		else:
			for child in model_node.get_children():
				if child is MeshInstance3D: meshes.append(child)
		for mesh in meshes: mesh.material_overlay = effect_mat

	apply_scale_safely()
	spawn_stage_change_fx()

func process_hopping(delta):
	if not is_inside_tree(): return
	hop_timer -= delta * speed_multiplier
	look_at_player(delta * 5.0)

	if is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

		if hop_timer <= 0:
			velocity.y = 4.0 + current_stage
			var dir = - global_transform.basis.z.normalized()

			if nav_agent and is_instance_valid(target_player):
				nav_agent.target_position = target_player.global_position
				if not nav_agent.is_navigation_finished():
					var next_pos = nav_agent.get_next_path_position()
					dir = global_position.direction_to(next_pos)
					dir.y = 0;dir = dir.normalized()

			var hop_speed = 3.0 * speed_multiplier
			velocity.x = dir.x * hop_speed
			velocity.z = dir.z * hop_speed

			hop_timer = 1.0 / speed_multiplier
			play_anim(anim_walk, 1.5 * speed_multiplier)


func choose_next_attack():
	if not is_instance_valid(target_player): return

	if current_stage == 1:
		if randf() < 0.75:
			current_state = State.PREP_PUKE
			state_timer = 0.7
		else:
			current_state = State.PREP_LEAP
			state_timer = 0.5

	elif current_stage == 2:
		if randf() < 0.7:
			dash_chain = 0
			current_state = State.PREP_DASH
			state_timer = 0.6
		else:
			current_state = State.PREP_LEAP
			state_timer = 0.4

	elif current_stage == 3:
		if randf() < 0.6:
			current_state = State.BULLET_HELL
			state_timer = 4.0
			bh_tick = 0.0
			spiral_angle = 0.0
			play_anim(anim_attack, 2.0)
		else:
			current_state = State.PREP_LEAP
			state_timer = 0.3

	if current_state not in [State.BULLET_HELL]:
		play_anim(anim_idle, speed_multiplier)

func fire_puke():
	if not projectile_scene or not is_inside_tree(): return
	var parent = get_parent()
	if not parent: return

	if audio:
		audio.stream = attack_sound
		audio.pitch_scale = 0.8
		audio.play()

	var pellets = 10

	var p_vel = target_player.get("velocity") if target_player.get("velocity") != null else Vector3.ZERO
	p_vel.y = 0
	var aim_pos = target_player.global_position + (p_vel * 0.4)

	aim_pos.y = target_player.global_position.y + 0.8

	var spawn_pos = global_position + Vector3(0, 1.0, 0) + (global_position.direction_to(aim_pos) * 1.5)
	var base_dir = spawn_pos.direction_to(aim_pos).normalized()

	for i in range(pellets):
		var proj = projectile_scene.instantiate()
		parent.add_child(proj)

		proj.global_position = spawn_pos

		var spread_x = randf_range(-0.3, 0.3)
		var spread_y = randf_range(-0.1, 0.1)
		var spread_z = randf_range(-0.3, 0.3)
		var shoot_dir = (base_dir + Vector3(spread_x, spread_y, spread_z)).normalized()

		var shoot_speed = randf_range(18.0, 25.0)
		proj.velocity = shoot_dir * shoot_speed


	current_state = State.HOPPING
	state_timer = 1.5
	hop_timer = 0.2
	play_anim(anim_idle)

func fire_360_ring():
	if not projectile_scene or not is_inside_tree(): return
	var parent = get_parent()
	if not parent: return

	if audio:
		audio.stream = attack_sound
		audio.pitch_scale = 0.4
		audio.play()

	var pellets = 20
	spiral_angle += 0.2

	for i in range(pellets):
		var proj = projectile_scene.instantiate()
		parent.add_child(proj)

		proj.global_position = global_position + Vector3(0, 1.0, 0)

		var angle = (float(i) / pellets) * TAU + spiral_angle
		var shoot_dir = Vector3(cos(angle), 0.0, sin(angle)).normalized()
		var shoot_speed = 12.0
		proj.velocity = shoot_dir * shoot_speed

func trigger_slam_shockwave():
	if is_dead or not is_inside_tree(): return
	var world = get_world_3d()
	if not world: return

	var slam_radius = 5.0 + (current_stage * 1.5)

	var base_slam_dmg = 10.0 + (current_stage * 4.0)
	var slam_damage = base_slam_dmg * (1.0 + (0.5 * Global.panties_count))

	var parent = get_parent()
	if not parent: return

	if is_instance_valid(target_player) and target_player.is_inside_tree():
		if global_position.distance_to(target_player.global_position) <= slam_radius:
			if target_player.has_method("take_damage"):
				target_player.take_damage(slam_damage, "Boss Slam")
				if target_player.has_method("add_camera_trauma"): target_player.add_camera_trauma(1.0)

	var space_state = world.direct_space_state
	if space_state:
		var query = PhysicsShapeQueryParameters3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = slam_radius
		query.shape = sphere
		query.transform = global_transform
		query.exclude = [self.get_rid()]

		var results = space_state.intersect_shape(query)

		for res in results:
			if res.collider is RigidBody3D:
				var col = res.collider
				if col.sleeping: col.sleeping = false
				var push_dir = (col.global_position - global_position).normalized()
				push_dir.y = 0.8
				col.apply_central_impulse(push_dir * 50.0)

	var expl_node = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = slam_radius
	mesh.bottom_radius = slam_radius
	mesh.height = 0.5
	expl_node.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if current_stage == 3: mat.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	elif current_stage == 2: mat.albedo_color = Color(0.05, 0.05, 0.05, 0.8)
	else: mat.albedo_color = Color(0.8, 0.2, 0.0, 0.5)

	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 0.0) if current_stage > 1 else mat.albedo_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.surface_set_material(0, mat)

	parent.add_child(expl_node)
	expl_node.global_position = global_position + Vector3(0, 0.2, 0)

	var tween = expl_node.create_tween()
	if tween:
		tween.set_parallel(true)
		expl_node.scale = Vector3(0.1, 1, 0.1)
		tween.tween_property(expl_node, "scale", Vector3(1, 1, 1), 0.4).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.4)
		tween.chain().tween_callback(expl_node.queue_free)

func spawn_stage_change_fx():
	var shockwave = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = 1.8;mesh.outer_radius = 2.0
	mesh.rings = 12;mesh.ring_segments = 4
	shockwave.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.0, 0.0, 0.0) if current_stage == 2 else Color(1.0, 0.0, 0.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shockwave.material_override = mat

	get_parent().add_child(shockwave)
	shockwave.global_position = global_position + Vector3(0, 0.2, 0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(shockwave, "scale", Vector3(8.0, 1.0, 8.0), 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.6)
	tween.chain().tween_callback(shockwave.queue_free)

func look_at_player(speed_factor):
	if is_instance_valid(target_player) and target_player.is_inside_tree() and is_inside_tree():
		var dir_to_target = global_position.direction_to(target_player.global_position)
		if dir_to_target.length_squared() > 0.01:
			var target_angle = atan2( - dir_to_target.x, - dir_to_target.z)
			rotation.y = lerp_angle(rotation.y, target_angle, speed_factor)

func take_damage(amount, is_crit = false, hit_pos = Vector3.ZERO, _impact_dir = Vector3.ZERO) -> bool:
	if is_dead or not is_inside_tree(): return false
	if is_invulnerable: return false

	if hit_pos != Vector3.ZERO and blood_scene:
		var blood = blood_scene.instantiate()
		var p = get_parent()
		if p:
			p.add_child(blood)
			blood.global_position = hit_pos
			blood.scale = Vector3(2.5, 2.5, 2.5)

	var final_is_crit = false
	if typeof(is_crit) == TYPE_BOOL: final_is_crit = is_crit
	current_health -= amount


	Global.spawn_damage_number(int(amount), global_position + Vector3(0, 6.0, 0), final_is_crit)
	flash_red()

	check_stage_transition()

	if current_health <= 0: die()
	return false

func flash_red():
	var model_node = $MeshInstance3D if has_node("MeshInstance3D") else find_child("MeshInstance3D*", true, false)
	if not model_node: return
	var red_mat = StandardMaterial3D.new()
	red_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.6)
	red_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	red_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var meshes = []
	if model_node is MeshInstance3D: meshes.append(model_node)
	else:
		for child in model_node.get_children():
			if child is MeshInstance3D: meshes.append(child)

	for mesh in meshes: mesh.material_overlay = red_mat

	var tree = get_tree()
	if tree: await tree.create_timer(0.15).timeout

	if is_instance_valid(self) and not is_dead and current_stage == 1:
		for mesh in meshes: mesh.material_overlay = null

func spawn_custom_text(text_str: String, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.text = text_str
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 120
	label.outline_size = 20
	label.modulate = color

	get_parent().add_child(label)
	var start_pos = global_position + Vector3(0, 4.0 * boss_scale, 0)
	var end_pos = start_pos + Vector3(0, 2.0, 0)
	label.global_position = start_pos

	var tree = get_tree()
	if tree:
		var tween = tree.create_tween()
		if tween:
			tween.set_parallel(true)
			tween.tween_property(label, "global_position", end_pos, 2.0).set_ease(Tween.EASE_OUT)
			tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
			tween.chain().tween_callback(label.queue_free)

func die():
	if is_dead: return
	is_dead = true

	enemy_died.emit()

	remove_from_group("boss")
	remove_from_group("enemies")

	if is_inside_tree():
		call_deferred("reparent", get_tree().current_scene)

	set_physics_process(false)
	Global.score += 500

	if my_room != null and my_room.has_method("on_enemy_killed"):
		my_room.on_enemy_killed()

	spawn_coin_shower()
	if is_lightbulb_target:
		Global.add_money(10 * Global.lightbulb_count)

	if audio and is_inside_tree():
		var temp_sound = AudioStreamPlayer3D.new()
		temp_sound.stream = die_sound
		temp_sound.unit_size = 20.0
		temp_sound.pitch_scale = 0.5
		get_tree().current_scene.add_child(temp_sound)
		temp_sound.global_position = global_position
		temp_sound.play()
		temp_sound.finished.connect(temp_sound.queue_free)

	play_anim(anim_death)
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)

	var tree = get_tree()
	if tree: await tree.create_timer(3.0).timeout

	if is_instance_valid(self):
		call_deferred("queue_free")

func set_room(room_node): my_room = room_node
func get_health_percent() -> float: return current_health / max_health

func push_rigid_bodies():
	if not is_inside_tree() or is_dead: return
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is RigidBody3D:
			var push_dir = - col.get_normal()
			push_dir.y = 0
			if push_dir.length_squared() > 0.01:
				collider.apply_central_impulse(push_dir.normalized() * 35.0)

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

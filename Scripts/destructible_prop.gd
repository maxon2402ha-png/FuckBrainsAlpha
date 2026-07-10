extends RigidBody3D

@export var is_explosive: bool = false

var max_health: float = 20.0
var current_health: float = 20.0
var is_broken: bool = false

var explosion_radius: float = 6.0
var explosion_damage: float = 80.0
var explosion_force: float = 20.0


var kicked_by: String = ""
var kick_start_pos: Vector3 = Vector3.ZERO
var last_velocity: Vector3 = Vector3.ZERO

func _ready():
	current_health = max_health
	contact_monitor = true
	max_contacts_reported = 5



	linear_damp = 3.0
	angular_damp = 3.0

	body_entered.connect(_on_body_entered)

func _physics_process(_delta):
	last_velocity = linear_velocity


	if kicked_by != "" and linear_velocity.length() < 2.0:
		kicked_by = ""


func get_kicked(start_pos: Vector3, kicker_type: String = "player"):
	kicked_by = kicker_type
	kick_start_pos = start_pos

func _on_body_entered(body):
	if kicked_by == "": return

	var speed = clamp(last_velocity.length(), 0.0, 60.0)


	if speed > 5.0:


		var calc_dmg = 10.0 + (sqrt(mass) * speed * 0.4)

		var base_damage = clamp(calc_dmg, 10.0, 60.0)


		if kicked_by == "player" and (body.is_in_group("enemies") or body.is_in_group("boss")):
			var damage = base_damage
			var global_dmg_mult = Global.damage_multiplier if Global.get("damage_multiplier") != null else 1.0
			damage *= global_dmg_mult

			var is_crit = false

			if global_position.y - body.global_position.y > 1.0:
				damage *= 1.5
				is_crit = true

			if body.has_method("take_damage"):
				body.take_damage(damage, is_crit, global_position)

			take_damage(damage * 0.5)
			linear_velocity = last_velocity * 0.6

			if linear_velocity.length() < 6.0:
				kicked_by = ""


		elif kicked_by == "enemy" and (body.is_in_group("player") or body.name == "Player"):

			var player_damage = clamp(base_damage * 0.35, 5.0, 20.0)

			if body.has_method("take_damage"):
				body.take_damage(player_damage, "Летящий предмет")

			take_damage(player_damage)
			linear_velocity = last_velocity * 0.3
			kicked_by = ""

func take_damage(amount: float, _is_crit: bool = false, hit_dir: Vector3 = Vector3.ZERO, _extra_push = Vector3.ZERO):
	if is_broken or not is_inside_tree(): return

	if hit_dir == Vector3.ZERO:
		hit_dir = Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5)).normalized()


	var impact_force = clamp(amount * 0.4, 0.0, 25.0)

	apply_central_impulse(hit_dir * impact_force + Vector3(0, impact_force * 0.2, 0))
	apply_torque_impulse(Vector3(randf_range( - impact_force, impact_force), randf_range( - impact_force, impact_force), randf_range( - impact_force, impact_force)) * 0.1)

	if not is_broken:
		current_health -= amount
		if current_health <= 0:
			is_broken = true
			if is_explosive:
				trigger_explosion()
			else:
				break_prop()

func break_prop():
	if not is_inside_tree(): return
	visible = false
	var col = get_node_or_null("CollisionShape3D")
	if col: col.set_deferred("disabled", true)
	spawn_debris()
	await get_tree().create_timer(2.0).timeout
	queue_free()

func trigger_explosion():
	if not is_inside_tree(): return
	visible = false
	var col = get_node_or_null("CollisionShape3D")
	if col: col.set_deferred("disabled", true)
	spawn_volumetric_explosion()
	spawn_debris()
	deal_radial_damage()
	var sound = get_node_or_null("ExplosionSound")
	if sound:
		sound.pitch_scale = randf_range(0.8, 1.2)
		sound.play()
	await get_tree().create_timer(2.0).timeout
	queue_free()

func spawn_volumetric_explosion():
	var expl_root = Node3D.new()
	var scene_root = get_tree().current_scene if get_tree().current_scene else get_tree().root
	scene_root.add_child(expl_root)
	expl_root.global_position = global_position

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(2.0, 2.0, 2.0, 1.0)

	var meshes_to_animate = []
	var core = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radial_segments = 6
	sphere.rings = 4
	core.mesh = sphere
	core.material_override = mat
	expl_root.add_child(core)
	meshes_to_animate.append(core)

	for i in range(4):
		var puff = MeshInstance3D.new()
		puff.mesh = sphere
		puff.material_override = mat
		var offset = Vector3(randf_range(-1, 1), randf_range(-0.5, 1), randf_range(-1, 1)).normalized() * 0.8
		puff.position = offset
		puff.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
		expl_root.add_child(puff)
		meshes_to_animate.append(puff)

	var ring = MeshInstance3D.new()
	var r_mesh = TorusMesh.new()
	r_mesh.inner_radius = 0.8
	r_mesh.outer_radius = 1.0
	r_mesh.rings = 8
	r_mesh.ring_segments = 3
	ring.mesh = r_mesh
	ring.material_override = mat
	expl_root.add_child(ring)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.0)
	light.light_energy = 15.0
	light.omni_range = 15.0
	light.shadow_enabled = false
	expl_root.add_child(light)

	var tween = create_tween()
	tween.set_parallel(true)

	for m in meshes_to_animate:
		m.scale = Vector3.ZERO
		var target_scale = Vector3.ONE * randf_range(3.5, 5.0)
		tween.tween_property(m, "scale", target_scale, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(m, "scale", target_scale * 0.8, 0.2).set_delay(0.15)

	ring.scale = Vector3(0.1, 0.1, 0.1)
	tween.tween_property(ring, "scale", Vector3(8.0, 0.1, 8.0), 0.35).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(light, "light_energy", 0.0, 0.35)

	var color_tween = create_tween()
	color_tween.tween_property(mat, "albedo_color", Color(1.0, 0.8, 0.0, 1.0), 0.05)
	color_tween.tween_property(mat, "albedo_color", Color(0.8, 0.2, 0.0, 0.8), 0.1)
	color_tween.tween_property(mat, "albedo_color", Color(0.5, 0.1, 0.0, 0.0), 0.15)

	get_tree().create_timer(0.4).timeout.connect(expl_root.queue_free)

func spawn_debris():
	var p = GPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 12
	p.lifetime = 2.0

	var mat = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 25.0
	mat.gravity = Vector3(0, -35.0, 0)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.angular_velocity_min = 50.0
	mat.angular_velocity_max = 200.0
	mat.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	mat.collision_bounce = 0.4
	mat.collision_friction = 0.8

	p.process_material = mat
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.15, 0.5, 0.05)
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.3, 0.15, 0.05)
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mesh.material = p_mat
	p.draw_pass_1 = mesh

	var root = get_tree().current_scene if get_tree().current_scene else get_tree().root
	root.add_child(p)
	p.global_position = global_position + Vector3(0, 0.5, 0)
	p.restart()
	p.emitting = true
	get_tree().create_timer(2.1).timeout.connect(p.queue_free)

func deal_radial_damage():
	var targets = get_tree().get_nodes_in_group("enemies")
	var player = get_tree().get_first_node_in_group("player")
	if player: targets.append(player)

	var other_barrels = get_tree().get_nodes_in_group("barrels")
	for b in other_barrels: if b != self: targets.append(b)

	for target in targets:
		if not is_instance_valid(target): continue
		var dist = global_position.distance_to(target.global_position)
		if dist <= explosion_radius:
			var intensity = clamp(1.0 - (dist / explosion_radius), 0.2, 1.0)
			var final_damage = explosion_damage * intensity
			var push_dir = global_position.direction_to(target.global_position).normalized()
			push_dir.y += 0.5

			if target.has_method("take_damage"):
				if target == player:
					target.take_damage(final_damage, "Взрыв бочки")
					if target.has_method("add_camera_trauma"): target.add_camera_trauma(0.9 * intensity)
				elif target in other_barrels:
					target.take_damage(final_damage, false, push_dir)
				else:
					target.take_damage(final_damage, false, target.global_position, push_dir * explosion_force * intensity)

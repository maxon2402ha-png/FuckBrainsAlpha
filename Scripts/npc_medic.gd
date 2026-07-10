extends CharacterBody3D

var speed: float = 4.8
var max_health: float = 150.0
var current_health: float = 150.0
var is_dead: bool = false
var is_leaving: bool = false
var gravity: float = 28.0

var heal_amount: int = 5
var heal_cooldown: float = 0.0
var heal_interval: float = 0.5
var heal_range: float = 12.0
var preferred_distance: float = 5.0

var heal_beam: MeshInstance3D = null
var shout_cooldown: float = 0.0
var base_mat_override = null

@onready var nav_agent = get_node_or_null("NavigationAgent3D")

func _ready():
	add_to_group("friendlies")
	current_health = max_health
	set_model_color(Color(1.0, 0.8, 0.8), true)

	if nav_agent:
		nav_agent.path_desired_distance = 1.0
		nav_agent.target_desired_distance = preferred_distance
		nav_agent.avoidance_enabled = true
		nav_agent.radius = 1.0

	create_heal_beam()

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
	base_mat_override = mat
	var meshes = []
	if model_node is MeshInstance3D: meshes.append(model_node)
	else:
		for child in model_node.get_children():
			if child is MeshInstance3D: meshes.append(child)
	for mesh in meshes: mesh.material_override = mat

func create_heal_beam():
	heal_beam = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.08
	heal_beam.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.9, 0.1)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.surface_set_material(0, mat)
	add_child(heal_beam)
	heal_beam.top_level = true
	heal_beam.visible = false

func update_heal_beam(player):
	if not is_instance_valid(heal_beam): return

	if is_dead or is_leaving or player.current_health >= player.max_health or global_position.distance_to(player.global_position) > heal_range:
		heal_beam.visible = false
		return

	heal_beam.visible = true
	var start_pos = global_position + Vector3(0, 1.5, 0)
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	var dist = start_pos.distance_to(end_pos)

	heal_beam.mesh.height = dist
	heal_beam.global_position = start_pos.lerp(end_pos, 0.5)

	var aim_dir = start_pos.direction_to(end_pos)
	var up_vec = Vector3.UP
	if abs(aim_dir.y) > 0.99: up_vec = Vector3.RIGHT
	heal_beam.look_at(end_pos, up_vec)
	heal_beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)

func _physics_process(delta):
	if is_dead: return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_leaving:
		velocity.x = move_toward(velocity.x, 0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 10.0 * delta)
		move_and_slide()
		return

	if heal_cooldown > 0: heal_cooldown -= delta
	if shout_cooldown > 0: shout_cooldown -= delta

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var dist = global_position.distance_to(player.global_position)
		update_heal_beam(player)

		if dist > preferred_distance:
			if nav_agent:
				nav_agent.target_position = player.global_position
				var next_pos = nav_agent.get_next_path_position()
				var direction = (next_pos - global_position).normalized()
				direction.y = 0
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
				if direction.length_squared() > 0.01:
					rotation.y = lerp_angle(rotation.y, atan2( - direction.x, - direction.z), 10.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0, 15.0 * delta)
			var dir_to_player = global_position.direction_to(player.global_position)
			rotation.y = lerp_angle(rotation.y, atan2( - dir_to_player.x, - dir_to_player.z), 10.0 * delta)

		if dist <= heal_range and player.current_health < player.max_health:
			if heal_cooldown <= 0:
				heal_player(player)

	move_and_slide()

func heal_player(player):
	player.heal(heal_amount)
	heal_cooldown = heal_interval

	if shout_cooldown <= 0:
		spawn_custom_text("ЗЭР ГУД ВАЛЬДЕМАР!", Color(0.2, 1.0, 0.2))
		shout_cooldown = 4.0
		var audio_player = get_node_or_null("AudioStreamPlayer3D")
		if audio_player: audio_player.play()


func take_damage(amount, is_crit = false, _hit_pos = Vector3.ZERO, _impact_dir = Vector3.ZERO) -> bool:
	if is_dead or is_leaving: return false
	current_health -= amount
	spawn_damage_number(amount, is_crit)
	flash_red()
	if current_health <= 0: die()
	return false

func spawn_damage_number(amount: float, is_crit: bool):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.text = str(round(amount));label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test = true
	label.font_size = 72;label.outline_size = 15
	if is_crit: label.modulate = Color(1.0, 0.8, 0.0);label.scale = Vector3(1.5, 1.5, 1.5)
	else: label.modulate = Color(1.0, 1.0, 1.0)
	get_parent().add_child(label)
	var start_pos = global_position + Vector3(randf_range(-0.5, 0.5), 2.5, randf_range(-0.5, 0.5))
	var end_pos = start_pos + Vector3(0, 1.5, 0)
	label.global_position = start_pos
	var tween = create_tween()
	if tween:
		tween.set_parallel(true)
		tween.tween_property(label, "global_position", end_pos, 0.5).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.1)
		tween.chain().tween_callback(label.queue_free)

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
	if is_instance_valid(self) and not is_dead and not is_leaving:
		for mesh in meshes: mesh.material_override = base_mat_override

func die():
	if is_dead: return
	is_dead = true
	if is_instance_valid(heal_beam): heal_beam.queue_free()

	spawn_custom_text("МЕНЯ УБИЛИ...", Color(1.0, 0.2, 0.2))
	collision_layer = 0
	collision_mask = 0

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func leave_room():
	if is_dead or is_leaving: return
	is_leaving = true
	if is_instance_valid(heal_beam): heal_beam.queue_free()

	spawn_custom_text("АУФВИДЕРЗЕЙН!", Color(0.8, 0.8, 0.8))
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func spawn_custom_text(text_str: String, color: Color):
	if not is_inside_tree(): return
	var label = Label3D.new()
	label.text = text_str
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 60
	label.outline_size = 15
	label.modulate = color
	get_parent().add_child(label)
	var start_pos = global_position + Vector3(0, 2.5 * scale.y, 0)
	var end_pos = start_pos + Vector3(0, 1.5, 0)
	label.global_position = start_pos
	var tween = create_tween()
	if tween:
		tween.set_parallel(true)
		tween.tween_property(label, "global_position", end_pos, 1.0).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)
		tween.chain().tween_callback(label.queue_free)

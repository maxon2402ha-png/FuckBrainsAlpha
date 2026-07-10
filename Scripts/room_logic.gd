extends Node3D

var gates: Array = []
var battle_started: bool = false
var is_cleared: bool = false

var is_boss_room: bool = false
var is_gold_room: bool = false
var is_shop_room: bool = false

var stairs_node: Node3D = null
var exit_trigger: Area3D = null
var valid_floor_tiles: Array = []
var grid_pos: Vector2
var room_index: int = 0

var room_bounds: Dictionary = {"x_min": -2, "x_max": 2, "z_min": -2, "z_max": 2}
var tile_size: float = 4.0

var enemy_scenes: Array[PackedScene] = [
	preload("res://Scenes/enemy.tscn"), 
	preload("res://Scenes/ranged_enemy.tscn")
]

var boss_scene: PackedScene = preload("res://Scenes/boss_monstro.tscn")
var health_scene: PackedScene = preload("res://Scenes/medkit.tscn")
var oil_scene: PackedScene = preload("res://Scenes/Item_Baby_Oil.tscn")
var medic_scene: PackedScene = preload("res://Scenes/npc_medic.tscn")
var coin_scene: PackedScene = preload("res://Scenes/coin.tscn")

var room_light: OmniLight3D = null
var base_light_energy: float = 1.0
var flicker_timer: float = 0.0

var enemies_to_kill: int = 0

var pre_spawned_enemies: Array[Node3D] = []
var pre_spawned_boss: Node3D = null

func _ready():

	set_process(false)

	room_light = get_node_or_null("RoomLight")
	if room_light:
		base_light_energy = room_light.light_energy

	if gates.is_empty():
		for child in get_children():
			if "gate" in child.name.to_lower() or child is MeshInstance3D:
				pass

	if name == "StartRoom" or is_shop_room:
		call_deferred("instant_clear")
	else:
		_pre_spawn_entities()

func _pre_spawn_entities():
	if is_boss_room:
		pre_spawned_boss = boss_scene.instantiate()
		add_child(pre_spawned_boss)
		pre_spawned_boss.process_mode = Node.PROCESS_MODE_DISABLED
		pre_spawned_boss.visible = false

		if pre_spawned_boss.has_node("CollisionShape3D"):
			pre_spawned_boss.get_node("CollisionShape3D").set_deferred("disabled", true)

	elif not is_gold_room:

		var width: float = abs(room_bounds["x_max"] - room_bounds["x_min"])
		var depth: float = abs(room_bounds["z_max"] - room_bounds["z_min"])
		var room_area: float = width * depth


		var base_count: int = max(1, int(room_area / 18.0))


		var count: int = int(base_count * Global.get_enemy_count_multiplier())


		if Global.condoms_count > 0 and randf() < 0.4:
			count = int(count * 0.5)


		count = clampi(count + randi_range(-1, 1), 1, 45)

		var ranged_chance: float = 0.3 + (Global.current_level * 0.02)

		for i in range(count):
			var chosen_scene: PackedScene = enemy_scenes[1] if randf() < ranged_chance else enemy_scenes[0]

			var enemy: Node3D = chosen_scene.instantiate()
			add_child(enemy)
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			enemy.visible = false

			if enemy.has_node("CollisionShape3D"):
				enemy.get_node("CollisionShape3D").set_deferred("disabled", true)

			pre_spawned_enemies.append(enemy)

func instant_clear():
	is_cleared = true

	set_process(false)
	for gate in gates:
		if is_instance_valid(gate):
			gate.position.y = 4.0
			toggle_collision(gate, true)

func _process(delta: float):
	if not is_cleared and room_light:
		flicker_timer -= delta
		if flicker_timer <= 0:
			if randf() < 0.05:
				room_light.light_energy = base_light_energy * randf_range(0.1, 0.4)
				flicker_timer = randf_range(0.05, 0.1)
			else:
				room_light.light_energy = lerp(room_light.light_energy, base_light_energy, 20.0 * delta)
				flicker_timer = randf_range(0.05, 0.15)

func _on_enemy_killed():
	enemies_to_kill -= 1
	if enemies_to_kill <= 0 and battle_started:
		room_cleared()

func _on_player_entered(body: Node3D):
	if body.is_in_group("player") or body.name == "Player":
		Global.current_room_pos = grid_pos
		if not grid_pos in Global.discovered_rooms:
			Global.discovered_rooms.append(grid_pos)

		if not is_cleared and not is_shop_room and not battle_started:
			start_battle()

func _on_exit_entered(body: Node3D):
	if body.is_in_group("player") and is_boss_room and is_cleared:
		if Global.current_level < Global.MAX_LEVELS:
			Global.current_level += 1
			Global.save_game()

			var loading_screen = get_node_or_null("/root/LoadingScreen")
			if loading_screen:
				loading_screen.call_deferred("change_scene", "res://Scenes/level_generator.tscn", "> ГЕНЕРАЦИЯ СЛЕДУЮЩЕГО ЭТАЖА...")
			else:
				get_tree().call_deferred("change_scene_to_file", "res://Scenes/level_generator.tscn")
		else:
			Global.reset_run()

			var loading_screen = get_node_or_null("/root/LoadingScreen")
			if loading_screen:
				loading_screen.call_deferred("change_scene", "res://Scenes/main_menu.tscn", "> ВОЗВРАТ В МЕНЮ...")
			else:
				get_tree().call_deferred("change_scene_to_file", "res://Scenes/main_menu.tscn")

func start_battle():
	battle_started = true

	set_process(true)

	close_gates()

	if is_gold_room:
		var white_party_chance: float = Global.get_white_party_chance()
		if white_party_chance > 0 and randf() < white_party_chance:
			spawn_white_party_rewards()
		else:
			spawn_gold_reward()
		room_cleared()
	elif is_boss_room:
		Global.play_boss_music()
		spawn_boss()
	else:
		Global.play_combat_music()
		spawn_enemies()

func close_gates():
	for gate in gates:
		if is_instance_valid(gate):
			gate.visible = true
			toggle_collision(gate, false)
			gate.position.y = 4.0
			var tween: Tween = create_tween()
			tween.tween_property(gate, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func open_gates():
	for gate in gates:
		if is_instance_valid(gate):
			toggle_collision(gate, true)
			var tween: Tween = create_tween()
			tween.tween_property(gate, "position:y", 4.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_callback( func(): gate.visible = false)

func spawn_enemies():
	enemies_to_kill = 0

	var player_hp_factor: float = 0.0
	var player_dmg_factor: float = 0.0
	var player: Node3D = get_tree().get_first_node_in_group("player")

	if is_instance_valid(player):
		if "max_health" in player:
			player_hp_factor = float(player.max_health) / 100.0

	if Global.get("meta_upgrades") != null:
		player_dmg_factor = float(Global.meta_upgrades.get("damage", 0)) * 0.15
		player_hp_factor += float(Global.meta_upgrades.get("health", 0)) * 0.1


	var enemy_hp_multiplier: float = Global.get_enemy_hp_multiplier() + player_dmg_factor
	var enemy_dmg_multiplier: float = Global.get_enemy_dmg_multiplier() + (player_hp_factor * 0.25)

	var formations: Array = calculate_formation(pre_spawned_enemies.size())
	var nav_map: RID = get_world_3d().navigation_map

	for i in range(pre_spawned_enemies.size()):
		var enemy: Node3D = pre_spawned_enemies[i]
		if not is_instance_valid(enemy): continue

		var local_pos: Vector3 = formations[i]
		local_pos += Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))

		var global_target: Vector3 = global_position + local_pos
		var safe_global_pos: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, global_target)

		enemy.position = to_local(safe_global_pos) + Vector3(0, 1.0, 0)
		enemy.scale = Vector3(2, 2, 2)

		if enemy.has_method("set_stats"):
			enemy.set_stats(enemy_hp_multiplier, enemy_dmg_multiplier)

		if enemy.has_node("CollisionShape3D"):
			enemy.get_node("CollisionShape3D").set_deferred("disabled", false)

		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.visible = true

		enemies_to_kill += 1
		if enemy.has_signal("enemy_died"):
			if not enemy.enemy_died.is_connected(_on_enemy_killed):
				enemy.enemy_died.connect(_on_enemy_killed)

	if Global.lightbulb_count > 0 and pre_spawned_enemies.size() > 0:
		var target: Node3D = pre_spawned_enemies.pick_random()
		if target.has_method("make_lightbulb_target"):
			target.make_lightbulb_target()

	var friendly_chance: float = Global.get_final_friendly_chance()
	if friendly_chance > 0 and randf() < friendly_chance:
		var friendly: Node3D = enemy_scenes[0].instantiate()
		add_child(friendly)

		var safe_pos: Vector3 = get_random_valid_tile()
		var global_f_target: Vector3 = global_position + safe_pos
		var safe_f_global: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, global_f_target)
		friendly.position = to_local(safe_f_global) + Vector3(0, 1.0, 0)

		if friendly.has_method("make_friendly"):
			friendly.make_friendly()

		if Global.inventory.has("mge_photo") and Global.armor >= 3.0:
			friendly.scale = Vector3(4.0, 4.0, 4.0)
			if friendly.has_method("set_stats"):
				friendly.set_stats(5.0, 3.0)
		else:
			friendly.scale = Vector3(2, 2, 2)

	if Global.cologne_count > 0 and randf() < 0.3:
		var medic: Node3D = medic_scene.instantiate()
		if medic:
			add_child(medic)
			var m_pos: Vector3 = get_random_valid_tile()

			var global_m_target: Vector3 = global_position + m_pos
			var safe_m_global: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, global_m_target)
			medic.position = to_local(safe_m_global) + Vector3(0, 1.0, 0)

func spawn_boss():
	if pre_spawned_boss and is_instance_valid(pre_spawned_boss):
		pre_spawned_boss.position = Vector3(0, 1.5, 0)

		var player_hp_factor: float = 0.0
		var player_dmg_factor: float = 0.0
		var player: Node3D = get_tree().get_first_node_in_group("player")

		if is_instance_valid(player):
			if "max_health" in player:
				player_hp_factor = float(player.max_health) / 100.0
		if Global.get("meta_upgrades") != null:
			player_dmg_factor = float(Global.meta_upgrades.get("damage", 0)) * 0.15
			player_hp_factor += float(Global.meta_upgrades.get("health", 0)) * 0.1


		var boss_hp_multiplier: float = (Global.get_enemy_hp_multiplier() * 5.0) + (player_dmg_factor * 2.0)
		var boss_dmg_multiplier: float = (Global.get_enemy_dmg_multiplier() * 2.0) + (player_hp_factor * 0.5)

		if pre_spawned_boss.has_method("set_stats"):
			pre_spawned_boss.set_stats(boss_hp_multiplier, boss_dmg_multiplier)

		if pre_spawned_boss.has_node("CollisionShape3D"):
			pre_spawned_boss.get_node("CollisionShape3D").set_deferred("disabled", false)

		pre_spawned_boss.process_mode = Node.PROCESS_MODE_INHERIT
		pre_spawned_boss.visible = true

		enemies_to_kill = 1
		if pre_spawned_boss.has_signal("enemy_died"):
			if not pre_spawned_boss.enemy_died.is_connected(_on_enemy_killed):
				pre_spawned_boss.enemy_died.connect(_on_enemy_killed)

func room_cleared():
	if is_cleared: return
	is_cleared = true
	battle_started = false


	set_process(false)
	if room_light:
		room_light.light_energy = base_light_energy

	open_gates()
	Global.fade_out_music()

	if is_boss_room:
		if stairs_node: stairs_node.position.y = 0
		if exit_trigger: exit_trigger.set_deferred("monitoring", true)
	elif not is_gold_room and not is_shop_room:
		spawn_rewards()

	if Global.inventory.has("medpolis") and not is_shop_room:
		Global.medpolis_room_counter += 1
		if Global.medpolis_room_counter >= 5:
			Global.medpolis_room_counter = 0
			_drop_item(health_scene)

	for child in get_children():
		if child.is_in_group("friendlies") and child.has_method("leave_room"):
			child.leave_room()

func _drop_item(scene: PackedScene):
	if not scene: return
	var item: Node3D = scene.instantiate()
	add_child(item)

	var nav_map: RID = get_world_3d().navigation_map
	var safe_pos: Vector3 = get_random_valid_tile()
	var global_target: Vector3 = global_position + safe_pos
	var safe_global: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, global_target)

	item.position = to_local(safe_global) + Vector3(0, 1.0, 0)

func spawn_rewards():
	var roll: float = randf()

	if roll < 0.4:
		if coin_scene:

			var min_coins: int = 2 + int(Global.current_level / 4.0)
			var max_coins: int = 5 + int(Global.current_level / 2.0)
			var coin_count: int = randi_range(min_coins, max_coins)

			var nav_map: RID = get_world_3d().navigation_map

			for i in range(coin_count):

				var random_offset: Vector3 = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
				var center_pos: Vector3 = get_random_valid_tile()
				var global_target: Vector3 = global_position + center_pos + random_offset
				var safe_global: Vector3 = NavigationServer3D.map_get_closest_point(nav_map, global_target)

				var spawn_pos: Vector3 = to_local(safe_global) + Vector3(0, 1.0, 0)
				var root = get_tree().current_scene if get_tree().current_scene else get_parent()

				var coin = Global.spawn_from_pool("coins", coin_scene, global_position + spawn_pos, root)
				if not coin:
					coin = coin_scene.instantiate()
					add_child(coin)
					coin.position = spawn_pos

	elif roll < 0.65:
		_drop_item(health_scene)

func spawn_white_party_rewards():
	if room_light:
		room_light.light_color = Color(1.0, 1.0, 1.0)
		base_light_energy = 3.0
		room_light.light_energy = 3.0

	var is_two_items: bool = randf() < 0.5
	if is_two_items:
		for i in range(2):
			var scn: PackedScene = Global.get_random_item_scene()
			_drop_item(scn)
	else:
		var rare_scene: PackedScene = get_rare_item_scene()
		_drop_item(rare_scene)

		if randf() < 0.1:
			_drop_item(oil_scene)

func get_rare_item_scene() -> PackedScene:
	var rares: Array = []
	for item in Global.item_pool:
		if item[1] <= 35:
			rares.append(item[0])
	if rares.size() > 0: return rares.pick_random()
	return Global.get_random_item_scene()

func spawn_gold_reward():
	var scene_to_spawn: PackedScene = Global.get_random_item_scene()
	_drop_item(scene_to_spawn)

func calculate_formation(count: int) -> Array:
	var points: Array = []
	var x_m: float = room_bounds["x_min"] * tile_size
	var x_M: float = room_bounds["x_max"] * tile_size
	var z_m: float = room_bounds["z_min"] * tile_size
	var z_M: float = room_bounds["z_max"] * tile_size
	var cx: float = (x_m + x_M) / 2.0
	var cz: float = (z_m + z_M) / 2.0
	var inset: float = tile_size * 1.0
	var available_width: float = (x_M - x_m) - (inset * 2)
	var available_depth: float = (z_M - z_m) - (inset * 2)

	if available_width <= 0 or available_depth <= 0:
		for i in range(count): points.append(Vector3(cx, 0, cz))
		return points

	var patterns: Array = ["ring", "line_x", "line_z"]
	if count >= 4:
		patterns.append("corners")
		patterns.append("cross")

	var chosen: String = patterns.pick_random()
	match chosen:
		"corners":
			points.append(Vector3(x_m + inset, 0, z_m + inset))
			points.append(Vector3(x_M - inset, 0, z_m + inset))
			points.append(Vector3(x_m + inset, 0, z_M - inset))
			points.append(Vector3(x_M - inset, 0, z_M - inset))
			for i in range(4, count): points.append(Vector3(cx, 0, cz))
		"cross":
			points.append(Vector3(cx, 0, cz))
			var d_x: float = available_width / 2.0
			var d_z: float = available_depth / 2.0
			points.append(Vector3(cx + d_x, 0, cz))
			points.append(Vector3(cx - d_x, 0, cz))
			points.append(Vector3(cx, 0, cz + d_z))
			points.append(Vector3(cx, 0, cz - d_z))
			for i in range(5, count): points.append(Vector3(cx, 0, cz))
		"ring":
			var radius: float = min(available_width, available_depth) / 2.0
			for i in range(count):
				var angle: float = (TAU / count) * i
				points.append(Vector3(cx + cos(angle) * radius, 0, cz + sin(angle) * radius))
		"line_x":
			var step: float = available_width / max(1.0, float(count - 1))
			for i in range(count):
				points.append(Vector3(x_m + inset + (step * i), 0, cz))
		"line_z":
			var step: float = available_depth / max(1.0, float(count - 1))
			for i in range(count):
				points.append(Vector3(cx, 0, z_m + inset + (step * i)))

	return points

func get_random_valid_tile() -> Vector3:
	if valid_floor_tiles.is_empty(): return Vector3.ZERO
	return valid_floor_tiles.pick_random()

func toggle_collision(node: Node, state: bool):
	if node is CollisionShape3D: node.set_deferred("disabled", state)
	for child in node.get_children(): toggle_collision(child, state)

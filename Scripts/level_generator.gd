extends Node3D

var floors = [
	preload("res://Assets/Models/GLB format/template-floor.glb")
]

var walls_solid = [
	preload("res://Assets/Models/GLB format/template-wall.glb"), 
	preload("res://Assets/Models/GLB format/template-wall-detail-a.glb")
]

var corridor_straight = preload("res://Assets/Models/GLB format/corridor.glb")
var corridor_intersection = preload("res://Assets/Models/GLB format/corridor-intersection.glb")
var corridor_turn = preload("res://Assets/Models/GLB format/corridor-corner.glb")

var asset_gate_frame = preload("res://Assets/Models/GLB format/gate.glb")
var asset_gate_bars = preload("res://Assets/Models/GLB format/gate-metal-bars.glb")
var asset_pillar = preload("res://Assets/Models/GLB format/template-wall-corner.glb")
var asset_stairs = preload("res://Assets/Models/GLB format/stairs.glb")
var shop_pedestal_scene = preload("res://Scenes/shop_pedestal.tscn")
var destructible_prop_script = preload("res://Scripts/destructible_prop.gd")
var player_scene = preload("res://Scenes/player.tscn")
var room_logic_script = preload("res://Scripts/room_logic.gd")

var prop_models = [
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/barrel_large.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/barrel_small.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/crates_stacked.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/box_large.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/table_long.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/table_small.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/chair.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/bed_decorated.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/chest_gold.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/shelf_large.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/candle.gltf"), 
	preload("res://Assets/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/plate_food_B.gltf")
]

var total_rooms = 5
var tile_size = 4.0
var max_radius = 5
var room_height_tiles = 4
var room_spacing = 48.0

var map = {}
var corridors_map = {}
var directions = [Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]

@onready var nav_region = $NavigationRegion3D
var occupied_cells = {}

var cached_floor_meshes: Array[Mesh] = []
var cached_wall_meshes: Array[Mesh] = []
var cached_wall_shapes: Array[Shape3D] = []
var cached_props: Dictionary = {}
var cached_architecture: Dictionary = {}

const DOOR_SAFE_RADIUS: float = 3.5

func get_corridor_key(p1: Vector2, p2: Vector2) -> String:
	if p1.x < p2.x or (p1.x == p2.x and p1.y < p2.y):
		return str(p1.x) + "_" + str(p1.y) + "|" + str(p2.x) + "_" + str(p2.y)
	return str(p2.x) + "_" + str(p2.y) + "|" + str(p1.x) + "_" + str(p1.y)

func _ready():
	_cache_meshes_and_shapes()
	randomize()
	_setup_ambient_environment()
	generate_level()


func _setup_ambient_environment():
	if get_node_or_null("WorldEnvironment"): return

	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"

	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.03, 0.04, 0.06)
	env.ambient_light_energy = 0.55

	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.025
	env.volumetric_fog_albedo = Color(0.015, 0.015, 0.02)

	env.tonemap_mode = Environment.TONE_MAPPER_ACES

	env_node.environment = env
	add_child(env_node)


func _cache_meshes_and_shapes():
	for f in floors:
		var m = _get_mesh_from_packed(f)
		if m: cached_floor_meshes.append(m)

	for w in walls_solid:
		var m = _get_mesh_from_packed(w)
		if m:
			cached_wall_meshes.append(m)
			cached_wall_shapes.append(m.create_trimesh_shape())

	for p in prop_models:
		var inst = p.instantiate()
		var m_node = _find_mesh_node(inst)
		if m_node and m_node.mesh:
			cached_props[p.resource_path] = {
				"mesh": m_node.mesh, 
				"shape": m_node.mesh.create_convex_shape(true, true)
			}
		inst.queue_free()

	_cache_single_architecture(asset_pillar, true)
	_cache_single_architecture(corridor_straight, true)
	_cache_single_architecture(asset_gate_frame, true)

func _cache_single_architecture(scene: PackedScene, use_trimesh: bool):
	var inst = scene.instantiate()
	var m_node = _find_mesh_node(inst)
	if m_node and m_node.mesh:
		var shape = m_node.mesh.create_trimesh_shape() if use_trimesh else m_node.mesh.create_convex_shape(true, true)
		cached_architecture[scene.resource_path] = {"mesh": m_node.mesh, "shape": shape}
	inst.queue_free()

func _get_mesh_from_packed(scene: PackedScene) -> Mesh:
	var instance = scene.instantiate()
	var m_node = _find_mesh_node(instance)
	var result = null
	if m_node: result = m_node.mesh
	instance.queue_free()
	return result

func _find_mesh_node(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D: return node
	for c in node.get_children():
		var res = _find_mesh_node(c)
		if res: return res
	return null

func _build_cached_static_node(path: String) -> MeshInstance3D:
	if not cached_architecture.has(path): return null
	var data = cached_architecture[path]

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = data.mesh

	var st_body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	col.shape = data.shape
	st_body.add_child(col)
	mesh_inst.add_child(st_body)

	return mesh_inst

func _add_occluder_to_mesh(mesh_inst: MeshInstance3D, is_wall: bool = true):
	if not is_wall: return

	var occluder = OccluderInstance3D.new()
	var box_occluder = BoxOccluder3D.new()

	box_occluder.size = Vector3(tile_size, tile_size, 0.5)

	occluder.occluder = box_occluder
	mesh_inst.add_child(occluder)

func generate_level():
	occupied_cells.clear()

	total_rooms = 5 + int(Global.current_level * 2.5)
	max_radius = 4 + int(Global.current_level * 0.8)
	room_spacing = (max_radius * 2 + 2) * tile_size

	var current_pos = Vector2(0, 0)
	var rooms_to_generate = [current_pos]
	map[current_pos] = null
	var last_pos = current_pos

	while rooms_to_generate.size() < total_rooms:
		var dir = directions.pick_random()
		var new_pos = last_pos + dir
		if map.has(new_pos):
			last_pos = new_pos
			continue
		if count_neighbors_in_map(new_pos) > 1: continue

		map[new_pos] = null
		rooms_to_generate.append(new_pos)
		corridors_map[get_corridor_key(last_pos, new_pos)] = true
		last_pos = new_pos

	var gold_room_index = -1
	var shop_room_index = -1
	if rooms_to_generate.size() > 4:
		gold_room_index = randi_range(1, rooms_to_generate.size() - 2)
		shop_room_index = randi_range(1, rooms_to_generate.size() - 2)
		while shop_room_index == gold_room_index:
			shop_room_index = randi_range(1, rooms_to_generate.size() - 2)

	Global.map_layout.clear()
	Global.discovered_rooms.clear()

	for i in range(rooms_to_generate.size()):
		var pos = rooms_to_generate[i]
		Global.map_layout.append(pos)
		var is_start = (i == 0)
		var is_boss = (pos == last_pos)
		var is_gold = (i == gold_room_index)
		var is_shop = (i == shop_room_index)

		var room_name = "StartRoom"
		if is_boss: room_name = "BossRoom";Global.boss_room_pos = pos
		elif is_gold: room_name = "GoldRoom";Global.gold_room_pos = pos
		elif is_shop: room_name = "ShopRoom";Global.shop_room_pos = pos
		elif not is_start: room_name = "Room_" + str(i)

		build_dynamic_room(pos, room_name, is_boss, is_gold, is_shop, is_start, i)

		if i % 2 == 0:
			await get_tree().process_frame

	build_corridors()

	nav_region.bake_navigation_mesh(true)
	await nav_region.bake_finished

	spawn_player()

	await get_tree().create_timer(0.5).timeout
	if Global.has_method("play_ambient_music"):
		Global.play_ambient_music()


func is_position_safe_from_doors(local_pos: Vector2, active_doors: Array) -> bool:
	for door_pos in active_doors:
		if local_pos.distance_to(door_pos) < DOOR_SAFE_RADIUS:
			return false
	return true

func build_dynamic_room(grid_pos, r_name, is_boss, is_gold, is_shop, is_start, room_idx):
	var room_node = Node3D.new()
	room_node.name = r_name
	room_node.position = Vector3(grid_pos.x * room_spacing, 0, grid_pos.y * room_spacing)
	nav_region.add_child(room_node)

	room_node.set_script(room_logic_script)
	room_node.set("grid_pos", grid_pos)
	room_node.set("room_index", room_idx)
	map[grid_pos] = room_node

	var is_special = is_boss or is_gold or is_shop or is_start
	if is_boss: room_node.set("is_boss_room", true)
	if is_gold: room_node.set("is_gold_room", true)
	if is_shop: room_node.set("is_shop_room", true)

	var has_N = corridors_map.has(get_corridor_key(grid_pos, grid_pos + Vector2(0, -1)))
	var has_S = corridors_map.has(get_corridor_key(grid_pos, grid_pos + Vector2(0, 1)))
	var has_E = corridors_map.has(get_corridor_key(grid_pos, grid_pos + Vector2(1, 0)))
	var has_W = corridors_map.has(get_corridor_key(grid_pos, grid_pos + Vector2(-1, 0)))

	room_node.set_meta("has_N", has_N)
	room_node.set_meta("has_S", has_S)
	room_node.set_meta("has_E", has_E)
	room_node.set_meta("has_W", has_W)

	var z_min = - max_radius
	var z_max = max_radius
	var x_min = - max_radius
	var x_max = max_radius

	if not is_special:
		var madness_offset = int(clamp(Global.current_level / 2.0, 0.0, 2.0))
		z_min = - max_radius if has_N else randi_range( - max_radius + madness_offset, -3)
		z_max = max_radius if has_S else randi_range(3, max_radius - madness_offset)
		x_max = max_radius if has_E else randi_range(3, max_radius - madness_offset)
		x_min = - max_radius if has_W else randi_range( - max_radius + madness_offset, -3)

	room_node.set("room_bounds", {"x_min": x_min, "x_max": x_max, "z_min": z_min, "z_max": z_max})
	room_node.set("tile_size", tile_size)

	var room_center_x = ((x_min + x_max) / 2.0) * tile_size
	var room_center_z = ((z_min + z_max) / 2.0) * tile_size
	var room_center_v3 = Vector3(room_center_x, 0, room_center_z)

	var heightmap = {}
	var local_obstacles = {}


	var active_doors = []
	if has_N: active_doors.append(Vector2(0, z_min))
	if has_S: active_doors.append(Vector2(0, z_max))
	if has_E: active_doors.append(Vector2(x_max, 0))
	if has_W: active_doors.append(Vector2(x_min, 0))

	for x in range(x_min, x_max + 1):
		for z in range(z_min, z_max + 1):
			heightmap[Vector2(x, z)] = 0

	var room_shape = 0

	if is_boss or is_start:
		room_shape = 99
	else:
		room_shape = randi_range(0, 16)

	var carve = func(bx_min, bx_max, bz_min, bz_max):
		for x in range(bx_min, bx_max + 1):
			for z in range(bz_min, bz_max + 1):
				if has_N and x >= -1 and x <= 1 and z <= 0: continue
				if has_S and x >= -1 and x <= 1 and z >= 0: continue
				if has_E and z >= -1 and z <= 1 and x >= 0: continue
				if has_W and z >= -1 and z <= 1 and x <= 0: continue
				if x >= -1 and x <= 1 and z >= -1 and z <= 1: continue
				if x >= x_min and x <= x_max and z >= z_min and z <= z_max:
					var local_pos = Vector2(x, z)

					if is_position_safe_from_doors(local_pos, active_doors):
						heightmap[local_pos] = room_height_tiles
						local_obstacles[local_pos] = true
						occupied_cells[room_node.global_position + Vector3(x * tile_size, 0, z * tile_size)] = true

	var safe_internal_wall = func(type, index, start, end):
		for i in range(start, end + 1):
			if abs(i) <= 1 and abs(index) <= 1: continue
			if abs(i) <= 1 and index < 0 and has_N: continue
			if abs(i) <= 1 and index > 0 and has_S: continue
			if abs(index) <= 1 and i > 0 and has_E: continue
			if abs(index) <= 1 and i < 0 and has_W: continue

			var local_pos = Vector2(i, index) if type == "H" else Vector2(index, i)


			if is_position_safe_from_doors(local_pos, active_doors):
				local_obstacles[local_pos] = true
				var pos3d = Vector3(local_pos.x * tile_size, 0, local_pos.y * tile_size)
				add_internal_wall_piece(room_node, pos3d, 0.0 if type == "H" else 90.0)
				occupied_cells[room_node.global_position + pos3d] = true

	match room_shape:
		99:
			pass
		0:
			var p_x1 = int(lerp(float(x_min), 0.0, 0.5))
			var p_x2 = int(lerp(0.0, float(x_max), 0.5))
			carve.call(p_x1 - 1, p_x1, z_min + 2, z_max - 2)
			carve.call(p_x2, p_x2 + 1, z_min + 2, z_max - 2)
		1:
			safe_internal_wall.call("H", -2, x_min + 1, x_max - 1)
			safe_internal_wall.call("V", 2, z_min + 1, -2)
		2:
			var b_min = int(max(x_min, z_min) / 2.0)
			var b_max = int(min(x_max, z_max) / 2.0)
			safe_internal_wall.call("H", b_min, b_min, b_max)
			safe_internal_wall.call("H", b_max, b_min, b_max)
			safe_internal_wall.call("V", b_min, b_min, b_max)
			safe_internal_wall.call("V", b_max, b_min, b_max)
		3:
			carve.call(x_min, x_min + 2, z_min, z_min + 2)
			carve.call(x_max - 2, x_max, z_min, z_min + 2)
			carve.call(x_min, x_min + 2, z_max - 2, z_max)
			carve.call(x_max - 2, x_max, z_max - 2, z_max)
		4:
			safe_internal_wall.call("H", z_min + 2, x_min + 2, 0)
			safe_internal_wall.call("V", 0, z_min + 2, z_max - 2)
			safe_internal_wall.call("H", z_max - 2, 0, x_max - 2)
		5:
			for z in range(z_min, z_max + 1):
				var w = int(abs(float(z) / float(z_max + 0.1) * float(x_max - x_min) / 2.0))
				carve.call(x_min, x_min + w - 1, z, z)
				carve.call(x_max - w + 1, x_max, z, z)
		6:
			carve.call(x_min, 0, z_min, z_max)
		7:
			carve.call(2, x_max, 2, z_max)
		8:
			safe_internal_wall.call("H", z_min + 2, x_min + 1, x_max - 2)
			safe_internal_wall.call("H", z_max - 2, x_min + 2, x_max - 1)
			safe_internal_wall.call("V", x_min + 2, z_min + 2, 0)
			safe_internal_wall.call("V", x_max - 2, 0, z_max - 2)
		9:
			safe_internal_wall.call("H", z_max - 2, x_min, x_max)
		10:
			for px in range(x_min + 2, x_max - 1, 2):
				for pz in range(z_min + 2, z_max - 1, 2):
					carve.call(px, px, pz, pz)
		11:
			carve.call(2, x_max, z_min, -2)
		12:
			carve.call(x_min, -2, z_min, -2)
			carve.call(2, x_max, z_min, -2)
			carve.call(x_min, -2, 2, z_max)
			carve.call(2, x_max, 2, z_max)
		13:
			safe_internal_wall.call("V", -2, 2, z_max)
			safe_internal_wall.call("V", 2, 2, z_max)
		14:
			safe_internal_wall.call("H", -2, x_min, -2)
			safe_internal_wall.call("H", 2, x_min, -2)
			safe_internal_wall.call("V", -2, -2, 2)
		15:
			carve.call(x_min, -2, z_min, -2)
			carve.call(2, x_max, z_min, -2)
		16:
			safe_internal_wall.call("H", -2, 2, x_max)
			safe_internal_wall.call("V", 2, z_min, -2)

	var valid_floor_tiles = []

	for x in range(x_min, x_max + 1):
		for z in range(z_min, z_max + 1):
			var h = heightmap[Vector2(x, z)]
			var floor_pos = Vector3(x * tile_size, h * tile_size, z * tile_size)

			var floor_tile = MeshInstance3D.new()
			if cached_floor_meshes.size() > 0:
				floor_tile.mesh = cached_floor_meshes.pick_random()

			_add_occluder_to_mesh(floor_tile, false)

			room_node.add_child(floor_tile)
			floor_tile.position = floor_pos

			var f_body = StaticBody3D.new()
			var f_shape = CollisionShape3D.new()
			var f_box = BoxShape3D.new()
			f_box.size = Vector3(tile_size, 2.0, tile_size)
			f_shape.shape = f_box
			f_shape.position = Vector3(0, -1.0, 0)
			f_body.add_child(f_shape)
			floor_tile.add_child(f_body)

			var ceiling_tile = MeshInstance3D.new()
			if cached_floor_meshes.size() > 0:
				ceiling_tile.mesh = cached_floor_meshes[0]

			_add_occluder_to_mesh(ceiling_tile, false)

			room_node.add_child(ceiling_tile)
			ceiling_tile.position = Vector3(x * tile_size, room_height_tiles * tile_size, z * tile_size)
			ceiling_tile.rotation_degrees.x = 180

			var c_body = StaticBody3D.new()
			var c_shape = CollisionShape3D.new()
			var c_box = BoxShape3D.new()
			c_box.size = Vector3(tile_size, 2.0, tile_size)
			c_shape.shape = c_box
			c_shape.position = Vector3(0, -1.0, 0)
			c_body.add_child(c_shape)
			ceiling_tile.add_child(c_body)

			var neighbors = {"N": Vector2(0, -1), "S": Vector2(0, 1), "E": Vector2(1, 0), "W": Vector2(-1, 0)}
			for dir_key in neighbors.keys():
				var nx = x + neighbors[dir_key].x
				var nz = z + neighbors[dir_key].y
				if nx >= x_min and nx <= x_max and nz >= z_min and nz <= z_max:
					var nh = heightmap[Vector2(nx, nz)]
					if h > nh:
						for gap_y in range(nh, h):
							var internal_wall
							if cached_wall_meshes.size() > 0:
								var r_idx = randi() % cached_wall_meshes.size()
								internal_wall = MeshInstance3D.new()
								internal_wall.mesh = cached_wall_meshes[r_idx]

								var st_body = StaticBody3D.new()
								var col = CollisionShape3D.new()
								col.shape = cached_wall_shapes[r_idx]
								st_body.add_child(col)
								internal_wall.add_child(st_body)
							else:
								internal_wall = walls_solid.pick_random().instantiate()
								add_collision_to_node(internal_wall, true)

							_add_occluder_to_mesh(internal_wall, true)

							room_node.add_child(internal_wall)
							var w_offset = Vector3.ZERO
							var w_rot = 0
							var shift = tile_size / 2.0
							if dir_key == "N": w_rot = 0;w_offset.z = - shift
							elif dir_key == "S": w_rot = 180;w_offset.z = shift
							elif dir_key == "E": w_rot = -90;w_offset.x = shift
							elif dir_key == "W": w_rot = 90;w_offset.x = - shift
							internal_wall.rotation_degrees.y = w_rot
							internal_wall.position = Vector3(x * tile_size, gap_y * tile_size, z * tile_size) + w_offset

			var is_solid_pillar = (h >= room_height_tiles)
			var is_door_path = false
			if has_N and x >= -1 and x <= 1 and z <= 0: is_door_path = true
			if has_S and x >= -1 and x <= 1 and z >= 0: is_door_path = true
			if has_E and z >= -1 and z <= 1 and x >= 0: is_door_path = true
			if has_W and z >= -1 and z <= 1 and x <= 0: is_door_path = true

			if not is_solid_pillar and not is_door_path:
				valid_floor_tiles.append(floor_pos)

	var room_theme = randi() % 4
	if Global.current_level >= 4 and randf() > 0.6: room_theme = 4
	if is_shop: room_theme = -1
	if is_boss: room_theme = 0
	if is_start: room_theme = -1

	var is_large_room = not (is_shop or is_gold)
	var safe_zone_radius = 2.0 * tile_size

	match room_theme:
		0:
			var num_items = randi_range(5, 15) if is_large_room else randi_range(1, 3)
			for i in range(num_items):
				if valid_floor_tiles.is_empty(): break
				var tile_idx = randi() % valid_floor_tiles.size()
				var t_pos = valid_floor_tiles[tile_idx]
				var local_pos = Vector2(int(round(t_pos.x / tile_size)), int(round(t_pos.z / tile_size)))


				if not local_obstacles.has(local_pos) and t_pos.distance_to(room_center_v3) > safe_zone_radius and is_position_safe_from_doors(local_pos, active_doors):
					var item = ["box_large", "crates", "barrel_large"].pick_random()
					spawn_single_prop(room_node, t_pos, item, [0, 90, 180, -90].pick_random())
					local_obstacles[local_pos] = true

		1:
			if not local_obstacles.has(Vector2(0, 0)):
				spawn_single_prop(room_node, room_center_v3, "table_long", [0, 90].pick_random())
				local_obstacles[Vector2(0, 0)] = true

			for tp in valid_floor_tiles:
				var vx = int(tp.x / tile_size); var vz = int(tp.z / tile_size)
				if local_obstacles.has(Vector2(vx, vz)): continue

				var near_N = heightmap.get(Vector2(vx, vz - 1), 0) >= room_height_tiles
				var near_S = heightmap.get(Vector2(vx, vz + 1), 0) >= room_height_tiles
				var near_E = heightmap.get(Vector2(vx + 1, vz), 0) >= room_height_tiles
				var near_W = heightmap.get(Vector2(vx - 1, vz), 0) >= room_height_tiles

				if (near_N or near_S or near_E or near_W) and randf() > 0.6:
					if near_N: spawn_single_prop(room_node, tp, "bed", 0)
					elif near_S: spawn_single_prop(room_node, tp, "bed", 180)
					elif near_E: spawn_single_prop(room_node, tp, "bed", -90)
					elif near_W: spawn_single_prop(room_node, tp, "bed", 90)
					local_obstacles[Vector2(vx, vz)] = true

		2:
			var is_horizontal = randf() > 0.5
			var shelf_rot = 0.0 if is_horizontal else 90.0
			for tp in valid_floor_tiles:
				var vx = int(tp.x / tile_size); var vz = int(tp.z / tile_size)
				if local_obstacles.has(Vector2(vx, vz)) or tp.distance_to(room_center_v3) < safe_zone_radius: continue

				if (is_horizontal and vz % 2 == 0) or ( not is_horizontal and vx % 2 == 0):
					if randf() > 0.3 and is_position_safe_from_doors(Vector2(vx, vz), active_doors):
						spawn_single_prop(room_node, tp, "shelf", shelf_rot)
						local_obstacles[Vector2(vx, vz)] = true

		3:
			var num_rubble = randi_range(10, 20) if is_large_room else randi_range(2, 5)
			for i in range(num_rubble):
				if valid_floor_tiles.is_empty(): break
				var t_pos = valid_floor_tiles.pick_random()
				var local_pos = Vector2(int(round(t_pos.x / tile_size)), int(round(t_pos.z / tile_size)))
				if not local_obstacles.has(local_pos) and t_pos.distance_to(room_center_v3) > safe_zone_radius:
					spawn_single_prop(room_node, t_pos, "candle", [0, 90, 180, -90].pick_random())
					local_obstacles[local_pos] = true

		4:
			var chaos_items = ["chair", "table_small", "barrel", "chest"]
			var num_chaos = 15 if is_large_room else 5
			for i in range(num_chaos):
				if valid_floor_tiles.is_empty(): break
				var t_pos = valid_floor_tiles.pick_random()
				var local_pos = Vector2(int(round(t_pos.x / tile_size)), int(round(t_pos.z / tile_size)))
				if not local_obstacles.has(local_pos) and is_position_safe_from_doors(local_pos, active_doors):
					spawn_single_prop(room_node, t_pos, chaos_items.pick_random(), randf_range(0, 360))
					local_obstacles[local_pos] = true

	var truly_free_tiles = []
	for tp in valid_floor_tiles:
		var vx = int(round(tp.x / tile_size))
		var vz = int(round(tp.z / tile_size))

		var is_safe = true
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var cx = vx + dx
				var cz = vz + dz
				if cx <= x_min or cx >= x_max or cz <= z_min or cz >= z_max:
					is_safe = false
				elif local_obstacles.has(Vector2(cx, cz)):
					is_safe = false

		if is_safe:
			truly_free_tiles.append(tp)

	room_node.set("valid_floor_tiles", truly_free_tiles)

	build_wall_row(room_node, "N", z_min, x_min, x_max, has_N, heightmap)
	build_wall_row(room_node, "S", z_max, x_min, x_max, has_S, heightmap)
	build_wall_row(room_node, "E", x_max, z_min, z_max, has_E, heightmap)
	build_wall_row(room_node, "W", x_min, z_min, z_max, has_W, heightmap)

	place_pillar_at(room_node, x_min, z_min, -90, heightmap)
	place_pillar_at(room_node, x_max, z_min, 0, heightmap)
	place_pillar_at(room_node, x_max, z_max, 90, heightmap)
	place_pillar_at(room_node, x_min, z_max, 180, heightmap)
	add_room_trigger(room_node, x_min, x_max, z_min, z_max)


	_spawn_smart_lighting(room_node, room_center_v3, x_min, x_max, z_min, z_max, is_boss, is_shop, is_gold, room_theme)

	if is_shop and shop_pedestal_scene:
		var shop_positions = [Vector3(-4, 0, -2), Vector3(0, 0, -2), Vector3(4, 0, -2)]
		for p in shop_positions:
			var pedestal = shop_pedestal_scene.instantiate()
			room_node.add_child(pedestal)
			pedestal.position = room_center_v3 + p

	if is_boss:
		var stairs = asset_stairs.instantiate()
		room_node.add_child(stairs)
		stairs.position = room_center_v3
		if has_N: stairs.rotation_degrees.y = 180
		elif has_S: stairs.rotation_degrees.y = 0
		elif has_E: stairs.rotation_degrees.y = 90
		elif has_W: stairs.rotation_degrees.y = -90

		add_collision_to_node(stairs, true)
		stairs.position.y -= 10.0
		room_node.set("stairs_node", stairs)
		add_exit_trigger(room_node)

	if room_node.has_method("_ready"):
		room_node._ready()

func build_corridors():
	for key in corridors_map.keys():
		var parts = key.split("|")
		var p1_str = parts[0].split("_")
		var p2_str = parts[1].split("_")
		var pos_a = Vector2(float(p1_str[0]), float(p1_str[1]))
		var pos_b = Vector2(float(p2_str[0]), float(p2_str[1]))

		var real_pos_a = Vector3(pos_a.x * room_spacing, 0, pos_a.y * room_spacing)
		var real_pos_b = Vector3(pos_b.x * room_spacing, 0, pos_b.y * room_spacing)

		var corridor = _build_cached_static_node(corridor_straight.resource_path)
		if not corridor:
			corridor = corridor_straight.instantiate()
			add_collision_to_node(corridor, true)

		if pos_a.x == pos_b.x: corridor.rotation_degrees.y = 90
		else: corridor.rotation_degrees.y = 0

		nav_region.add_child(corridor)
		corridor.position = (real_pos_a + real_pos_b) / 2.0

		var f_body = StaticBody3D.new()
		var f_shape = CollisionShape3D.new()
		var f_box = BoxShape3D.new()
		f_box.size = Vector3(tile_size, 2.0, tile_size)
		f_shape.shape = f_box
		f_shape.position = Vector3(0, -1.0, 0)
		f_body.add_child(f_shape)
		corridor.add_child(f_body)

func spawn_single_prop(room, pos, keyword, rot_y):
	var chosen_path = ""
	for m in prop_models:
		if keyword in m.resource_path.get_file().to_lower():
			chosen_path = m.resource_path
			break

	if chosen_path == "" or not cached_props.has(chosen_path): return

	var cache = cached_props[chosen_path]
	var model_instance = MeshInstance3D.new()
	model_instance.mesh = cache.mesh

	var rigid = RigidBody3D.new()
	rigid.set_script(destructible_prop_script)

	rigid.sleeping = true
	rigid.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC

	if "candle" in keyword or "plate" in keyword: rigid.set("max_health", 5.0);rigid.mass = 0.5
	elif "chair" in keyword: rigid.set("max_health", 15.0);rigid.mass = 4.0
	elif "barrel" in keyword: rigid.set("is_explosive", true);rigid.set("max_health", 40.0);rigid.mass = 50.0
	elif "table" in keyword or "desk" in keyword: rigid.set("max_health", 50.0);rigid.mass = 45.0
	elif "bed" in keyword or "shelf" in keyword: rigid.set("max_health", 100.0);rigid.mass = 80.0
	elif "box" in keyword or "crates" in keyword or "chest" in keyword: rigid.set("max_health", 25.0);rigid.mass = 30.0
	elif "rubble" in keyword: rigid.set("max_health", 200.0);rigid.mass = 300.0
	else: rigid.set("max_health", 20.0);rigid.mass = 10.0

	var coll = CollisionShape3D.new()
	coll.shape = cache.shape
	rigid.add_child(coll)
	rigid.add_child(model_instance)

	room.add_child(rigid)
	rigid.position = pos + Vector3(0, 0.05, 0)
	rigid.rotation_degrees.y = rot_y

func build_wall_row(room, side, level_index, start_index, end_index, has_main_door, h_map):
	var is_horizontal = (side == "N" or side == "S")
	var rotation_y = 0
	var z_offset = 0; var x_offset = 0
	var wall_shift = tile_size / 2.0

	if side == "N": rotation_y = 180;z_offset = - wall_shift
	elif side == "S": rotation_y = 0;z_offset = wall_shift
	elif side == "E": rotation_y = 90;x_offset = wall_shift
	elif side == "W": rotation_y = -90;x_offset = - wall_shift

	var r_gates = room.get("gates")
	if r_gates == null: r_gates = []

	for i in range(start_index, end_index + 1):
		var is_center = (i == 0)
		var local_h = h_map.get(Vector2(i, level_index) if is_horizontal else Vector2(level_index, i), 0)

		var should_have_door = false
		if is_center and has_main_door:
			should_have_door = true

		for y_level in range(local_h, room_height_tiles):
			var piece = null
			if should_have_door and y_level == 0:
				piece = _build_cached_static_node(asset_gate_frame.resource_path)
				if not piece:
					piece = asset_gate_frame.instantiate()
					add_collision_to_node(piece, true)

				var bars = asset_gate_bars.instantiate()
				bars.name = "Bars";bars.visible = false
				piece.add_child(bars)
				add_collision_to_node(bars, false)
				set_collision_disabled(bars, true)
				r_gates.append(bars)
			else:
				var random_w_mesh = cached_wall_meshes.pick_random() if cached_wall_meshes.size() > 0 else null
				if random_w_mesh:
					piece = MeshInstance3D.new()
					piece.mesh = random_w_mesh

					_add_occluder_to_mesh(piece, true)

					var st_body = StaticBody3D.new()
					var col = CollisionShape3D.new()
					col.shape = cached_wall_shapes[cached_wall_meshes.find(random_w_mesh)]
					st_body.add_child(col)
					piece.add_child(st_body)
				else:
					piece = walls_solid.pick_random().instantiate()
					add_collision_to_node(piece, true)

			if piece:
				room.add_child(piece)
				piece.rotation_degrees.y = rotation_y
				var pos_y = y_level * tile_size
				if is_horizontal: piece.position = Vector3(i * tile_size, pos_y, level_index * tile_size + z_offset)
				else: piece.position = Vector3(level_index * tile_size + x_offset, pos_y, i * tile_size)

	room.set("gates", r_gates)

func place_pillar_at(room, tile_x, tile_z, rot_y, h_map):
	var offset = tile_size / 2.0
	var px = tile_x * tile_size + (offset if tile_x > 0 else - offset)
	var pz = tile_z * tile_size + (offset if tile_z > 0 else - offset)
	place_pillar_v3_at(room, Vector3(px, 0, pz), rot_y, h_map)

func add_internal_wall_piece(room, pos_v3, rot_y = 0.0):
	for y_level in range(room_height_tiles):
		var internal_wall
		if cached_wall_meshes.size() > 0:
			var r_idx = randi() % cached_wall_meshes.size()
			internal_wall = MeshInstance3D.new()
			internal_wall.mesh = cached_wall_meshes[r_idx]

			var st_body = StaticBody3D.new()
			var col = CollisionShape3D.new()
			col.shape = cached_wall_shapes[r_idx]
			st_body.add_child(col)
			internal_wall.add_child(st_body)

			_add_occluder_to_mesh(internal_wall, true)
		else:
			internal_wall = walls_solid.pick_random().instantiate()
			add_collision_to_node(internal_wall, true)

		room.add_child(internal_wall)
		internal_wall.position = pos_v3 + Vector3(0, y_level * tile_size, 0)
		internal_wall.rotation_degrees.y = rot_y

func place_pillar_v3_at(room, pos_v3, rot_y = 0.0, h_map = null):
	var local_h = 0
	if h_map:
		var tile_x = int(pos_v3.x / tile_size)
		var tile_z = int(pos_v3.z / tile_size)
		local_h = h_map.get(Vector2(tile_x, tile_z), 0)

	for y_level in range(local_h, room_height_tiles):
		var p = _build_cached_static_node(asset_pillar.resource_path)
		if not p:
			p = asset_pillar.instantiate()
			add_collision_to_node(p, true)
		room.add_child(p)
		p.position = Vector3(pos_v3.x, y_level * tile_size, pos_v3.z)
		p.rotation_degrees.y = rot_y

func add_room_trigger(room, x1, x2, z1, z2):
	var area = Area3D.new()
	area.name = "Trigger"
	room.add_child(area)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()

	var width = (x2 - x1) * tile_size - 4.0
	var depth = (z2 - z1) * tile_size - 4.0

	box.size = Vector3(width, (room_height_tiles + 2) * tile_size, depth)

	var center_x = (x1 + x2) * tile_size / 2.0
	var center_z = (z1 + z2) * tile_size / 2.0
	shape.shape = box
	shape.position = Vector3(center_x, (room_height_tiles * tile_size) / 2.0, center_z)

	area.add_child(shape)
	if room.has_method("_on_player_entered"):
		area.body_entered.connect(room._on_player_entered)

func add_exit_trigger(room):
	var area = Area3D.new()
	room.add_child(area)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4, 4, 4)
	shape.shape = box
	shape.position = Vector3(0, 1, 0)
	area.add_child(shape)
	area.monitoring = false
	room.set("exit_trigger", area)
	if room.has_method("_on_exit_entered"): area.body_entered.connect(room._on_exit_entered)

func count_neighbors_in_map(pos):
	var count = 0
	for d in directions: if map.has(pos + d): count += 1
	return count

func spawn_player():
	var p = player_scene.instantiate()
	add_child(p)
	p.position = Vector3(0, 2, 0)

func add_collision_to_node(node, use_trimesh = true):
	if node is MeshInstance3D and node.mesh:
		var static_body = StaticBody3D.new()
		var col_shape = CollisionShape3D.new()
		if use_trimesh: col_shape.shape = node.mesh.create_trimesh_shape()
		else: col_shape.shape = node.mesh.create_convex_shape(true, true)
		static_body.add_child(col_shape)
		node.add_child(static_body)
	for child in node.get_children():
		if child is StaticBody3D: continue
		add_collision_to_node(child, use_trimesh)

func set_collision_disabled(node, is_disabled):
	if node is CollisionShape3D: node.disabled = is_disabled
	for child in node.get_children(): set_collision_disabled(child, is_disabled)





func _spawn_smart_lighting(room, center, x_min, x_max, z_min, z_max, is_boss, is_shop, is_gold, theme_idx):
	var width_tiles = abs(x_max - x_min)
	var depth_tiles = abs(z_max - z_min)
	var is_large_room = (width_tiles >= 4 or depth_tiles >= 4)

	var palettes = [
		{"main": Color(1.0, 0.6, 0.2), "accent": Color(0.1, 0.5, 0.8)}, 
		{"main": Color(0.8, 1.0, 0.8), "accent": Color(0.1, 0.2, 0.4)}, 
		{"main": Color(1.0, 0.2, 0.2), "accent": Color(0.5, 0.1, 0.0)}, 
		{"main": Color(0.9, 0.9, 1.0), "accent": Color(0.4, 0.1, 0.6)}
	]

	var p = palettes[theme_idx % palettes.size()]

	if is_shop: p = {"main": Color(1.0, 0.9, 0.6), "accent": Color(0.3, 0.8, 0.5)}
	if is_gold: p = {"main": Color(1.0, 0.8, 0.1), "accent": Color(0.8, 0.4, 0.0)}
	if is_boss: p = {"main": Color(1.0, 0.0, 0.0), "accent": Color(0.2, 0.0, 0.0)}


	var main_light = OmniLight3D.new()
	main_light.name = "KeyLight"
	main_light.light_color = p.main
	main_light.light_energy = randf_range(1.7, 2.2)

	main_light.shadow_enabled = true
	main_light.distance_fade_enabled = true
	main_light.distance_fade_begin = 30.0
	main_light.distance_fade_shadow = 20.0
	main_light.shadow_blur = 1.5

	var max_dim = max(width_tiles, depth_tiles) * tile_size
	main_light.omni_range = max_dim * 1.3
	main_light.omni_attenuation = 1.2

	main_light.position = center + Vector3(0, (room_height_tiles * tile_size) - 1.5, 0)
	room.add_child(main_light)

	if randf() > 0.8 and not (is_shop or is_gold):
		_apply_horror_flicker(main_light)


	if is_large_room and not is_boss:
		var corners = [
			Vector2(x_min + 1, z_min + 1), 
			Vector2(x_max - 1, z_min + 1), 
			Vector2(x_min + 1, z_max - 1), 
			Vector2(x_max - 1, z_max - 1)
		]

		for c in corners:
			if randf() > 0.5:
				var accent = OmniLight3D.new()
				accent.name = "AccentLight"
				accent.light_color = p.accent
				accent.light_energy = randf_range(0.4, 0.9)

				accent.shadow_enabled = false

				accent.omni_range = 3.5 * tile_size
				accent.omni_attenuation = 2.0

				accent.position = Vector3(c.x * tile_size, (room_height_tiles * tile_size) * 0.4, c.y * tile_size)
				room.add_child(accent)

func _apply_horror_flicker(light_node: OmniLight3D):
	var flicker_tween = create_tween().set_loops()
	var base_e = light_node.light_energy

	flicker_tween.tween_property(light_node, "light_energy", base_e * randf_range(0.6, 0.8), randf_range(0.05, 0.15))
	flicker_tween.tween_property(light_node, "light_energy", base_e * randf_range(1.1, 1.2), randf_range(0.02, 0.08))
	flicker_tween.tween_property(light_node, "light_energy", base_e * 0.2, randf_range(0.01, 0.05))
	flicker_tween.tween_property(light_node, "light_energy", base_e, randf_range(0.2, 0.6))

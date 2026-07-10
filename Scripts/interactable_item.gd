extends CollisionObject3D

var item_id: String = ""
var prompt_height: float = 0.5

var prompt_label: Label3D = null
var is_highlighted: bool = false
var meshes: Array[MeshInstance3D] = []
var outline_material: ShaderMaterial = null


func _init_item(id: String):
	item_id = id


	add_to_group("interactable")
	add_to_group("items")


	meshes.clear()
	_find_meshes(self)


	if prompt_label == null:
		prompt_label = Label3D.new()
		prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		prompt_label.no_depth_test = true
		prompt_label.pixel_size = 0.004
		prompt_label.font_size = 32
		prompt_label.outline_size = 8
		prompt_label.outline_render_priority = 0
		prompt_label.render_priority = 10

		prompt_label.visible = false
		prompt_label.position = Vector3(0, prompt_height - 0.2, 0)
		add_child(prompt_label)


	outline_material = ShaderMaterial.new()

	var shader = preload("res://Shaders/item_outline.gdshader")
	if shader: outline_material.shader = shader

	if item_id in ["xbox_gamepad", "ps_gamepad", "chingis_eggs"]:
		outline_material.set_shader_parameter("outline_color", Color("#ff007f"))

func _find_meshes(node: Node):
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_find_meshes(child)

func highlight():
	if is_highlighted: return
	is_highlighted = true

	var item_name = "НЕИЗВЕСТНЫЙ ОБЪЕКТ"
	if Global.get("item_database") and Global.item_database.has(item_id):
		item_name = Global.item_database[item_id]["name"]

	var key_code = Global.keybinds.get("interact", KEY_E)
	var key_string = OS.get_keycode_string(key_code).to_upper()

	prompt_label.text = "[ " + item_name + " ]\n> НАЖМИ [ " + key_string + " ] <"
	prompt_label.modulate = Color("#00ff41")

	prompt_label.visible = true
	var tw = create_tween()
	tw.tween_property(prompt_label, "position:y", prompt_height, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


	for mesh in meshes:
		mesh.material_overlay = outline_material

func unhighlight():
	if not is_highlighted: return
	is_highlighted = false

	var tw = create_tween()
	tw.tween_property(prompt_label, "position:y", prompt_height - 0.2, 0.1)
	tw.tween_callback( func(): prompt_label.visible = false)


	for mesh in meshes:
		mesh.material_overlay = null

func interact(player_node):
	if Global.has_method("add_item"):
		Global.add_item(item_id)

	if player_node and player_node.has_node("HitmarkerPlayer"):
		var audio = player_node.get_node("HitmarkerPlayer")
		audio.pitch_scale = 1.5
		audio.play()

	queue_free()

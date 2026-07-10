extends Area3D

var base_price: int = 0
var final_price: int = 0
var item_instance: Node3D = null
var item_id: String = ""

var update_timer: float = 0.0


var is_highlighted: bool = false
var outline_material: ShaderMaterial = null
var meshes: Array[MeshInstance3D] = []
var prompt_label: Label3D = null
var prompt_height: float = 2.2

@onready var price_label = $PriceLabel

func _ready():

	add_to_group("interactable")

	base_price = randi_range(20, 35)


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

	var scene = Global.get_random_item_scene()
	if scene:
		var scene_path = scene.resource_path
		if Global.item_scene_map.has(scene_path):
			item_id = Global.item_scene_map[scene_path]

		item_instance = scene.instantiate()


		item_instance.set_script(null)

		for child in item_instance.get_children():
			if child is CollisionShape3D:
				child.queue_free()

		add_child(item_instance)
		item_instance.position = Vector3(0, 1.2, 0)


		var tw = create_tween().set_loops()
		tw.tween_property(item_instance, "rotation_degrees:y", 360.0, 4.0).as_relative()

		_find_meshes(item_instance)

		outline_material = ShaderMaterial.new()
		var shader = preload("res://Shaders/item_outline.gdshader")
		if shader: outline_material.shader = shader


	var my_col = find_child("CollisionShape*", true, false)
	if my_col and my_col.shape is BoxShape3D:
		my_col.shape.size.y = 2.5
		my_col.position.y = 1.25

	_update_price()

func _find_meshes(node: Node):
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		_find_meshes(child)

func _process(delta):
	update_timer += delta
	if update_timer >= 1.0:
		update_timer = 0.0
		_update_price()

func _update_price():
	var old_price = final_price
	final_price = Global.get_inflated_price(base_price)

	if price_label and old_price != final_price:
		price_label.text = str(final_price) + " $"

		if final_price < old_price:
			price_label.modulate = Color(0.2, 1.0, 0.2)
		elif final_price > old_price:
			price_label.modulate = Color(1.0, 0.2, 0.2)
		else:
			price_label.modulate = Color(1.0, 1.0, 1.0)





func highlight():
	if is_highlighted: return
	is_highlighted = true


	for mesh in meshes:
		mesh.material_overlay = outline_material


	if price_label:
		var tw_price = create_tween()
		tw_price.tween_property(price_label, "scale", Vector3(1.2, 1.2, 1.2), 0.1)


	var item_name = "НЕИЗВЕСТНЫЙ ОБЪЕКТ"
	if item_id != "" and Global.item_database.has(item_id):
		item_name = Global.item_database[item_id]["name"]

	var key_code = Global.keybinds.get("interact", KEY_E)
	var key_string = OS.get_keycode_string(key_code).to_upper()

	prompt_label.text = "[ " + item_name + " ]\n> КУПИТЬ [ " + key_string + " ] <"
	prompt_label.modulate = Color(1.0, 0.8, 0.2)
	prompt_label.visible = true

	var tw_prompt = create_tween()
	tw_prompt.tween_property(prompt_label, "position:y", prompt_height, 0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func unhighlight():
	if not is_highlighted: return
	is_highlighted = false


	for mesh in meshes:
		mesh.material_overlay = null


	if price_label:
		var tw_price = create_tween()
		tw_price.tween_property(price_label, "scale", Vector3(1.0, 1.0, 1.0), 0.1)


	if prompt_label:
		var tw_prompt = create_tween()
		tw_prompt.tween_property(prompt_label, "position:y", prompt_height - 0.2, 0.1)
		tw_prompt.tween_callback( func(): prompt_label.visible = false)

func interact(player_node):
	if Global.money >= final_price:
		Global.money -= final_price
		Global.emit_signal("money_updated")


		if item_id != "" and Global.has_method("add_item"):
			Global.add_item(item_id)

		if player_node and player_node.has_node("HitmarkerPlayer"):
			var audio = player_node.get_node("HitmarkerPlayer")
			audio.pitch_scale = 1.2
			audio.play()

		queue_free()
	else:
		if player_node and player_node.has_method("show_notification"):
			player_node.show_notification("НЕДОСТАТОЧНО СРЕДСТВ! НУЖНО " + str(final_price) + "$", Color(1.0, 0.2, 0.2))

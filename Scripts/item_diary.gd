extends Area3D


@export var item_id: String = "diary"
@export var price: int = 0


var hover_speed: float = 3.0
var hover_amplitude: float = 0.2
var rotation_speed: float = 1.5

@onready var mesh_holder = $MeshHolder
@onready var light = get_node_or_null("OmniLight3D")

var start_y: float = 0.0
var time_passed: float = 0.0
var start_light_energy: float = 1.5
var is_highlighted: bool = false
var glow_material: StandardMaterial3D

func _ready():

	add_to_group("interactable")


	glow_material = StandardMaterial3D.new()
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


	time_passed = randf_range(0.0, 10.0)


	await get_tree().process_frame
	if mesh_holder:
		start_y = mesh_holder.position.y

	if light:
		start_light_energy = light.light_energy

func _process(delta):
	if not mesh_holder: return

	time_passed += delta


	mesh_holder.rotate_y(rotation_speed * delta)


	var bob = sin(time_passed * hover_speed)
	mesh_holder.position.y = start_y + bob * hover_amplitude


	if light:
		light.light_energy = start_light_energy + (bob * 0.5)


func highlight():
	if is_highlighted or not mesh_holder: return
	is_highlighted = true


	for child in mesh_holder.get_children():
		if child is MeshInstance3D:
			child.material_overlay = glow_material

func unhighlight():
	if not is_highlighted or not mesh_holder: return
	is_highlighted = false


	for child in mesh_holder.get_children():
		if child is MeshInstance3D:
			child.material_overlay = null


func interact(player):
	if price > 0:

		if Global.money >= price:
			Global.money -= price
			player.update_money_ui()
			player.add_item(item_id)
			_play_pickup_juice()
		else:
			player.show_notification("НЕДОСТАТОЧНО СРЕДСТВ", Color(1.0, 0.2, 0.2))
	else:

		player.add_item(item_id)
		_play_pickup_juice()

func _play_pickup_juice():
	unhighlight()


	collision_layer = 0
	collision_mask = 0


	if mesh_holder:
		mesh_holder.visible = false


	if light:
		var tween = create_tween()
		tween.tween_property(light, "light_energy", start_light_energy * 3.0, 0.1)
		tween.tween_property(light, "light_energy", 0.0, 0.2)
		await tween.finished

	queue_free()

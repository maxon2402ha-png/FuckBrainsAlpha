extends Node3D

@onready var blood_mesh = $BloodMesh
var mat: ShaderMaterial

var max_lifetime = 15.0
var current_growth = 0.1
var target_growth = 0.5

func _ready():

	mat = blood_mesh.material_override.duplicate()
	blood_mesh.material_override = mat


	mat.set_shader_parameter("seed", randf_range(0.0, 100.0))
	mat.set_shader_parameter("growth", current_growth)

	target_growth = randf_range(0.4, 0.7)
	rotation.y = randf_range(0, TAU)

	get_tree().create_timer(max_lifetime).timeout.connect(_fade_out)

func _process(delta):

	if current_growth < target_growth:
		current_growth = lerp(current_growth, target_growth, delta * 4.0)
		mat.set_shader_parameter("growth", current_growth)

func _fade_out():
	var tween = create_tween()

	tween.tween_method( func(val):
		if is_instance_valid(mat):
			mat.set_shader_parameter("growth", val)
	, current_growth, 0.0, 3.0)

	tween.chain().tween_callback(queue_free)

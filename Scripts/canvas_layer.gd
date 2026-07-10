extends CanvasLayer


@onready var color_rect = $VHS_Effect

func _ready():
	add_to_group("vhs_filter")

	call_deferred("update_vhs_settings")

func update_vhs_settings():
	if not color_rect: return

	color_rect.visible = Global.vhs_enabled

	if color_rect.visible and color_rect.material is ShaderMaterial:
		var mat = color_rect.material
		mat.set_shader_parameter("effect_intensity", Global.vhs_intensity)
		mat.set_shader_parameter("noise_intensity", Global.vhs_noise)
		mat.set_shader_parameter("color_displacement", Global.vhs_rgb)






		match Global.vhs_style:
			0:
				mat.set_shader_parameter("vhs_tint", Vector3(1.0, 1.0, 1.0))
				mat.set_shader_parameter("grayscale_mix", 0.0)
			1:
				mat.set_shader_parameter("vhs_tint", Vector3(1.0, 1.0, 1.0))
				mat.set_shader_parameter("grayscale_mix", 1.0)
			2:
				mat.set_shader_parameter("vhs_tint", Vector3(0.3, 1.0, 0.4))
				mat.set_shader_parameter("grayscale_mix", 0.8)
			3:
				mat.set_shader_parameter("vhs_tint", Vector3(1.0, 0.5, 0.5))
				mat.set_shader_parameter("grayscale_mix", 0.4)

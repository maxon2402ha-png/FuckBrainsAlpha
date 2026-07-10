extends ColorRect

func _ready() -> void :
	add_to_group("vhs_filter")
	print("📺 [VHS] Фильтр добавлен в группу 'vhs_filter'!")
	update_vhs_settings()

func update_vhs_settings() -> void :
	print("📺 [VHS] Получен сигнал! Шум: ", Global.vhs_noise, " | RGB: ", Global.vhs_rgb, " | Стиль: ", Global.vhs_style)

	visible = Global.vhs_enabled
	if not visible:
		print("📺 [VHS] Фильтр скрыт (галочка выключена).")
		return

	if not material is ShaderMaterial:
		print("❌ [ОШИБКА VHS] У ColorRect нет ShaderMaterial! Проверь инспектор.")
		return

	var mat = material as ShaderMaterial


	mat.set_shader_parameter("noise_amount", Global.vhs_noise)
	mat.set_shader_parameter("rgb_shift", Global.vhs_rgb)
	mat.set_shader_parameter("intensity", Global.vhs_intensity)

	match Global.vhs_style:
		0:
			mat.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0, 1.0))
			mat.set_shader_parameter("saturation", 1.0)
		1:
			mat.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0, 1.0))
			mat.set_shader_parameter("saturation", 0.0)
		2:
			mat.set_shader_parameter("tint_color", Color(0.2, 1.0, 0.2, 1.0))
			mat.set_shader_parameter("saturation", 0.5)
		3:
			mat.set_shader_parameter("tint_color", Color(1.0, 0.2, 0.2, 1.0))
			mat.set_shader_parameter("saturation", 0.8)

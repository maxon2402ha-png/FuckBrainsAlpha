shader_type spatial;
render_mode unshaded, blend_add, shadows_disabled, cull_disabled;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float face_threshold = 0.2;

void vertex() {
	vec3 side_vec3 = -MODEL_MATRIX[0].xyz;
	vec4 side_vec4 = -MODEL_MATRIX[0];
	MODELVIEW_MATRIX = VIEW_MATRIX * (
		mat4(
			vec4(normalize(cross(side_vec3, INV_VIEW_MATRIX[2].xyz)), 0.0),
			side_vec4,
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, side_vec3)), 0.0),
			MODEL_MATRIX[3]
		)
	);
}

void fragment() {
	float vec_dif = abs(dot(MODEL_MATRIX[0].xyz, CAMERA_DIRECTION_WORLD));
	
	// === СЖИМАЕМ ВСПЫШКУ СИЛЬНЕЕ ПО ВЕРТИКАЛИ (uv.y *= 5.0;) ===
	vec2 uv = UV - vec2(0.5);
	// Было 2.5, увеличили до 5.0, чтобы сжать сильнее. Пламя станет ниже.
	uv.y *= 5.0; 
	float dist = length(uv);
	
	// Острый градиент (оставить без изменений)
	float glow = smoothstep(0.4, 0.0, dist);
	
	// Яркие "огненные" цвета (оставить без изменений)
	vec3 core = vec3(2.0, 1.5, 0.5);
	vec3 edge = vec3(1.5, 0.2, 0.0);
	
	ALBEDO = mix(edge, core, pow(glow, 3.0));
	ALPHA = glow * opacity * max(0.0, 1.0 - vec_dif - face_threshold);
}
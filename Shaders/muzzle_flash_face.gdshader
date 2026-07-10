shader_type spatial;
render_mode unshaded, blend_add, shadows_disabled, cull_disabled;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float face_threshold = 0.2;

void vertex() {
	vec3 face_vec3 = -MODEL_MATRIX[1].xyz;
	vec4 face_vec4 = -MODEL_MATRIX[1];
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(face_vec3, INV_VIEW_MATRIX[2].xyz)), 0.0),
		face_vec4,
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, face_vec3)), 0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
	float vec_dif = abs(dot(MODEL_MATRIX[0].xyz, CAMERA_DIRECTION_WORLD));
	vec2 uv = UV - vec2(0.5);
	
	// === ДОБАВЛЯЕМ СЖАТИЕ ПО ВЕРТИКАЛИ (uv.y *= 3.0;) ===
	// Это превратит звезду в сплющенный эллипс.
	uv.y *= 3.0; 
	
	// Делаем лучи звезды более тонкими и длинными (оставить без изменений)
	float angle = atan(uv.y, uv.x);
	float radius = length(uv);
	float star = abs(cos(angle * 4.0)) * 0.15 + 0.85; 
	float dist = radius / star;
	
	float glow = smoothstep(0.4, 0.0, dist);
	
	vec3 core = vec3(2.0, 1.5, 0.5);
	vec3 edge = vec3(1.5, 0.2, 0.0);
	
	ALBEDO = mix(edge, core, pow(glow, 3.0));
	ALPHA = glow * opacity * max(0.0, 0.5 - max(0.0, 1.0 - vec_dif - face_threshold));
}
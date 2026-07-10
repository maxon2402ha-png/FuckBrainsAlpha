shader_type spatial;
// Важно: unshaded делает его светящимся в темноте, cull_front выворачивает наизнанку для обводки
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 0.25, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;

void vertex() {
	// Раздуваем модельку по нормалям
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	
	// PS1 Глитч-эффект мерцания
	float time_q = floor(TIME * 20.0) / 20.0;
	float noise = fract(sin(dot(UV + time_q, vec2(12.9898, 78.233))) * 43758.5453);
	ALPHA = mix(0.4, 1.0, step(0.5, noise));
}
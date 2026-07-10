shader_type spatial;
// Добавили depth_test_disabled, чтобы кровь не "проваливалась" в пол при малейшем перепаде высот
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded, depth_test_disabled;

uniform vec3 blood_color : source_color = vec3(0.4, 0.02, 0.02);
uniform float growth : hint_range(0.0, 1.0) = 0.1; 
uniform float edge_sharpness : hint_range(0.1, 10.0) = 5.0; 
uniform float seed : hint_range(0.0, 100.0) = 0.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
               mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    float n = noise(uv * 3.0 + vec2(seed, seed * 2.0)) * 0.4;
    float blob = dist + n;
    
    float alpha = smoothstep(growth + 0.1, growth - (1.0/edge_sharpness), blob);
    vec3 final_color = mix(blood_color * 0.5, blood_color, alpha);
    
    ALBEDO = final_color;
    ALPHA = clamp(alpha, 0.0, 1.0);
}
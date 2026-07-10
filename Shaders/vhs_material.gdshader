shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// --- НАСТРОЙКИ (ВЫКЛЮЧЕНЫ ПО УМОЛЧАНИЮ ДЛЯ ЧИСТОТЫ) ---
// Волны и двоение ставим на 0.0 по умолчанию. Игрок сам добавит, если захочет.
uniform float tape_wave_amount : hint_range(0.0, 0.05) = 0.0; 
uniform float color_displacement : hint_range(0.0, 5.0) = 0.0; 
uniform float lines_velocity : hint_range(0.0, 5.0) = 0.0;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.01; // Едва уловимый шум

uniform vec3 vhs_tint = vec3(1.0, 1.0, 1.0); 
uniform float grayscale_mix : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
    // 1. УБРАЛИ ИСКРИВЛЕНИЕ ЛИНЗЫ! Теперь экран плоский, глаза не будут уставать.
    vec2 final_uv = SCREEN_UV; 

    float time = TIME;
    
    // Волны пленки (работают только если ползунок больше нуля)
    float wave = sin(final_uv.y * 20.0 + time * 5.0) * tape_wave_amount;
    final_uv.x += wave;

    // Смещение цветов (Хроматическая аберрация)
    float shift = color_displacement * TEXTURE_PIXEL_SIZE.x;
    float r = texture(SCREEN_TEXTURE, final_uv + vec2(shift, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, final_uv).g;
    float b = texture(SCREEN_TEXTURE, final_uv - vec2(shift, 0.0)).b;
    vec3 color = vec3(r, g, b);

    // Мягкий шум
    float noise = hash21(final_uv + time) * noise_intensity;
    color += noise - (noise_intensity / 2.0); 

    // 2. ИСПРАВИЛИ СКАНЛАЙНЫ. Уменьшили частоту (600 вместо 900), чтобы не было мерцания пикселей (Moiré)
    float scanline = sin(final_uv.y * 600.0) * 0.01; 
    color -= scanline;

    // Обесцвечивание (для ЧБ)
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(gray), grayscale_mix);
    color *= vhs_tint;

    // 3. ИСПРАВИЛИ ЯРКОСТЬ И КОНТРАСТ!
    // Картинка стала чуть светлее и сочнее. Никакого "серого месива".
    color = color * 1.05 + 0.02; // Легкое высветление теней и поднятие общей яркости
    
    COLOR = vec4(color, 1.0);
}
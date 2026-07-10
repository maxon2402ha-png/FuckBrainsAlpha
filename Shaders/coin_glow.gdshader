shader_type spatial;
// Убрали blend_add, чтобы монета оставалась плотной и не просвечивала.
// unshaded - контур светится в темноте, не зависит от освещения уровня.
render_mode unshaded, cull_disabled;

// --- ПАРАМЕТРЫ ДЛЯ ИНСПЕКТОРА ---
uniform vec4 gold_color : source_color = vec4(1.0, 0.75, 0.1, 1.0); // Теплый золотой
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 0.9, 1.0); // Беловатый блик
uniform float brightness : hint_range(1.0, 5.0) = 2.5; // Яркость свечения! Увеличьте это значение, если нужно еще ярче.
uniform float shine_speed : hint_range(0.1, 10.0) = 2.0; // Скорость пульсации блика

void fragment() {
    // 1. Создаем аккуратный бегущий блик по вертикали (UV.y)
    float shine = sin(UV.y * 8.0 + TIME * shine_speed) * 0.5 + 0.5;
    shine = pow(shine, 8.0); // Высокая степень делает блик узким и четким
    
    // 2. Мягкий френель для псевдо-объема по краям
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
    
    // 3. Смешиваем базовый золотой цвет и блик
    vec3 final_color = mix(gold_color.rgb, shine_color.rgb, shine * 0.8);
    
    // 4. Добавляем свечение краев (Френель)
    final_color += gold_color.rgb * fresnel * 0.7;
    
    // 5. 🔥 КЛЮЧЕВОЙ МОМЕНТ: Умножаем финальный цвет на яркость! 🔥
    // Включаем свечение за счет параметра brightness.
    ALBEDO = final_color * brightness;
    
    // Монета полностью непрозрачная для лучшей видимости
    ALPHA = 1.0; 
}
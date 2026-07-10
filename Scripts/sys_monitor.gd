extends CanvasLayer

var is_active: bool = false
var monitor_label: Label
var update_timer: float = 0.0

func _ready():
	layer = 128

	monitor_label = Label.new()
	add_child(monitor_label)


	monitor_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	monitor_label.position.y = 15


	monitor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	monitor_label.add_theme_color_override("font_color", Color(0.36, 0.64, 0.84))
	monitor_label.add_theme_color_override("font_outline_color", Color.BLACK)
	monitor_label.add_theme_constant_override("outline_size", 4)
	monitor_label.add_theme_font_size_override("font_size", 18)

	visible = false


func toggle_monitor(state = null):
	if state != null:
		is_active = state
	else:
		is_active = not is_active

	visible = is_active
	if is_active:
		_update_stats()

func _process(delta: float):
	if not is_active: return

	update_timer -= delta
	if update_timer <= 0:
		_update_stats()
		update_timer = 0.5

func _update_stats():
	var fps = Engine.get_frames_per_second()
	var mem_static = OS.get_static_memory_usage() / 1048576.0
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)


	monitor_label.text = "FPS: %d   |   MEM: %.1f MB   |   DRAW CALLS: %d   |   3D OBJECTS: %d" % [fps, mem_static, draw_calls, objects]


	if fps < 30:
		monitor_label.add_theme_color_override("font_color", Color.RED)
	else:
		monitor_label.add_theme_color_override("font_color", Color(0.36, 0.64, 0.84))

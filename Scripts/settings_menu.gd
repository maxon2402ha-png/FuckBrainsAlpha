extends Control

@onready var sens_slider: Slider = $TabContainer / Gameplay / SensSlider
@onready var color_picker: ColorPickerButton = $TabContainer / Crosshair / ColorPickerButton
@onready var length_slider: Slider = $TabContainer / Crosshair / LengthSlider
@onready var gap_slider: Slider = $TabContainer / Crosshair / GapSlider

func _ready() -> void :

	if sens_slider:
		sens_slider.set_value_no_signal(Global.mouse_sensitivity)
		if not sens_slider.value_changed.is_connected(_on_sens_changed):
			sens_slider.value_changed.connect(_on_sens_changed)

	if color_picker:
		color_picker.color = Global.crosshair_color
		if not color_picker.color_changed.is_connected(_on_color_changed):
			color_picker.color_changed.connect(_on_color_changed)

	if length_slider:
		length_slider.set_value_no_signal(Global.crosshair_length)
		if not length_slider.value_changed.is_connected(_on_length_changed):
			length_slider.value_changed.connect(_on_length_changed)

	if gap_slider:
		gap_slider.set_value_no_signal(Global.crosshair_base_gap)
		if not gap_slider.value_changed.is_connected(_on_gap_changed):
			gap_slider.value_changed.connect(_on_gap_changed)

func _on_sens_changed(value: float) -> void :
	Global.mouse_sensitivity = value

func _on_color_changed(color: Color) -> void :
	Global.crosshair_color = color




func _on_length_changed(value: float) -> void :
	Global.crosshair_length = value

func _on_gap_changed(value: float) -> void :
	Global.crosshair_base_gap = value

func _on_save_button_pressed() -> void :
	if Global.has_method("save_settings"):
		Global.save_settings()

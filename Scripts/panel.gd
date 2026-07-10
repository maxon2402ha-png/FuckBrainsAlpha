extends Panel

var time = 0.0

func _process(delta):
	time += delta * 3.0

	modulate.a = (sin(time) + 1.0) / 2.0

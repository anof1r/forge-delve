extends Camera2D
## Зум колесом мыши, перемещение средней кнопкой.

const ZOOM_STEP := 1.1
const ZOOM_MIN := 0.4
const ZOOM_MAX := 2.5

var _panning := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_zoom_by(ZOOM_STEP)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_by(1.0 / ZOOM_STEP)
			MOUSE_BUTTON_MIDDLE:
				_panning = event.pressed
	elif event is InputEventMouseMotion and _panning:
		position -= event.relative / zoom.x


func _zoom_by(factor: float) -> void:
	var value := clampf(zoom.x * factor, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(value, value)

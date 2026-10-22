class_name PlaceholderTokenModel
extends TokenModel
## Плоская заглушка: цветной круг или квадрат с первой буквой имени.

const RADIUS := 18.0
const LIFT := 6.0

var _display_name := ""
var _color := Color.WHITE
var _shape := 0


func configure(display_name: String, color: Color, shape: int) -> void:
	_display_name = display_name
	_color = color
	_shape = shape
	queue_redraw()


func _draw() -> void:
	var center := Vector2(0, -RADIUS - LIFT)
	var outline := _color.darkened(0.5)
	if _shape == Token.Shape.SQUARE:
		var rect := Rect2(center - Vector2.ONE * RADIUS * 0.85, Vector2.ONE * RADIUS * 1.7)
		draw_rect(rect, _color)
		draw_rect(rect, outline, false, 2.0)
	else:
		draw_circle(center, RADIUS, _color)
		draw_arc(center, RADIUS, 0.0, TAU, 32, outline, 2.0)
	draw_string(
		ThemeDB.fallback_font, center + Vector2(-8, 8), _display_name.left(1),
		HORIZONTAL_ALIGNMENT_CENTER, 16, 22, Color.WHITE
	)

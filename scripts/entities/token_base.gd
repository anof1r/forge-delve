class_name TokenBase
extends Node2D
## Круглая подставка токена: остаётся на земле, пока модель прыгает.
## Рисует тень, подставку и кольцо выбора.

const RADIUS := 18.0
const SELECTION_COLOR := Color(1.0, 0.9, 0.3)

var selected := false:
	set(value):
		selected = value
		queue_redraw()


func _draw() -> void:
	draw_colored_polygon(IsoDraw.ellipse(RADIUS * 1.1, RADIUS * 0.55), Color(0, 0, 0, 0.35))
	draw_colored_polygon(IsoDraw.ellipse(RADIUS * 0.9, RADIUS * 0.45), Color("2b2b33"))
	if selected:
		var ring := IsoDraw.ellipse(RADIUS * 1.5, RADIUS * 0.75)
		ring.append(ring[0])
		draw_polyline(ring, SELECTION_COLOR, 3.0)

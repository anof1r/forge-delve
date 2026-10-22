class_name IsoDraw
extends RefCounted
## Помощники для рисования изометрических заглушек. Начало координат — центр клетки на земле.


static func draw_box(
	canvas: CanvasItem, tile_size: Vector2, footprint: float, height: float, top_color: Color
) -> void:
	var half_w := tile_size.x * 0.5 * footprint
	var half_h := tile_size.y * 0.5 * footprint
	var lift := Vector2(0, -height)
	var left := Vector2(-half_w, 0)
	var bottom := Vector2(0, half_h)
	var right := Vector2(half_w, 0)
	var back := Vector2(0, -half_h)
	canvas.draw_colored_polygon(
		PackedVector2Array([left, bottom, bottom + lift, left + lift]), top_color.darkened(0.35)
	)
	canvas.draw_colored_polygon(
		PackedVector2Array([bottom, right, right + lift, bottom + lift]), top_color.darkened(0.55)
	)
	canvas.draw_colored_polygon(
		PackedVector2Array([left + lift, bottom + lift, right + lift, back + lift]), top_color
	)


static func ellipse(radius_x: float, radius_y: float, points: int = 24) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points:
		var angle := TAU * i / points
		result.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return result

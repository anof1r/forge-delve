class_name CellHighlighter
extends Node2D
## Подсвечивает набор клеток (например, радиус движения).

const _FILL := Color(0.3, 0.8, 1.0, 0.28)
const _OUTLINE := Color(0.5, 0.9, 1.0, 0.8)

var grid: IsoGrid

var _cells: Array[Vector2i] = []


func show_cells(cells: Array[Vector2i]) -> void:
	_cells = cells
	queue_redraw()


func clear() -> void:
	_cells = []
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	var half := grid.tile_size * 0.5
	for cell in _cells:
		var center := to_local(grid.cell_to_world(cell))
		var diamond := PackedVector2Array([
			center + Vector2(0, -half.y), center + Vector2(half.x, 0),
			center + Vector2(0, half.y), center + Vector2(-half.x, 0),
		])
		draw_colored_polygon(diamond, _FILL)
		diamond.append(diamond[0])
		draw_polyline(diamond, _OUTLINE, 2.0)

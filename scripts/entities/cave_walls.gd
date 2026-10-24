@tool
class_name CaveWalls
extends MeshInstance3D
## Запечённая скала: визуальная сетка и логическая граница видимости.
## Непроходимость задаётся отсутствием клеток пола, а не формой треугольников.

@export_storage var sight_edges := PackedVector2Array()


func register(grid: BoardGrid) -> void:
	for index in range(0, sight_edges.size() - 1, 2):
		var a := to_global(Vector3(sight_edges[index].x, 0, sight_edges[index].y))
		var b := to_global(Vector3(sight_edges[index + 1].x, 0, sight_edges[index + 1].y))
		grid.add_sight_segment(Vector2(a.x, a.z), Vector2(b.x, b.z))

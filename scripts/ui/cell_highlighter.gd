class_name CellHighlighter
extends Node3D
## Отмечает доступные клетки плоскими красными точками.

const RADIUS := 0.075
const HEIGHT := 0.012

var grid: BoardGrid

var _pool: Array[MeshInstance3D] = []
var _material: StandardMaterial3D
var _mesh: CylinderMesh


func _init() -> void:
	_material = Mat.solid(Color("d83c3c"), 0.8)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh = CylinderMesh.new()
	_mesh.top_radius = RADIUS
	_mesh.bottom_radius = RADIUS
	_mesh.height = HEIGHT


func show_cells(cells: Array[Vector2i]) -> void:
	while _pool.size() < cells.size():
		var marker := MeshInstance3D.new()
		marker.mesh = _mesh
		marker.material_override = _material
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)
		_pool.append(marker)
	for i in _pool.size():
		var marker := _pool[i]
		marker.visible = i < cells.size()
		if marker.visible:
			marker.position = grid.cell_to_world(cells[i]) + Vector3(0, HEIGHT * 0.5 + 0.006, 0)


func clear() -> void:
	for marker in _pool:
		marker.visible = false

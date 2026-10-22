class_name CellHighlighter
extends Node3D
## Отмечает доступные клетки плоскими красными крестиками.

const ARM_LENGTH := 0.42
const ARM_WIDTH := 0.055
const HEIGHT := 0.012

var grid: BoardGrid

var _pool: Array[Node3D] = []
var _material: StandardMaterial3D
var _mesh: BoxMesh


func _init() -> void:
	_material = Mat.solid(Color("d83c3c"), 0.8)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh = BoxMesh.new()
	_mesh.size = Vector3(ARM_LENGTH, HEIGHT, ARM_WIDTH)


func show_cells(cells: Array[Vector2i]) -> void:
	while _pool.size() < cells.size():
		var marker := Node3D.new()
		for angle in [-PI * 0.25, PI * 0.25]:
			var arm := MeshInstance3D.new()
			arm.mesh = _mesh
			arm.material_override = _material
			arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			arm.rotation.y = angle
			marker.add_child(arm)
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

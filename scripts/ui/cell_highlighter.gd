class_name CellHighlighter
extends Node3D
## Подсвечивает набор клеток светящимся контуром (например, радиус движения).

const SIZE := 0.92
const HEIGHT := 0.02

const _SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 color : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float border = 0.07;

void fragment() {
	float edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float line = 1.0 - smoothstep(border * 0.5, border, edge);
	float haze = (1.0 - smoothstep(0.0, 0.35, edge)) * 0.22 + 0.06;
	ALBEDO = color.rgb * 2.5;
	ALPHA = clamp(line + haze, 0.0, 1.0);
}
"""

var grid: BoardGrid

var _pool: Array[MeshInstance3D] = []
var _material: ShaderMaterial
var _mesh: PlaneMesh


func _init() -> void:
	var shader := Shader.new()
	shader.code = _SHADER
	_material = ShaderMaterial.new()
	_material.shader = shader
	_mesh = PlaneMesh.new()
	_mesh.size = Vector2(SIZE, SIZE)


func show_cells(cells: Array[Vector2i]) -> void:
	while _pool.size() < cells.size():
		var tile := MeshInstance3D.new()
		tile.mesh = _mesh
		tile.material_override = _material
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tile)
		_pool.append(tile)
	for i in _pool.size():
		var tile := _pool[i]
		tile.visible = i < cells.size()
		if tile.visible:
			tile.position = grid.cell_to_world(cells[i]) + Vector3(0, HEIGHT, 0)


func clear() -> void:
	for tile in _pool:
		tile.visible = false

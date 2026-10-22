@tool
class_name TokenBase
extends Node3D
## Круглая подставка токена: остаётся на земле, пока модель прыгает.
## Рисует диск подставки и плоскую подсветку выбора.

const RADIUS := 0.38
const HEIGHT := 0.08

var selected := false:
	set(value):
		selected = value
		if _selection:
			_selection.visible = value

var _selection: MeshInstance3D


func _ready() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = HEIGHT
	var base := MeshInstance3D.new()
	base.mesh = disc
	base.material_override = Mat.solid(Color("2b2b33"), 0.5)
	base.position.y = HEIGHT * 0.5
	add_child(base)

	var selection_mesh := PlaneMesh.new()
	selection_mesh.size = Vector2.ONE * (RADIUS + 0.13) * 2.0
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

void fragment() {
	vec2 p = abs(UV - vec2(0.5));
	float vertical = step(0.38, p.x) * (1.0 - step(0.45, p.x))
		* step(0.25, p.y) * (1.0 - step(0.45, p.y));
	float horizontal = step(0.38, p.y) * (1.0 - step(0.45, p.y))
		* step(0.25, p.x) * (1.0 - step(0.45, p.x));
	float corners = max(vertical, horizontal);
	ALBEDO = vec3(0.84, 0.67, 0.24);
	ALPHA = corners * 0.85;
}
"""
	var selection_material := ShaderMaterial.new()
	selection_material.shader = shader
	_selection = MeshInstance3D.new()
	_selection.mesh = selection_mesh
	_selection.material_override = selection_material
	_selection.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_selection.position.y = 0.006
	_selection.visible = selected
	add_child(_selection)

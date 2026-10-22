class_name AttackProjectile
extends Node3D
## Простой визуальный снаряд для ядра дальней атаки.

const FLIGHT_DURATION := 0.3
const ARC_HEIGHT := 0.14

static var _shaft_mesh: BoxMesh
static var _head_mesh: CylinderMesh
static var _shaft_material: StandardMaterial3D
static var _head_material: StandardMaterial3D


func _init() -> void:
	_prepare_resources()
	var shaft := MeshInstance3D.new()
	shaft.mesh = _shaft_mesh
	shaft.material_override = _shaft_material
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shaft)
	var head := MeshInstance3D.new()
	head.mesh = _head_mesh
	head.material_override = _head_material
	head.position.z = -0.19
	head.rotation.x = -PI * 0.5
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head)


func fly_to(target: Vector3) -> void:
	var start := global_position
	look_at(target, Vector3.UP)
	var tween := create_tween()
	tween.tween_method(
		func(weight: float) -> void:
			var next_position := start.lerp(target, weight)
			next_position.y += sin(weight * PI) * ARC_HEIGHT
			global_position = next_position,
		0.0, 1.0, FLIGHT_DURATION
	).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	queue_free()


static func _prepare_resources() -> void:
	if _shaft_mesh != null:
		return
	_shaft_material = Mat.solid(Color("6f3f1f"), 0.7)
	_head_material = Mat.solid(Color("aeb6c2"), 0.45)
	_shaft_mesh = BoxMesh.new()
	_shaft_mesh.size = Vector3(0.018, 0.018, 0.3)
	_head_mesh = CylinderMesh.new()
	_head_mesh.top_radius = 0.0
	_head_mesh.bottom_radius = 0.035
	_head_mesh.height = 0.1

@tool
class_name Mat
extends RefCounted
## Фабрика простых материалов для заглушек. Настоящие материалы заменят эти вызовы.


static func solid(color: Color, roughness := 0.85) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


static func box(size: Vector3, offset: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	return instance

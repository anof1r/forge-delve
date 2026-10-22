@tool
class_name GlbTokenModel
extends TokenModel
## Визуал токена из импортированной модели (.glb / PackedScene).
## Сама подгоняет размер и ставит модель ногами на подставку, поэтому Meshy-модели
## с любым масштабом и точкой привязки работают без ручной настройки.

@export var model_scene: PackedScene
@export var target_height := 0.9


func configure(_display_name: String, _color: Color, _shape: int) -> void:
	for child in get_children():
		child.queue_free()
	if model_scene == null:
		return

	var pivot := Node3D.new()
	add_child(pivot)
	var instance := model_scene.instantiate() as Node3D
	pivot.add_child(instance)

	var bounds := _bounds(instance, pivot)
	if bounds.size.y <= 0.0:
		return
	var factor := target_height / bounds.size.y
	var bottom_center := Vector3(
		bounds.position.x + bounds.size.x * 0.5,
		bounds.position.y,
		bounds.position.z + bounds.size.z * 0.5
	)
	pivot.scale = Vector3.ONE * factor
	pivot.position = -bottom_center * factor


## AABB всех мешей модели в системе координат pivot (до масштабирования).
func _bounds(root: Node, pivot: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			var local: Transform3D = pivot.global_transform.affine_inverse() * mesh_node.global_transform
			var box: AABB = local * mesh_node.get_aabb()
			result = box if first else result.merge(box)
			first = false
	return result

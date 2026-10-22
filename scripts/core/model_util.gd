@tool
class_name ModelUtil
extends RefCounted
## Помощники для импортированных 3D-моделей.


## AABB всех мешей модели в системе координат родителя root (с учётом transform самого root).
## Работает без добавления в дерево сцены.
static func bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [[root, root.transform]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node3D = item[0]
		var xform: Transform3D = item[1]
		if node is MeshInstance3D:
			var box: AABB = xform * (node as MeshInstance3D).get_aabb()
			result = box if first else result.merge(box)
			first = false
		for child in node.get_children():
			if child is Node3D:
				stack.append([child, xform * (child as Node3D).transform])
	return result

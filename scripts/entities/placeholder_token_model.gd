@tool
class_name PlaceholderTokenModel
extends TokenModel
## Заглушка-миниатюра из примитивов: пешка для игроков, куб с рогами для мобов.


func configure(display_name: String, color: Color, shape: int) -> void:
	for child in get_children():
		child.queue_free()

	var material := Mat.solid(color, 0.55)
	if shape == Token.Shape.SQUARE:
		add_child(Mat.box(Vector3(0.5, 0.55, 0.5), Vector3(0, 0.275, 0), material))
		add_child(_horns(color))
	else:
		var body := CylinderMesh.new()
		body.top_radius = 0.14
		body.bottom_radius = 0.26
		body.height = 0.55
		add_child(_mesh(body, Vector3(0, 0.275, 0), material))
		var head := SphereMesh.new()
		head.radius = 0.17
		head.height = 0.34
		add_child(_mesh(head, Vector3(0, 0.68, 0), material))

	var label := Label3D.new()
	label.text = display_name.left(1)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 72
	label.pixel_size = 0.006
	label.outline_size = 16
	label.position = Vector3(0, 1.1, 0)
	add_child(label)


func _horns(color: Color) -> Node3D:
	var horns := Node3D.new()
	var material := Mat.solid(color.lightened(0.35), 0.6)
	for side in [-1.0, 1.0]:
		horns.add_child(Mat.box(Vector3(0.1, 0.22, 0.1), Vector3(0.18 * side, 0.66, 0), material))
	return horns


func _mesh(mesh: Mesh, offset: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = offset
	return instance

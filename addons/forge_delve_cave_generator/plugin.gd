@tool
extends EditorPlugin

var _panel: VBoxContainer
var _width: SpinBox
var _depth: SpinBox
var _seed: SpinBox
var _chambers: SpinBox
var _passage: SpinBox
var _height: SpinBox
var _status: Label


func _enter_tree() -> void:
	_panel = VBoxContainer.new()
	_panel.name = "Пещеры"
	_panel.custom_minimum_size.x = 240
	var instructions := Label.new()
	instructions.text = "Создайте пустую 3D-сцену.\nСгенерируйте пещеру и сохраните Ctrl+S.\nОтмена генерации: Ctrl+Z."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(instructions)
	_width = _field("Ширина (клетки)", 16, 64, 32)
	_depth = _field("Длина (клетки)", 16, 64, 24)
	_seed = _field("Seed", 0, 2147483647, 4271)
	_chambers = _field("Количество полостей", 2, 12, 5)
	_passage = _field("Ширина проходов (клетки)", 2, 5, 2)
	_height = _field("Высота скалы", 0.6, 4.0, 1.6, 0.1)
	var randomize_button := Button.new()
	randomize_button.text = "Другой seed"
	randomize_button.pressed.connect(func() -> void: _seed.value = randi_range(0, 2147483647))
	_panel.add_child(randomize_button)
	var generate_button := Button.new()
	generate_button.text = "Сгенерировать пещеру"
	generate_button.pressed.connect(_generate)
	_panel.add_child(generate_button)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_status)
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _panel)
	scene_changed.connect(_scene_changed)
	_scene_changed(EditorInterface.get_edited_scene_root())


func _exit_tree() -> void:
	scene_changed.disconnect(_scene_changed)
	remove_control_from_docks(_panel)
	_panel.queue_free()


func _field(title: String, minimum: float, maximum: float, initial: float, step := 1.0) -> SpinBox:
	var label := Label.new()
	label.text = title
	_panel.add_child(label)
	var field := SpinBox.new()
	field.min_value = minimum
	field.max_value = maximum
	field.step = step
	field.value = initial
	_panel.add_child(field)
	return field


func _scene_changed(root: Node) -> void:
	_status.text = ""
	if root == null or not root.has_meta("cave_settings"):
		return
	var settings: Dictionary = root.get_meta("cave_settings")
	var size: Vector2i = settings["size"]
	_width.value = size.x
	_depth.value = size.y
	_seed.value = settings["seed"]
	_chambers.value = settings["chambers"]
	_passage.value = settings["passage_width"]
	_height.value = settings["wall_height"]


func _generate() -> void:
	var root := EditorInterface.get_edited_scene_root() as Node3D
	if root == null or root.transform != Transform3D.IDENTITY:
		_status.text = "Нужна 3D-сцена с корнем Node3D без смещения, вращения и масштаба."
		return
	if root.get_child_count() > 0 and not root.has_meta("cave_settings"):
		_status.text = "Откройте новую пустую 3D-сцену. Существующий уровень не заменяется."
		return
	# После ручной расстановки лучше генерировать новый уровень отдельно:
	# мебель и персонажи могут оказаться внутри скалы нового плана.
	for group in ["Props", "Tokens"]:
		var content := root.get_node_or_null(group)
		if content != null and content.get_child_count() > 0:
			_status.text = "В сцене уже есть предметы или фигуры. Для новой пещеры создайте пустую 3D-сцену."
			return
	var layout := CaveLayout.generate(Vector2i(int(_width.value), int(_depth.value)),
		int(_seed.value), int(_chambers.value), int(_passage.value))
	var generated := CaveBuilder.build(layout, _height.value)
	var fresh := generated.get_children()
	for child in fresh:
		_clear_owners(child)
		generated.remove_child(child)
	var previous: Array[Node] = []
	for group in ["Floor", "Walls", "Props", "Tokens"]:
		var child := root.get_node_or_null(group)
		if child != null:
			previous.append(child)
	var undo := get_undo_redo()
	var previous_settings: Variant = root.get_meta("cave_settings") if root.has_meta("cave_settings") else null
	undo.create_action("Сгенерировать пещеру", UndoRedo.MERGE_DISABLE, root)
	undo.add_do_method(self, "_replace", root, previous, fresh, generated.get_meta("cave_settings"))
	undo.add_undo_method(self, "_replace", root, fresh, previous, previous_settings)
	for child in fresh:
		undo.add_do_reference(child)
	for child in previous:
		undo.add_undo_reference(child)
	undo.commit_action()
	generated.free()
	_status.text = "Готово: %d клеток. Ctrl+S — сохранить .tscn.\nДля игры назначьте сцену в поле Dungeon → Level." % layout["cells"].size()
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(root.get_node("Walls/Rock"))


func _replace(root: Node, removed: Array[Node], added: Array[Node], settings: Variant) -> void:
	for child in removed:
		_clear_owners(child)
		root.remove_child(child)
	for child in added:
		root.add_child(child)
		child.owner = root
		# Внутренние модели Tile создаёт сам; не запекаем их второй раз.
		for entity in child.get_children():
			entity.owner = root
	if settings == null:
		root.remove_meta("cave_settings")
	else:
		root.set_meta("cave_settings", settings)
	_scene_changed(root)


func _clear_owners(container: Node) -> void:
	for entity in container.get_children():
		entity.owner = null
	container.owner = null

@tool
class_name Prop
extends Node3D

const FIRE_SCENE := preload("res://scenes/effects/fire_particles.tscn")
## Предмет окружения (стул, сундук, стол, факел...). Модель берётся из PropCatalog.
## Узел можно ставить в сцену уровня и править в инспекторе: положение считается
## из полей cell / rotation_steps / snap / elevation / offset, в том числе в редакторе.
##
## Поворот rotation_steps: 0 — «лицом» к +Z (юг, растёт y клетки), 1 — к +X (восток),
## 2 — к -Z (север), 3 — к -X (запад).

@export var prop_id := "":
	set(value):
		prop_id = value
		_rebuild()
## Левый верхний угол занимаемых клеток.
@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		_rebuild()
@export_range(0, 3) var rotation_steps := 0:
	set(value):
		rotation_steps = posmod(value, 4)
		_rebuild()
## Прижать заднюю грань модели к стене с её стороны.
@export var snap := false:
	set(value):
		snap = value
		_rebuild()
## Высота над полом (предметы на столе, настенные светильники).
@export var elevation := 0.0:
	set(value):
		elevation = value
		_rebuild()
## Смещение внутри клетки в мировых единицах (x, z до поворота).
@export var offset := Vector2.ZERO:
	set(value):
		offset = value
		_rebuild()
## Сохранять Transform узла для точной ручной расстановки; блокировка считается от него.
@export var use_manual_transform := false
## Переопределить блокировку хода из каталога: -1 — как в каталоге, 0 — нет, 1 — да.
@export_range(-1, 1) var blocks_override := -1:
	set(value):
		blocks_override = value
		_rebuild()

var _footprint := Vector2i.ONE  # уже с учётом поворота

static func create(prop_id_: String, cell_: Vector2i, steps := 0, options := {}) -> Prop:
	var prop := Prop.new()
	prop.name = prop_id_
	prop.prop_id = prop_id_
	prop.cell = cell_
	prop.rotation_steps = steps
	prop.snap = options.get("snap", false)
	prop.elevation = options.get("elevation", 0.0)
	prop.offset = options.get("offset", Vector2.ZERO)
	if options.has("blocks"):
		prop.blocks_override = 1 if options["blocks"] else 0
	return prop


func _ready() -> void:
	_rebuild()


func blocks_movement() -> bool:
	if blocks_override >= 0:
		return blocks_override == 1
	return PropCatalog.entry(prop_id)["blocks"]


func occupied_cells() -> Array[Vector2i]:
	var origin := cell
	var footprint := _footprint
	if use_manual_transform and not snap:
		var base: Vector2i = PropCatalog.entry(prop_id)["footprint"]
		var manual_steps := posmod(roundi(rotation.y / (PI * 0.5)), 4)
		footprint = Vector2i(base.y, base.x) if manual_steps % 2 == 1 else base
		var center := Vector2(global_position.x, global_position.z) / BoardGrid.CELL_SIZE
		var half_span := Vector2(footprint - Vector2i.ONE) * 0.5
		origin = Vector2i(roundi(center.x - half_span.x), roundi(center.y - half_span.y))
	var cells: Array[Vector2i] = []
	for x in footprint.x:
		for y in footprint.y:
			cells.append(origin + Vector2i(x, y))
	return cells


## Закрывает занимаемые клетки для движения. Вызывает Dungeon при загрузке уровня.
func register(grid: BoardGrid) -> void:
	if not blocks_movement():
		return
	for occupied in occupied_cells():
		if not grid.has_floor(occupied) or grid.has_wall(occupied):
			push_warning("Prop %s at %s overlaps a wall or has no floor" % [prop_id, occupied])
		grid.add_blocker(occupied)


func _rebuild() -> void:
	if not is_inside_tree() or prop_id.is_empty():
		return
	var saved_transform := transform
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var entry := PropCatalog.entry(prop_id)
	var base: Vector2i = entry["footprint"]
	_footprint = Vector2i(base.y, base.x) if rotation_steps % 2 == 1 else base

	var model := _load_model()
	if model == null:
		return
	model.scale = Vector3.ONE * float(entry["scale"])
	add_child(model)

	var center := Vector3(cell.x, 0.0, cell.y) * BoardGrid.CELL_SIZE \
		+ Vector3(_footprint.x - 1, 0.0, _footprint.y - 1) * BoardGrid.CELL_SIZE * 0.5
	var shift := Vector3(offset.x, elevation, offset.y)
	if snap:
		shift.z += -base.y * BoardGrid.CELL_SIZE * 0.5 - ModelUtil.bounds(model).position.z

	rotation.y = rotation_steps * PI * 0.5
	position = center + Basis(Vector3.UP, rotation.y) * shift
	if use_manual_transform:
		transform = saved_transform

	if entry.has("light"):
		_add_light(entry["light"])


func _load_model() -> Node3D:
	var path := PropCatalog.model_path(prop_id)
	if not ResourceLoader.exists(path):
		push_error("Prop model not found: " + path)
		return null
	return (load(path) as PackedScene).instantiate() as Node3D


func _add_light(spec: Dictionary) -> void:
	var color: Color = spec["color"]
	var light_position: Vector3 = spec["offset"]
	var flame_radius: float = spec.get("flame", 0.0)
	if flame_radius > 0.0:
		_add_fire_particles(light_position, flame_radius)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = spec["energy"]
	light.omni_range = spec["range"]
	light.shadow_enabled = spec.get("shadow", false)
	light.position = light_position
	add_child(light)


func _add_fire_particles(at: Vector3, radius: float) -> void:
	var particles := FIRE_SCENE.instantiate() as CPUParticles3D
	particles.position = at
	particles.scale = Vector3.ONE * (radius / 0.07)
	add_child(particles)

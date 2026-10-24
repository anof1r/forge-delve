@tool
class_name Tile
extends Node3D
## Редактируемая модульная плитка пола или стены.

const CORNER_ARM_LENGTH := 0.25

@export_enum("Floor", "Wall") var kind := TileCatalog.FLOOR:
	set(value):
		kind = value
		_rebuild()
@export var model_id := "floor_stone":
	set(value):
		model_id = value
		_rebuild()
@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		_rebuild()
@export_range(0, 3) var rotation_steps := 0:
	set(value):
		rotation_steps = posmod(value, 4)
		_rebuild()
@export_range(0, 32) var variant := 0:
	set(value):
		variant = maxi(value, 0)
		_rebuild()
@export_range(0.01, 4.0, 0.01) var scale_multiplier := 1.0:
	set(value):
		scale_multiplier = maxf(value, 0.01)
		_rebuild()
@export_range(-1, 1) var blocks_override := -1
## Элемент создан конструктором комнат и может перестраиваться им.
@export_storage var automatic := false
## Визуальное смещение внутри логической клетки; используется для стыков углов.
@export_storage var placement_offset := Vector2.ZERO:
	set(value):
		placement_offset = value
		_rebuild()
## Не меняет размер логической клетки, только растягивает модель внутри контура.
@export_storage var model_scale := Vector3.ONE:
	set(value):
		model_scale = value
		_rebuild()


static func create(kind_: int, model_id_: String, cell_: Vector2i, steps := 0, variant_ := 0, placement_offset_ := Vector2.ZERO, model_scale_ := Vector3.ONE) -> Tile:
	var tile := Tile.new()
	tile.kind = kind_
	tile.model_id = model_id_
	tile.cell = cell_
	tile.rotation_steps = steps
	tile.variant = variant_
	tile.placement_offset = placement_offset_
	tile.model_scale = model_scale_
	return tile


func _ready() -> void:
	_rebuild()


func blocks_movement() -> bool:
	if blocks_override >= 0:
		return blocks_override == 1
	return TileCatalog.entry(model_id, kind)["blocks"]


func register(grid: BoardGrid) -> void:
	if kind == TileCatalog.WALL and blocks_movement():
		grid.add_wall(cell)
		var center := Vector2(cell.x + placement_offset.x, cell.y + placement_offset.y) * BoardGrid.CELL_SIZE
		if model_id.begins_with("wall_corner_exterior"):
			var arms: Array[Vector2] = _corner_arms()
			for arm: Vector2 in arms:
				grid.add_sight_segment(center, center + arm * CORNER_ARM_LENGTH * BoardGrid.CELL_SIZE)
			return
		var axis := Vector2.RIGHT if rotation_steps % 2 == 0 else Vector2.DOWN
		var half_length := model_scale.x * BoardGrid.CELL_SIZE * 0.5
		grid.add_sight_segment(center - axis * half_length, center + axis * half_length)
	else:
		grid.add_floor(cell)


func _corner_arms() -> Array[Vector2]:
	var base: Array[Vector2] = [Vector2.LEFT, Vector2.DOWN]
	var result: Array[Vector2] = []
	var angle := rotation_steps * PI * 0.5
	for arm: Vector2 in base:
		result.append(arm.rotated(-angle).round())
	return result


func _rebuild() -> void:
	if not is_inside_tree() or model_id.is_empty():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var path := TileCatalog.model_path(model_id, variant, kind)
	if not ResourceLoader.exists(path):
		push_error("Tile model not found: " + path)
		return
	var model := (load(path) as PackedScene).instantiate() as Node3D
	var spec := TileCatalog.entry(model_id, kind)
	model.scale = Vector3.ONE * float(spec["scale"]) * scale_multiplier * model_scale
	add_child(model)

	rotation.y = rotation_steps * PI * 0.5
	position = Vector3(cell.x, 0.0, cell.y) * BoardGrid.CELL_SIZE \
		+ Vector3(placement_offset.x, 0.0, placement_offset.y) * BoardGrid.CELL_SIZE
	model.position = spec.get("offset", Vector3.ZERO)

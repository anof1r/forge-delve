@tool
class_name Tile
extends Node3D
## Редактируемая модульная плитка пола или стены.

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


static func create(kind_: int, model_id_: String, cell_: Vector2i, steps := 0, variant_ := 0) -> Tile:
	var tile := Tile.new()
	tile.kind = kind_
	tile.model_id = model_id_
	tile.cell = cell_
	tile.rotation_steps = steps
	tile.variant = variant_
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
	else:
		grid.add_floor(cell)


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
	model.scale = Vector3.ONE * float(spec["scale"]) * scale_multiplier
	add_child(model)

	rotation.y = rotation_steps * PI * 0.5
	position = Vector3(cell.x, 0.0, cell.y) * BoardGrid.CELL_SIZE
	model.position = spec.get("offset", Vector3.ZERO)

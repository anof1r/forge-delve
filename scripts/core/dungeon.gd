class_name Dungeon
extends Node3D
## Корень игровой карты и «авторитет» над ней: создание контента и валидация ходов.
## Любое изменение мира проходит через методы этого узла — это единая точка, куда
## позже подключится сеть (клиент шлёт запрос, сервер вызывает request_move()).

@export var level: PackedScene

@onready var grid: BoardGrid = $Grid
@onready var floor_root: Node3D = $Floor
@onready var wall_root: Node3D = $Walls
@onready var prop_root: Node3D = $Props
@onready var token_root: Node3D = $Tokens
@onready var highlights: CellHighlighter = $Highlights
@onready var controller: DungeonController = $Controller
@onready var rig: CameraRig = $CameraRig
@onready var hud: Hud = $Hud

func _ready() -> void:
	highlights.grid = grid
	controller.setup(self, grid, highlights, rig)
	hud.role_changed.connect(controller.set_role)

	if level:
		_load_level(level.instantiate())

	var rect := grid.used_rect()
	var center := grid.cell_to_world(rect.position) + grid.cell_to_world(rect.size - Vector2i.ONE) * 0.5
	rig.frame(center, maxf(rect.size.x, rect.size.y))


# --- Построение уровня -----------------------------------------------------

func add_floor(cell: Vector2i) -> void:
	if grid.has_floor(cell):
		return
	var tile := Tile.create(TileCatalog.FLOOR, "floor_stone", cell, 0, posmod(cell.x + cell.y, 2))
	floor_root.add_child(tile)
	tile.register(grid)


func add_wall(cell: Vector2i, rotation_steps := 0) -> void:
	add_floor(cell)
	if grid.has_wall(cell):
		return
	var tile := Tile.create(TileCatalog.WALL, "wall_stone", cell, rotation_steps)
	wall_root.add_child(tile)
	tile.register(grid)


func add_prop(prop_id: String, cell: Vector2i, rotation_steps := 0, options := {}) -> Prop:
	var prop := Prop.create(prop_id, cell, rotation_steps, options)
	prop_root.add_child(prop)
	prop.register(grid)
	return prop


## Сцена уровня (редактируется в редакторе) — корень с узлами Floor, Walls, Props, Tokens.
## Tile сам регистрирует тип и блокировку; старые Node3D читаются по позиции для совместимости.
func _load_level(level_root: Node3D) -> void:
	for tile: Node3D in level_root.get_node("Floor").get_children():
		if tile is Tile:
			tile.register(grid)
		else:
			grid.add_floor(grid.world_to_cell(tile.position))
	for tile: Node3D in level_root.get_node("Walls").get_children():
		if tile is Tile:
			tile.register(grid)
		else:
			grid.add_wall(grid.world_to_cell(tile.position))
	add_child(level_root)
	for prop: Node in level_root.get_node("Props").get_children():
		if prop is Prop:
			prop.register(grid)
	var level_tokens := level_root.get_node_or_null("Tokens")
	if level_tokens:
		for child: Node in level_tokens.get_children():
			if child is Token:
				level_tokens.remove_child(child)
				add_token(child, child.cell)


func add_token(token: Token, cell: Vector2i) -> void:
	if not grid.is_free(cell):
		push_error("Cannot add token %s to unavailable cell %s" % [token.display_name, cell])
		return
	token_root.add_child(token)
	if not token.place(grid, cell):
		token_root.remove_child(token)
		push_error("Could not register token %s at %s" % [token.display_name, cell])


# --- Действия --------------------------------------------------------------

## Двигает токен в пределах его радиуса. Использовать через await.
func request_move(token: Token, target: Vector2i) -> bool:
	if grid.get_occupant(token.cell) != token or token.is_moving or target == token.cell:
		return false
	var reach := grid.reachable(token.cell, token.move_radius)
	if not reach.has(target):
		return false
	if not await token.move_along(grid.path_to(reach, target)):
		return false
	var opponent := _nearest_adjacent_opponent(token)
	if opponent != null:
		await token.face_cell(opponent.cell)
	return true


func _nearest_adjacent_opponent(token: Token) -> Token:
	var nearest: Token
	var nearest_distance := INF
	for candidate: Token in grid.occupants():
		if candidate == token or candidate.team == token.team:
			continue
		var delta := candidate.cell - token.cell
		if absi(delta.x) > 1 or absi(delta.y) > 1:
			continue
		var distance := delta.length_squared()
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

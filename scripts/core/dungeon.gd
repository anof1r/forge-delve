class_name Dungeon
extends Node3D
## Корень игровой карты и «авторитет» над ней: создание контента и валидация ходов.
## Любое изменение мира проходит через методы этого узла — это единая точка, куда
## позже подключится сеть (клиент шлёт запрос, сервер вызывает request_move()).

const FLOOR_THICKNESS := 0.2
const WALL_HEIGHT := 1.0

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

var _floor_materials: Array[Material] = [
	Mat.solid(Color("4b505a"), 0.9), Mat.solid(Color("40444d"), 0.9),
]
var _wall_material := Mat.solid(Color("8c8279"), 0.85)


func _ready() -> void:
	highlights.grid = grid
	controller.setup(self, grid, highlights, rig)
	hud.role_changed.connect(controller.set_role)

	if level:
		_load_level(level.instantiate())
	DemoLevel.spawn_tokens(self)

	var rect := grid.used_rect()
	var center := grid.cell_to_world(rect.position) + grid.cell_to_world(rect.size - Vector2i.ONE) * 0.5
	rig.frame(center, maxf(rect.size.x, rect.size.y))


# --- Построение уровня -----------------------------------------------------

func add_floor(cell: Vector2i) -> void:
	if grid.has_floor(cell):
		return
	grid.add_floor(cell)
	var material := _floor_materials[posmod(cell.x + cell.y, 2)]  # шахматный узор
	var size := Vector3(BoardGrid.CELL_SIZE, FLOOR_THICKNESS, BoardGrid.CELL_SIZE)
	var tile := Mat.box(size, grid.cell_to_world(cell) + Vector3(0, -FLOOR_THICKNESS * 0.5, 0), material)
	floor_root.add_child(tile)


func add_wall(cell: Vector2i) -> void:
	add_floor(cell)
	if grid.has_wall(cell):
		return
	grid.add_wall(cell)
	var size := Vector3(BoardGrid.CELL_SIZE, WALL_HEIGHT, BoardGrid.CELL_SIZE)
	wall_root.add_child(Mat.box(size, grid.cell_to_world(cell) + Vector3(0, WALL_HEIGHT * 0.5, 0), _wall_material))


func add_prop(prop_id: String, cell: Vector2i, rotation_steps := 0, options := {}) -> Prop:
	var prop := Prop.create(prop_id, cell, rotation_steps, options)
	prop_root.add_child(prop)
	prop.register(grid)
	return prop


## Сцена уровня (редактируется в редакторе) — корень с узлами Floor, Walls, Props.
## Клетки пола и стен берутся из положения плиток, пропы блокируют свои клетки.
func _load_level(level_root: Node3D) -> void:
	for tile: Node3D in level_root.get_node("Floor").get_children():
		grid.add_floor(grid.world_to_cell(tile.position))
	for tile: Node3D in level_root.get_node("Walls").get_children():
		grid.add_wall(grid.world_to_cell(tile.position))
	add_child(level_root)
	for prop: Node in level_root.get_node("Props").get_children():
		if prop is Prop:
			prop.register(grid)


func add_token(token: Token, cell: Vector2i) -> void:
	token_root.add_child(token)
	token.place(grid, cell)


# --- Действия --------------------------------------------------------------

## Двигает токен в пределах его радиуса. Использовать через await.
func request_move(token: Token, target: Vector2i) -> bool:
	if token.is_moving or target == token.cell:
		return false
	var reach := grid.reachable(token.cell, token.move_radius)
	if not reach.has(target):
		return false
	await token.move_along(grid.path_to(reach, target))
	return true

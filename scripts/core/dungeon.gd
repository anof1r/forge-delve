class_name Dungeon
extends Node2D
## Корень игровой карты и «авторитет» над ней: создание контента и валидация ходов.
## Любое изменение мира проходит через методы этого узла — это единая точка, куда
## позже подключится сеть (клиент шлёт запрос, сервер вызывает request_move()).

@onready var grid: IsoGrid = $IsoGrid
@onready var floor_layer: TileMapLayer = $Floor
@onready var highlights: CellHighlighter = $Highlights
@onready var world: Node2D = $World  # y_sort_enabled: стены, пропы и токены сортируются вместе
@onready var wall_layer: TileMapLayer = $World/Walls
@onready var controller: DungeonController = $Controller
@onready var camera: Camera2D = $Camera2D
@onready var hud: Hud = $Hud


func _ready() -> void:
	var tile_set := PlaceholderTileset.build()
	floor_layer.tile_set = tile_set
	wall_layer.tile_set = tile_set
	grid.setup(floor_layer, wall_layer)
	highlights.grid = grid
	controller.setup(self, grid, highlights)
	hud.role_changed.connect(controller.set_role)

	DemoLevel.build(self)

	camera.position = grid.cell_to_world(grid.used_rect().get_center())
	_fit_camera_to_map()


func _fit_camera_to_map() -> void:
	var rect := grid.used_rect()
	var corners := [
		rect.position, rect.position + Vector2i(rect.size.x, 0),
		rect.position + Vector2i(0, rect.size.y), rect.end,
	]
	var bounds := Rect2(grid.cell_to_world(rect.position), Vector2.ZERO)
	for corner: Vector2i in corners:
		bounds = bounds.expand(grid.cell_to_world(corner))
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / bounds.size.x, viewport_size.y / bounds.size.y) * 0.9
	camera.zoom = Vector2.ONE * clampf(fit, 0.4, 1.0)


# --- Построение уровня -----------------------------------------------------

func add_floor(cell: Vector2i) -> void:
	var variant := posmod(cell.x + cell.y, 2)  # шахматный узор
	floor_layer.set_cell(cell, PlaceholderTileset.SOURCE_FLOOR, Vector2i(variant, 0))


func add_wall(cell: Vector2i) -> void:
	add_floor(cell)
	wall_layer.set_cell(cell, PlaceholderTileset.SOURCE_WALL, Vector2i.ZERO)


func add_prop(prop: Prop, cell: Vector2i) -> void:
	world.add_child(prop)
	prop.place(grid, cell)


func add_token(token: Token, cell: Vector2i) -> void:
	world.add_child(token)
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

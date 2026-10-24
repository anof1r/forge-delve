class_name Dungeon
extends Node3D
## Корень игровой карты и «авторитет» над ней: создание контента и валидация ходов.
## Любое изменение мира проходит через методы этого узла — это единая точка, куда
## позже подключится сеть (клиент шлёт запрос, сервер вызывает request_move/request_attack).

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
	add_floor_tile(cell, "floor_stone", posmod(cell.x + cell.y, 2))


func add_floor_tile(cell: Vector2i, model_id := "floor_stone", variant := 0) -> void:
	var existing := _tile_at(floor_root, cell)
	if existing != null:
		if existing.model_id == model_id and existing.variant == variant:
			return
		floor_root.remove_child(existing)
		existing.queue_free()
	var tile := Tile.create(TileCatalog.FLOOR, model_id, cell, 0, variant)
	floor_root.add_child(tile)
	tile.register(grid)


func add_wall(cell: Vector2i, rotation_steps := 0) -> void:
	add_wall_tile(cell, "wall_stone", rotation_steps)


func add_wall_tile(cell: Vector2i, model_id := "wall_stone", rotation_steps := 0, automatic := false) -> void:
	_remove_tiles_at(wall_root, cell)
	_create_wall_tile(cell, model_id, rotation_steps, automatic)
	_resolve_wall_junctions()
	_rebuild_grid()


func _create_wall_tile(cell: Vector2i, model_id: String, rotation_steps: int, automatic: bool, placement_offset := Vector2.ZERO, model_scale := Vector3.ONE) -> void:
	var tile := Tile.create(TileCatalog.WALL, model_id, cell, rotation_steps, 0, placement_offset, model_scale)
	tile.automatic = automatic
	wall_root.add_child(tile)


func add_prop(prop_id: String, cell: Vector2i, rotation_steps := 0, options := {}) -> Prop:
	var prop := Prop.create(prop_id, cell, rotation_steps, options)
	prop_root.add_child(prop)
	prop.register(grid)
	return prop


func remove_floor(cell: Vector2i) -> void:
	_remove_tiles_at(floor_root, cell)
	_remove_tiles_at(wall_root, cell)
	_rebuild_grid()


func remove_wall(cell: Vector2i) -> void:
	_remove_tiles_at(wall_root, cell)
	_resolve_wall_junctions()
	_rebuild_grid()


func remove_prop(prop: Prop) -> void:
	if prop == null or prop.get_parent() != prop_root:
		return
	prop_root.remove_child(prop)
	prop.queue_free()
	_rebuild_grid()


func remove_token(token: Token) -> void:
	if token == null or token.get_parent() != token_root:
		return
	token_root.remove_child(token)
	token.queue_free()
	_rebuild_grid()


func token_at(cell: Vector2i) -> Token:
	return grid.get_occupant(cell)


## Находит логическую клетку блокировки рядом с точным визуальным положением.
## Это позволяет придвинуть мебель к тонкой геометрии стены, не помещая её
## логический blocker в клетку стены.
func nearest_prop_anchor(prop_id: String, world_position: Vector3, rotation_steps: int) -> Variant:
	var raw_cell := grid.world_to_cell(world_position)
	var footprint: Vector2i = PropCatalog.entry(prop_id)["footprint"]
	if rotation_steps % 2 == 1:
		footprint = Vector2i(footprint.y, footprint.x)
	var half_span := Vector3(footprint.x - 1, 0.0, footprint.y - 1) * BoardGrid.CELL_SIZE * 0.5
	var best: Variant
	var best_distance := INF
	for x in range(-2, 3):
		for y in range(-2, 3):
			var candidate := raw_cell + Vector2i(x, y)
			if not _can_anchor_transformed_prop(prop_id, candidate, rotation_steps):
				continue
			var center := grid.cell_to_world(candidate) + half_span
			var distance := Vector2(center.x, center.z).distance_squared_to(Vector2(world_position.x, world_position.z))
			if distance < best_distance:
				best = candidate
				best_distance = distance
	return best if best_distance <= 0.8 * 0.8 else null


## Точная расстановка допускает пересечение мебели (например, стул под столом).
## Для игрового грида их blockers объединяются в тех же клетках.
func _can_anchor_transformed_prop(prop_id: String, cell: Vector2i, rotation_steps: int) -> bool:
	var footprint: Vector2i = PropCatalog.entry(prop_id)["footprint"]
	if rotation_steps % 2 == 1:
		footprint = Vector2i(footprint.y, footprint.x)
	for x in footprint.x:
		for y in footprint.y:
			var occupied := cell + Vector2i(x, y)
			if not grid.has_floor(occupied) or grid.has_wall(occupied):
				return false
			var occupant := token_at(occupied)
			if occupant != null:
				return false
	return true


## Сцена уровня (редактируется в редакторе) — корень с узлами Floor, Walls, Props, Tokens.
## Tile сам регистрирует тип и блокировку; старые Node3D читаются по позиции для совместимости.
func _load_level(level_root: Node3D) -> void:
	add_child(level_root)
	_move_level_children(level_root.get_node_or_null("Floor"), floor_root)
	_move_level_children(level_root.get_node_or_null("Walls"), wall_root)
	_move_level_children(level_root.get_node_or_null("Props"), prop_root)
	_move_level_children(level_root.get_node_or_null("Tokens"), token_root)
	remove_child(level_root)
	level_root.queue_free()
	_resolve_wall_junctions()
	_rebuild_grid()
	_normalize_manual_prop_anchors()


func _move_level_children(source: Node, destination: Node) -> void:
	if source == null:
		return
	for child: Node in source.get_children():
		child.reparent(destination)


func _remove_tiles_at(root: Node, cell: Vector2i) -> void:
	for child: Node in root.get_children():
		if child is Tile and (child as Tile).cell == cell:
			root.remove_child(child)
			child.queue_free()


func _tile_at(root: Node, cell: Vector2i) -> Tile:
	for child: Node in root.get_children():
		if child is Tile and (child as Tile).cell == cell:
			return child as Tile
	return null


func _rebuild_grid() -> void:
	grid.clear()
	for child: Node in floor_root.get_children():
		if child is Tile:
			(child as Tile).register(grid)
		elif child is Node3D:
			grid.add_floor(grid.world_to_cell((child as Node3D).position))
	for child: Node in wall_root.get_children():
		if child is Tile:
			(child as Tile).register(grid)
		elif child is CaveWalls:
			(child as CaveWalls).register(grid)
		elif child is Node3D:
			grid.add_wall(grid.world_to_cell((child as Node3D).position))
	for child: Node in prop_root.get_children():
		if child is Prop:
			(child as Prop).register(grid)
	for child: Node in token_root.get_children():
		if child is Token:
			(child as Token).place(grid, (child as Token).cell)


## Обновляет старые сохранения, где точное положение мебели уже изменилось,
## а её логическая клетка осталась прежней.
func _normalize_manual_prop_anchors() -> void:
	var changed := false
	for child: Node in prop_root.get_children():
		if child is not Prop:
			continue
		var prop := child as Prop
		if not prop.use_manual_transform or prop.snap or not prop.blocks_movement():
			continue
		var steps := posmod(roundi(prop.rotation.y / (PI * 0.5)), 4)
		var anchor: Variant = nearest_prop_anchor(prop.prop_id, prop.position, steps)
		if anchor != null and prop.cell != anchor:
			prop.cell = anchor
			changed = true
	if changed:
		_rebuild_grid()


## Две прямые стены в одной угловой клетке не должны проходить друг сквозь друга.
## Каждая занимает половину клетки от центра стыка до своего продолжения.
func _resolve_wall_junctions() -> void:
	var walls_by_cell: Dictionary = {}
	for child: Node in wall_root.get_children():
		if child is not Tile:
			continue
		var tile := child as Tile
		if tile.kind != TileCatalog.WALL:
			continue
		if not walls_by_cell.has(tile.cell):
			walls_by_cell[tile.cell] = []
		(walls_by_cell[tile.cell] as Array).append(tile)

	for cell: Vector2i in walls_by_cell:
		var cell_walls: Array = walls_by_cell[cell]
		if not _has_perpendicular_pair(cell_walls):
			continue
		for value: Variant in cell_walls:
			var tile := value as Tile
			var axis := Vector2i.RIGHT if tile.rotation_steps % 2 == 0 else Vector2i.DOWN
			var has_negative := _has_parallel_wall(walls_by_cell, cell - axis, tile.rotation_steps)
			var has_positive := _has_parallel_wall(walls_by_cell, cell + axis, tile.rotation_steps)
			if has_negative == has_positive:
				continue
			tile.model_scale = Vector3(0.5, 1.0, 1.0)
			var shift := 0.25 if has_positive else -0.25
			tile.placement_offset = Vector2(axis.x, axis.y) * shift


func _has_perpendicular_pair(walls: Array) -> bool:
	var has_horizontal := false
	var has_vertical := false
	for value: Variant in walls:
		var tile := value as Tile
		if tile.rotation_steps % 2 == 0:
			has_horizontal = true
		else:
			has_vertical = true
	return has_horizontal and has_vertical


func _has_parallel_wall(walls_by_cell: Dictionary, cell: Vector2i, rotation_steps: int) -> bool:
	if not walls_by_cell.has(cell):
		return false
	for value: Variant in walls_by_cell[cell]:
		var tile := value as Tile
		if tile.rotation_steps % 2 == rotation_steps % 2:
			return true
	return false


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
	if grid.get_occupant(token.cell) != token or token.is_moving or token.is_attacking \
			or token.is_reacting or target == token.cell:
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


func can_attack(attacker: Token, target: Token) -> bool:
	return _attack_kind(attacker, target) >= 0


func _attack_kind(attacker: Token, target: Token) -> int:
	if attacker == null or target == null or attacker == target:
		return -1
	if grid.get_occupant(attacker.cell) != attacker or grid.get_occupant(target.cell) != target:
		return -1
	if attacker.is_moving or attacker.is_attacking or attacker.is_reacting \
			or target.is_moving or target.is_attacking or target.is_reacting:
		return -1
	var delta := target.cell - attacker.cell
	var distance := maxi(absi(delta.x), absi(delta.y))
	if not grid.has_line_of_sight(attacker.cell, target.cell):
		return -1
	if distance == 1:
		return Token.AttackKind.MELEE
	if distance <= attacker.attack_range:
		return Token.AttackKind.RANGED
	return -1


## Валидирует и проигрывает атаку. Урон и здоровье будут добавлены поверх этой точки авторитета.
func request_attack(attacker: Token, target: Token) -> bool:
	var attack_kind := _attack_kind(attacker, target)
	if attack_kind < 0:
		return false
	await attacker.play_attack(target, token_root, attack_kind as Token.AttackKind)
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

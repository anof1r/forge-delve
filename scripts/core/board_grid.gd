@tool
class_name BoardGrid
extends Node
## Единственный источник правды о геометрии и проходимости карты.
## Не зависит от того, как карта нарисована (2D, 3D): хранит только данные клеток.
## Клетка (x, y) лежит в 3D в точке (x, 0, y) * CELL_SIZE.

const CELL_SIZE := 1.0
const ALLOW_DIAGONALS := true

const _ORTHOGONAL: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]
const _DIAGONAL: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var _floor: Dictionary = {}  # Vector2i -> true
var _walls: Dictionary = {}  # Vector2i -> true
var _blockers: Dictionary = {}  # Vector2i -> true (пропы, закрывающие клетку)
var _occupants: Dictionary = {}  # Vector2i -> Token


# --- Геометрия -------------------------------------------------------------

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x, 0.0, cell.y) * CELL_SIZE


func world_to_cell(world_pos: Vector3) -> Vector2i:
	return Vector2i(roundi(world_pos.x / CELL_SIZE), roundi(world_pos.z / CELL_SIZE))


func used_rect() -> Rect2i:
	var rect := Rect2i()
	var first := true
	for cell: Vector2i in _floor.keys():
		if first:
			rect = Rect2i(cell, Vector2i.ONE)
			first = false
		else:
			rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	return rect


# --- Данные карты ----------------------------------------------------------

func add_floor(cell: Vector2i) -> void:
	_floor[cell] = true


func add_wall(cell: Vector2i) -> void:
	_floor[cell] = true
	_walls[cell] = true


func has_floor(cell: Vector2i) -> bool:
	return _floor.has(cell)


func has_wall(cell: Vector2i) -> bool:
	return _walls.has(cell)


# --- Проходимость ----------------------------------------------------------

func is_walkable(cell: Vector2i) -> bool:
	return has_floor(cell) and not _walls.has(cell) and not _blockers.has(cell)


func is_free(cell: Vector2i) -> bool:
	return is_walkable(cell) and not _occupants.has(cell)


func add_blocker(cell: Vector2i) -> void:
	_blockers[cell] = true


func remove_blocker(cell: Vector2i) -> void:
	_blockers.erase(cell)


# --- Занятость клеток токенами ---------------------------------------------

func get_occupant(cell: Vector2i) -> Token:
	return _occupants.get(cell)


func occupants() -> Array:
	return _occupants.values()


func register_occupant(token: Token, cell: Vector2i) -> void:
	_occupants[cell] = token


func move_occupant(token: Token, from: Vector2i, to: Vector2i) -> void:
	if _occupants.get(from) == token:
		_occupants.erase(from)
	_occupants[to] = token


func unregister_occupant(token: Token) -> void:
	for cell: Vector2i in _occupants.keys():
		if _occupants[cell] == token:
			_occupants.erase(cell)


# --- Поиск путей -----------------------------------------------------------

## BFS по свободным клеткам в пределах radius шагов (диагональ = 1 шаг, как в D&D 5e).
## Возвращает Dictionary: клетка -> клетка, из которой в неё пришли (origin -> origin).
func reachable(origin: Vector2i, radius: int) -> Dictionary:
	var parents: Dictionary = {origin: origin}
	var steps_to: Dictionary = {origin: 0}
	var queue: Array[Vector2i] = [origin]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var spent: int = steps_to[current]
		if spent >= radius:
			continue
		for step in _steps():
			var next: Vector2i = current + step
			if parents.has(next) or not is_free(next):
				continue
			if _is_diagonal(step) and not _diagonal_is_open(current, step):
				continue
			parents[next] = current
			steps_to[next] = spent + 1
			queue.append(next)
	return parents


## Путь до target (без стартовой клетки) по результату reachable(). Пустой, если недостижимо.
func path_to(reach: Dictionary, target: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not reach.has(target):
		return path
	var current: Vector2i = target
	while reach[current] != current:
		path.push_front(current)
		current = reach[current]
	return path


func _steps() -> Array[Vector2i]:
	if ALLOW_DIAGONALS:
		return _ORTHOGONAL + _DIAGONAL
	return _ORTHOGONAL


func _is_diagonal(step: Vector2i) -> bool:
	return step.x != 0 and step.y != 0


# Запрещаем срезать угол стены/препятствия.
func _diagonal_is_open(from: Vector2i, step: Vector2i) -> bool:
	return is_walkable(from + Vector2i(step.x, 0)) and is_walkable(from + Vector2i(0, step.y))

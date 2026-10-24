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
var _sight_segments: Array[PackedVector2Array] = []  # логические отрезки тонких стен


func clear() -> void:
	_floor.clear()
	_walls.clear()
	_blockers.clear()
	_occupants.clear()
	_sight_segments.clear()


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


func add_sight_segment(first: Vector2, second: Vector2) -> void:
	_sight_segments.append(PackedVector2Array([first, second]))


func remove_floor(cell: Vector2i) -> void:
	_floor.erase(cell)
	_walls.erase(cell)
	_blockers.erase(cell)


func remove_wall(cell: Vector2i) -> void:
	_walls.erase(cell)


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


func register_occupant(token: Token, cell: Vector2i) -> bool:
	if not is_free(cell):
		return false
	_occupants[cell] = token
	return true


func move_occupant(token: Token, from: Vector2i, to: Vector2i) -> bool:
	if _occupants.get(from) != token or not is_free(to):
		return false
	_occupants.erase(from)
	_occupants[to] = token
	return true


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


## Проверяет линию между центрами клеток. Стены, блокирующие пропы и клетки
## вне пола закрывают обзор. При точном проходе через угол проверяются обе
## соседние клетки, поэтому стрелять через соприкасающиеся углы нельзя.
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true
	var from_point := Vector2(from.x, from.y) * CELL_SIZE
	var to_point := Vector2(to.x, to.y) * CELL_SIZE
	for segment: PackedVector2Array in _sight_segments:
		if _segments_cross(from_point, to_point, segment[0], segment[1]):
			return false
	var delta := to - from
	var step_x := signi(delta.x)
	var step_y := signi(delta.y)
	var count_x := absi(delta.x)
	var count_y := absi(delta.y)
	var passed_x := 0
	var passed_y := 0
	var current := from

	while passed_x < count_x or passed_y < count_y:
		var decision := (1 + 2 * passed_x) * count_y - (1 + 2 * passed_y) * count_x
		if decision == 0:
			var side_x := current + Vector2i(step_x, 0)
			var side_y := current + Vector2i(0, step_y)
			# Касание одного угла не перекрывает выстрел. Линия закрыта только
			# когда обе стороны угла заняты — иначе это обычный обзор из-за угла.
			var x_blocked := side_x != to and _blocks_sight(side_x)
			var y_blocked := side_y != to and _blocks_sight(side_y)
			if x_blocked and y_blocked:
				return false
			current += Vector2i(step_x, step_y)
			passed_x += 1
			passed_y += 1
		elif decision < 0:
			current.x += step_x
			passed_x += 1
		else:
			current.y += step_y
			passed_y += 1

		if current != to and _blocks_sight(current):
			return false
	return true


func _blocks_sight(cell: Vector2i) -> bool:
	return not _floor.has(cell) or _blockers.has(cell)


func _segments_cross(first: Vector2, second: Vector2, wall_first: Vector2, wall_second: Vector2) -> bool:
	var ray := second - first
	var wall := wall_second - wall_first
	var divisor := ray.cross(wall)
	if is_zero_approx(divisor):
		return false
	var offset := wall_first - first
	var ray_amount := offset.cross(wall) / divisor
	var wall_amount := offset.cross(ray) / divisor
	const END_EPSILON := 0.001
	return ray_amount > END_EPSILON and ray_amount < 1.0 - END_EPSILON \
		and wall_amount > END_EPSILON and wall_amount < 1.0 - END_EPSILON


func _steps() -> Array[Vector2i]:
	if ALLOW_DIAGONALS:
		return _ORTHOGONAL + _DIAGONAL
	return _ORTHOGONAL


func _is_diagonal(step: Vector2i) -> bool:
	return step.x != 0 and step.y != 0


# Запрещаем срезать угол стены/препятствия.
func _diagonal_is_open(from: Vector2i, step: Vector2i) -> bool:
	return is_walkable(from + Vector2i(step.x, 0)) and is_walkable(from + Vector2i(0, step.y))

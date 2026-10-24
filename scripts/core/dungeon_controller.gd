class_name DungeonController
extends Node
## Превращает клики мыши в команды. Сама мир не меняет — только выбирает токен,
## показывает радиус движения и просит Dungeon выполнить ход или атаку.
## Экран → клетка: луч из камеры пересекается с плоскостью пола (y = 0).

const TOKEN_PICK_RADIUS := 0.4

var role: Permissions.Role = Permissions.Role.DM

var _dungeon: Dungeon
var _grid: BoardGrid
var _highlights: CellHighlighter
var _rig: CameraRig
var _camera: Camera3D
var _selected: Token
var _reach: Dictionary = {}
var _busy := false


func setup(dungeon: Dungeon, grid: BoardGrid, highlights: CellHighlighter, rig: CameraRig) -> void:
	_dungeon = dungeon
	_grid = grid
	_highlights = highlights
	_rig = rig
	_camera = rig.camera


func set_role(new_role: Permissions.Role) -> void:
	role = new_role
	_deselect()


func set_enabled(value: bool) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	if not value:
		_deselect()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell: Variant = _pick_cell(event.position)
			if cell != null:
				_on_cell_clicked(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect()
	elif event.is_action_pressed("ui_cancel"):
		_deselect()


## Клетка под курсором. Сначала ищем токен лучом (чтобы можно было кликнуть по голове
## высокой модели), затем — пересечение с полом.
func _pick_cell(screen_pos: Vector2) -> Variant:
	var origin := _camera.project_ray_origin(screen_pos)
	var direction := _camera.project_ray_normal(screen_pos)

	var best: Token = null
	var best_distance := INF
	for token: Token in _grid.occupants():
		var center := token.pick_center()
		var closest := Geometry3D.get_closest_point_to_segment_uncapped(center, origin, origin + direction)
		if closest.distance_to(center) <= TOKEN_PICK_RADIUS:
			var along := origin.distance_to(closest)
			if along < best_distance:
				best_distance = along
				best = token
	if best != null:
		return best.cell

	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit == null:
		return null
	return _grid.world_to_cell(hit)


func _on_cell_clicked(cell: Vector2i) -> void:
	var occupant := _grid.get_occupant(cell)
	if _selected != null and occupant != null and occupant != _selected \
			and _dungeon.can_attack(_selected, occupant):
		var attacker := _selected
		_busy = true
		_highlights.clear()
		_rig.focus_on((attacker.global_position + occupant.global_position) * 0.5)
		await _dungeon.request_attack(attacker, occupant)
		_busy = false
		if _selected == attacker:
			_select(attacker)
		return
	if occupant != null and Permissions.can_control(role, occupant.team):
		_select(occupant)
		return
	if _selected != null and cell != _selected.cell and _reach.has(cell):
		var mover := _selected
		_busy = true
		_highlights.clear()
		_rig.follow(mover)
		await _dungeon.request_move(mover, cell)
		_rig.stop_following()
		_busy = false
		if _selected == mover:
			_select(mover)
		return
	_deselect()


func _select(token: Token) -> void:
	if _selected != null:
		_selected.set_selected(false)
	_selected = token
	token.set_selected(true)
	_rig.focus_on(token.global_position)
	_reach = _grid.reachable(token.cell, token.move_radius)
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _reach.keys():
		if cell != token.cell:
			cells.append(cell)
	_highlights.show_cells(cells)


func _deselect() -> void:
	if _selected != null:
		_selected.set_selected(false)
	_selected = null
	_reach = {}
	_highlights.clear()

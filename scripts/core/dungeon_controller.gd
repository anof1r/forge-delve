class_name DungeonController
extends Node2D
## Превращает клики мыши в команды. Сама мир не меняет — только выбирает токен,
## показывает радиус движения и просит Dungeon выполнить ход.
## Наследует Node2D только ради get_global_mouse_position().

var role: Permissions.Role = Permissions.Role.DM

var _dungeon: Dungeon
var _grid: IsoGrid
var _highlights: CellHighlighter
var _selected: Token
var _reach: Dictionary = {}
var _busy := false


func setup(dungeon: Dungeon, grid: IsoGrid, highlights: CellHighlighter) -> void:
	_dungeon = dungeon
	_grid = grid
	_highlights = highlights


func set_role(new_role: Permissions.Role) -> void:
	role = new_role
	_deselect()


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_cell_clicked(_grid.world_to_cell(get_global_mouse_position()))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect()
	elif event.is_action_pressed("ui_cancel"):
		_deselect()


func _on_cell_clicked(cell: Vector2i) -> void:
	var occupant := _grid.get_occupant(cell)
	if occupant != null and Permissions.can_control(role, occupant.team):
		_select(occupant)
		return
	if _selected != null and cell != _selected.cell and _reach.has(cell):
		var mover := _selected
		_busy = true
		_highlights.clear()
		await _dungeon.request_move(mover, cell)
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

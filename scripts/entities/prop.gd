class_name Prop
extends Node2D
## Предмет окружения (сундук, стол, стул). Заглушка рисуется кодом; позже
## _draw() заменяется на Sprite2D, а логика (клетка, блокировка) остаётся прежней.

enum Kind { CHEST, TABLE, CHAIR }

const _PRESETS := {
	Kind.CHEST: {"footprint": 0.6, "height": 18.0, "color": Color("b8863b")},
	Kind.TABLE: {"footprint": 0.9, "height": 26.0, "color": Color("8a5a35")},
	Kind.CHAIR: {"footprint": 0.4, "height": 16.0, "color": Color("a06a40")},
}

@export var kind: Kind = Kind.CHEST
@export var blocks_movement := true

var cell := Vector2i.ZERO

var _tile_size := Vector2(128, 64)


func place(grid: IsoGrid, new_cell: Vector2i) -> void:
	cell = new_cell
	_tile_size = grid.tile_size
	position = grid.cell_to_world(new_cell)
	if blocks_movement:
		grid.add_blocker(new_cell)
	queue_redraw()


func _draw() -> void:
	var preset: Dictionary = _PRESETS[kind]
	IsoDraw.draw_box(self, _tile_size, preset["footprint"], preset["height"], preset["color"])

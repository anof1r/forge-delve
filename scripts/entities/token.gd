class_name Token
extends Node2D
## Фишка игрока или моба. Знает только свою клетку и умеет прыгать по клеткам.
## Ввод и правила (кто и куда может ходить) живут снаружи — в Dungeon и контроллере.
## Узлы сцены: Base — подставка на земле, Model — сменный визуал (он и прыгает).

signal move_finished

enum Team { PLAYER, MOB }
enum Shape { CIRCLE, SQUARE }

const SCENE := "res://scenes/token.tscn"

@export var display_name := "Token"
@export var team: Team = Team.PLAYER
@export var shape: Shape = Shape.CIRCLE
@export var body_color := Color.DODGER_BLUE
@export var move_radius := 6
@export var hop_duration := 0.22
@export var hop_height := 22.0

var cell := Vector2i.ZERO
var is_moving := false

var _grid: IsoGrid

@onready var _base: TokenBase = $Base
@onready var _model: TokenModel = $Model


static func create() -> Token:
	return (load(SCENE) as PackedScene).instantiate()


func _ready() -> void:
	_model.configure(display_name, body_color, shape)


func place(grid: IsoGrid, new_cell: Vector2i) -> void:
	_grid = grid
	cell = new_cell
	position = grid.cell_to_world(new_cell)
	grid.register_occupant(self, new_cell)


func set_selected(value: bool) -> void:
	_base.selected = value


## Последовательно прыгает по клеткам пути. Использовать через await.
func move_along(path: Array[Vector2i]) -> void:
	if is_moving or path.is_empty():
		return
	is_moving = true
	for next_cell in path:
		await _hop_to(next_cell)
	is_moving = false
	move_finished.emit()


func _hop_to(target: Vector2i) -> void:
	_grid.move_occupant(self, cell, target)
	cell = target
	var half := hop_duration * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", _grid.cell_to_world(target), hop_duration)
	tween.tween_property(_model, "position:y", -hop_height, half) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_model, "position:y", 0.0, half) \
		.set_delay(half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

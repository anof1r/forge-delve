class_name Token
extends Node3D
## Фишка игрока или моба. Знает только свою клетку и умеет прыгать по клеткам.
## Ввод и правила (кто и куда может ходить) живут снаружи — в Dungeon и контроллере.
## Узлы сцены: Base — подставка на земле, Model — сменный визуал (он и прыгает).

signal move_finished

enum Team { PLAYER, MOB }
enum Shape { CIRCLE, SQUARE }

const SCENE := "res://scenes/token.tscn"
const BASE_TOP := TokenBase.HEIGHT  # модель стоит на верхней плоскости подставки

@export var display_name := "Token"
@export var team: Team = Team.PLAYER
@export var shape: Shape = Shape.CIRCLE
@export var body_color := Color.DODGER_BLUE
@export var move_radius := 6
@export var hop_duration := 0.22
@export var hop_height := 0.25
@export var turn_duration := 0.12
## Поправка, если у модели «лицо» смотрит не вдоль +Z (стандарт glTF).
@export var facing_offset_deg := 0.0
## Если задана, вместо заглушки показывается эта модель (.glb), подогнанная под клетку.
@export var model_scene: PackedScene
@export var model_height := 0.9

var cell := Vector2i.ZERO
var is_moving := false

var _grid: BoardGrid

@onready var _base: TokenBase = $Base
@onready var _model: TokenModel = $Model


static func create() -> Token:
	return (load(SCENE) as PackedScene).instantiate()


func _ready() -> void:
	if model_scene != null:
		_swap_model_to_glb()
	_model.position.y = BASE_TOP
	_model.configure(display_name, body_color, shape)


func _swap_model_to_glb() -> void:
	_model.free()
	var glb := GlbTokenModel.new()
	glb.name = "Model"
	glb.model_scene = model_scene
	glb.target_height = model_height
	add_child(glb)
	_model = glb


func place(grid: BoardGrid, new_cell: Vector2i) -> void:
	_grid = grid
	cell = new_cell
	position = grid.cell_to_world(new_cell)
	grid.register_occupant(self, new_cell)


func set_selected(value: bool) -> void:
	_base.selected = value


## Центр токена для выбора лучом мыши (высокая модель кликается не только по клетке).
func pick_center() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)


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
	var step := target - cell
	cell = target
	var half := hop_duration * 0.5
	var rest_y := BASE_TOP
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", _grid.cell_to_world(target), hop_duration)
	tween.tween_property(_model, "position:y", rest_y + hop_height, half) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_model, "position:y", rest_y, half) \
		.set_delay(half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var from_yaw := _model.rotation.y
	var to_yaw := atan2(float(step.x), float(step.y)) + deg_to_rad(facing_offset_deg)
	tween.tween_method(
		func(t: float) -> void: _model.rotation.y = lerp_angle(from_yaw, to_yaw, t),
		0.0, 1.0, minf(turn_duration, hop_duration)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

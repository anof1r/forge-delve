@tool
class_name Token
extends Node3D
## Фишка игрока или моба. Знает свою клетку и проигрывает движение и атаки.
## Ввод и правила (кто и куда может ходить) живут снаружи — в Dungeon и контроллере.
## Узлы сцены: Base — подставка на земле, Model — сменный визуал (он и прыгает).

enum Team { PLAYER, MOB }
enum Shape { CIRCLE, SQUARE }
enum AttackKind { MELEE, RANGED }

const SCENE := "res://scenes/token.tscn"
const BASE_TOP := TokenBase.HEIGHT  # модель стоит на верхней плоскости подставки

@export var display_name := "Token"
@export var team: Team = Team.PLAYER
@export var shape: Shape = Shape.CIRCLE
@export var body_color := Color.DODGER_BLUE
@export var move_radius := 6
## Максимальная дистанция атаки. На соседней клетке всегда используется ближняя анимация.
@export_range(1, 20) var attack_range := 1
@export var hop_duration := 0.22
@export var hop_height := 0.25
@export var turn_duration := 0.12
## Поправка, если у модели «лицо» смотрит не вдоль +Z (стандарт glTF).
@export var facing_offset_deg := 0.0
## Если задана, вместо заглушки показывается эта модель (.glb), подогнанная под клетку.
@export var model_scene: PackedScene:
	set(value):
		model_scene = value
		if is_inside_tree():
			_rebuild_model()
@export var model_height := 0.9:
	set(value):
		model_height = value
		if is_inside_tree():
			_rebuild_model()

@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		if Engine.is_editor_hint() or not is_inside_tree():
			position = Vector3(cell.x, 0.0, cell.y) * BoardGrid.CELL_SIZE
var is_moving := false
var is_attacking := false
var is_reacting := false

var _grid: BoardGrid

@onready var _base: TokenBase = $Base
@onready var _model: TokenModel = $Model


static func create() -> Token:
	return (load(SCENE) as PackedScene).instantiate()


func _ready() -> void:
	_rebuild_model()


func _rebuild_model() -> void:
	if not is_inside_tree():
		return
	if model_scene != null and not _model is GlbTokenModel:
		_swap_model_to_glb()
	elif model_scene == null and not _model is PlaceholderTokenModel:
		_swap_model_to_placeholder()
	if _model is GlbTokenModel:
		_model.model_scene = model_scene
		_model.target_height = model_height
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


func _swap_model_to_placeholder() -> void:
	_model.free()
	var placeholder := PlaceholderTokenModel.new()
	placeholder.name = "Model"
	add_child(placeholder)
	_model = placeholder


func place(grid: BoardGrid, new_cell: Vector2i) -> bool:
	if not grid.register_occupant(self, new_cell):
		return false
	_grid = grid
	cell = new_cell
	position = grid.cell_to_world(new_cell)
	return true


func set_selected(value: bool) -> void:
	_base.selected = value


func face_cell(target: Vector2i) -> void:
	var direction := target - cell
	if direction == Vector2i.ZERO:
		return
	var from_yaw := _model.rotation.y
	var to_yaw := atan2(float(direction.x), float(direction.y)) + deg_to_rad(facing_offset_deg)
	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void: _model.rotation.y = lerp_angle(from_yaw, to_yaw, t),
		0.0, 1.0, turn_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


## Проигрывает выбранный тип атаки. Правила дальности проверяет Dungeon.
func play_attack(target: Token, projectile_parent: Node3D, attack_kind: AttackKind) -> void:
	if is_moving or is_attacking or is_reacting:
		return
	is_attacking = true
	await face_cell(target.cell)
	if attack_kind == AttackKind.RANGED:
		await _play_ranged_attack(target, projectile_parent)
	else:
		await _play_melee_attack(target)
	position = _grid.cell_to_world(cell)
	is_attacking = false


func play_hit_reaction(source_position: Vector3) -> void:
	if is_moving or is_attacking or is_reacting:
		return
	is_reacting = true
	var rest_position := _grid.cell_to_world(cell)
	var away := global_position - source_position
	away.y = 0.0
	if away.is_zero_approx():
		away = Vector3.FORWARD
	away = away.normalized()
	var tilt := deg_to_rad(11.0)
	var leaned_rotation := Vector3(away.z * tilt, rotation.y, -away.x * tilt)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", rest_position + away * 0.08 + Vector3.UP * 0.025, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", leaned_rotation, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position", rest_position, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", Vector3(0.0, rotation.y, 0.0), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	is_reacting = false


func _play_melee_attack(target: Token) -> void:
	var rest_position := _grid.cell_to_world(cell)
	var direction := target.global_position - global_position
	direction.y = 0.0
	direction = direction.normalized()
	var windup := rest_position - direction * 0.06 + Vector3.UP * 0.06
	var impact := rest_position + direction * 0.28 + Vector3.UP * 0.14
	var strike := create_tween()
	strike.tween_property(self, "position", windup, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	strike.tween_property(self, "position", impact, 0.11) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await strike.finished
	await target.play_hit_reaction(global_position)
	var recover := create_tween()
	recover.tween_property(self, "position", rest_position, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await recover.finished


func _play_ranged_attack(target: Token, projectile_parent: Node3D) -> void:
	var rest_position := _grid.cell_to_world(cell)
	var direction := target.global_position - global_position
	direction.y = 0.0
	direction = direction.normalized()
	var draw := create_tween()
	draw.tween_property(self, "position", rest_position - direction * 0.06 + Vector3.UP * 0.04, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await draw.finished
	var projectile := AttackProjectile.new()
	projectile_parent.add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 0.58
	var target_position := target.global_position + Vector3.UP * 0.45
	var recover := create_tween()
	recover.tween_property(self, "position", rest_position, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await projectile.fly_to(target_position)
	await target.play_hit_reaction(global_position)


## Центр токена для выбора лучом мыши (высокая модель кликается не только по клетке).
func pick_center() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)


## Последовательно прыгает по клеткам пути. Использовать через await.
func move_along(path: Array[Vector2i]) -> bool:
	if is_moving or is_attacking or is_reacting or path.is_empty():
		return false
	is_moving = true
	for next_cell in path:
		if not await _hop_to(next_cell):
			is_moving = false
			return false
	is_moving = false
	return true


func _hop_to(target: Vector2i) -> bool:
	if not _grid.move_occupant(self, cell, target):
		return false
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
	return true

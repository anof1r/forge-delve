class_name CameraRig
extends Node3D
## Орбитальная камера вокруг точки фокуса, как в настольной игре.
## СКМ — вращать, Space+ЛКМ или Shift+СКМ — двигать, колесо — зум, Q/E — поворот на 45°.

const PITCH_MIN := deg_to_rad(-88.0)
const PITCH_MAX := deg_to_rad(-10.0)
const DIST_MIN := 4.0
const DIST_MAX := 40.0
const ZOOM_STEP := 1.1
const ROTATE_SPEED := 0.006
const SNAP_STEP := deg_to_rad(45.0)
const SMOOTHING := 12.0

@onready var camera: Camera3D = $Camera3D

var _yaw := deg_to_rad(20.0)
var _pitch := deg_to_rad(-52.0)
var _distance := 18.0
var _focus := Vector3.ZERO

var _yaw_target := _yaw
var _pitch_target := _pitch
var _distance_target := _distance
var _focus_target := _focus

var _middle_dragging := false
var _space_panning := false
var _follow_target: Node3D


func _ready() -> void:
	_apply()


## Плавно наводит камеру на точку (например, на выбранный токен).
func focus_on(world_position: Vector3) -> void:
	_focus_target = Vector3(world_position.x, 0.0, world_position.z)


## Камера едет за узлом (например, за прыгающим токеном), пока не вызван stop_following().
func follow(target: Node3D) -> void:
	_follow_target = target


func stop_following() -> void:
	_follow_target = null


## Наводит камеру на карту: центр и размер большей стороны в клетках.
func frame(center: Vector3, extent: float) -> void:
	_focus = center
	_focus_target = center
	_distance = clampf(extent * 1.25, DIST_MIN, DIST_MAX)
	_distance_target = _distance
	_apply()


func _process(delta: float) -> void:
	if is_instance_valid(_follow_target):
		focus_on(_follow_target.global_position)
	var weight := 1.0 - exp(-SMOOTHING * delta)
	_yaw = lerp_angle(_yaw, _yaw_target, weight)
	_pitch = lerpf(_pitch, _pitch_target, weight)
	_distance = lerpf(_distance, _distance_target, weight)
	_focus = _focus.lerp(_focus_target, weight)
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				stop_following()
				_distance_target = clampf(_distance_target / ZOOM_STEP, DIST_MIN, DIST_MAX)
			MOUSE_BUTTON_WHEEL_DOWN:
				stop_following()
				_distance_target = clampf(_distance_target * ZOOM_STEP, DIST_MIN, DIST_MAX)
			MOUSE_BUTTON_MIDDLE:
				_middle_dragging = event.pressed
				if event.pressed:
					stop_following()
			MOUSE_BUTTON_LEFT:
				if Input.is_key_pressed(KEY_SPACE) or _space_panning:
					_space_panning = event.pressed
					if event.pressed:
						stop_following()
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and (_middle_dragging or _space_panning):
		if _space_panning or Input.is_key_pressed(KEY_SHIFT):
			_pan(event.relative)
		else:
			_yaw_target -= event.relative.x * ROTATE_SPEED
			_pitch_target = clampf(_pitch_target - event.relative.y * ROTATE_SPEED, PITCH_MIN, PITCH_MAX)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_yaw_target += SNAP_STEP
		elif event.keycode == KEY_E:
			_yaw_target -= SNAP_STEP


func _pan(relative: Vector2) -> void:
	var yaw_basis := Basis(Vector3.UP, _yaw_target)
	var scale := _distance_target * 0.0015
	var movement := -(yaw_basis * Vector3.RIGHT) * relative.x * scale \
		+ yaw_basis * Vector3.FORWARD * relative.y * scale
	_focus += movement
	_focus_target += movement
	_focus.y = 0.0
	_focus_target.y = 0.0
	_apply()


func _apply() -> void:
	position = _focus
	rotation = Vector3(_pitch, _yaw, 0.0)
	camera.position = Vector3(0.0, 0.0, _distance)

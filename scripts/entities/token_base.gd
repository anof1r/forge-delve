class_name TokenBase
extends Node3D
## Круглая подставка токена: остаётся на земле, пока модель прыгает.
## Рисует диск подставки и светящееся кольцо выбора.

const RADIUS := 0.38
const HEIGHT := 0.08

var selected := false:
	set(value):
		selected = value
		if _ring:
			_ring.visible = value

var _ring: MeshInstance3D


func _ready() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = HEIGHT
	var base := MeshInstance3D.new()
	base.mesh = disc
	base.material_override = Mat.solid(Color("2b2b33"), 0.5)
	base.position.y = HEIGHT * 0.5
	add_child(base)

	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS + 0.04
	torus.outer_radius = RADIUS + 0.1
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.material_override = Mat.glow(Color(1.0, 0.85, 0.25), 3.0)
	_ring.position.y = 0.04
	_ring.visible = selected
	add_child(_ring)

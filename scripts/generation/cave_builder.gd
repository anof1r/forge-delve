@tool
class_name CaveBuilder
extends RefCounted
## Создаёт обычные сохраняемые узлы. Во время игры генерация не вызывается.

const ROCK_SHADER := preload("res://assets/materials/cave_rock.gdshader")
const SIDES := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const CORNERS := [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.ONE, Vector2i.DOWN]
const VERTICAL_STEPS := 4


static func build(layout: Dictionary, wall_height: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Cave"
	var settings := layout.duplicate()
	settings.erase("cells")
	settings["wall_height"] = wall_height
	root.set_meta("cave_settings", settings)
	for group in ["Floor", "Walls", "Props", "Tokens"]:
		var container := Node3D.new()
		container.name = group
		root.add_child(container)
		container.owner = root
	var cells: Dictionary = layout["cells"]
	for cell: Vector2i in cells:
		var tile := Tile.create(TileCatalog.FLOOR, "Floor_UnevenBrick", cell)
		tile.name = "Floor_%d_%d" % [cell.x, cell.y]
		tile.scale_multiplier = 0.98
		root.get_node("Floor").add_child(tile)
		tile.owner = root
	var walls := CaveWalls.new()
	walls.name = "Rock"
	walls.mesh = _rock_mesh(cells, layout["seed"], clampf(wall_height, 0.6, 4.0))
	var material := ShaderMaterial.new()
	material.shader = ROCK_SHADER
	walls.material_override = material
	for cell: Vector2i in cells:
		for side in 4:
			if not cells.has(cell + SIDES[side]):
				walls.sight_edges.append(Vector2(cell) + Vector2(CORNERS[side]) - Vector2.ONE * 0.5)
				walls.sight_edges.append(Vector2(cell) + Vector2(CORNERS[(side + 1) % 4]) - Vector2.ONE * 0.5)
	root.get_node("Walls").add_child(walls)
	walls.owner = root
	return root


static func _rock_mesh(floor_cells: Dictionary, level_seed: int, height: float) -> ArrayMesh:
	# Полуклеточная сетка полосы скалы. Общие вершины вычисляются одинаково,
	# поэтому углы, верх и боковые поверхности соединяются без нахлёстов.
	var rock: Dictionary = {}
	for cell: Vector2i in floor_cells:
		for y in range(-1, 2):
			for x in range(-1, 2):
				var solid := cell + Vector2i(x, y)
				if floor_cells.has(solid):
					continue
				for dy in 2:
					for dx in 2:
						rock[solid * 2 + Vector2i(dx, dy)] = true
	var noise := FastNoiseLite.new()
	noise.seed = level_seed
	noise.frequency = 0.8
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for cell: Vector2i in rock:
		var top: Array[Vector3] = []
		for corner: Vector2i in CORNERS:
			top.append(_vertex(cell + corner, VERTICAL_STEPS, floor_cells, noise, height))
		_quad(surface, top[0], top[1], top[2], top[3])
		for side in 4:
			if rock.has(cell + SIDES[side]):
				continue
			var a: Vector2i = cell + CORNERS[side]
			var b: Vector2i = cell + CORNERS[(side + 1) % 4]
			for step in VERTICAL_STEPS:
				_quad(surface, _vertex(a, step, floor_cells, noise, height),
					_vertex(b, step, floor_cells, noise, height),
					_vertex(b, step + 1, floor_cells, noise, height),
					_vertex(a, step + 1, floor_cells, noise, height))
	surface.generate_normals()
	surface.index()
	return surface.commit()


static func _vertex(point: Vector2i, step: int, cells: Dictionary, noise: FastNoiseLite, height: float) -> Vector3:
	var base := Vector2(point) * 0.5 - Vector2.ONE * 0.5
	var fraction := float(step) / VERTICAL_STEPS
	var displacement := Vector2(noise.get_noise_3d(base.x, step * 2.3, base.y),
		noise.get_noise_3d(base.x + 71.0, step * 2.3, base.y)) * 0.65
	var shifted := base + displacement * sin(fraction * PI * 0.8)
	# Ограничиваем обе стороны на углах: одного теста конечной точки мало,
	# иначе наклонный треугольник мог бы срезать угол проходимого квадрата.
	var anchor := Vector2i(floori(base.x + 0.5), floori(base.y + 0.5))
	for y in range(-1, 2):
		for x in range(-1, 2):
			var neighbor := anchor + Vector2i(x, y)
			if not cells.has(neighbor):
				continue
			var delta := base - Vector2(neighbor)
			if absf(delta.x) > 0.501 or absf(delta.y) > 0.501:
				continue
			if is_equal_approx(delta.x, -0.5):
				shifted.x = minf(shifted.x, base.x)
			elif is_equal_approx(delta.x, 0.5):
				shifted.x = maxf(shifted.x, base.x)
			if is_equal_approx(delta.y, -0.5):
				shifted.y = minf(shifted.y, base.y)
			elif is_equal_approx(delta.y, 0.5):
				shifted.y = maxf(shifted.y, base.y)
	var top := height * (1.0 + noise.get_noise_2d(base.x * 0.5, base.y * 0.5) * 0.32)
	return Vector3(shifted.x, lerpf(-0.12, top, fraction), shifted.y)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	# Godot использует обход по часовой стрелке для лицевой стороны.
	for vertex in [a, b, c, a, c, d]:
		surface.add_vertex(vertex)

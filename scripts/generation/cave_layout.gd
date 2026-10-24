@tool
class_name CaveLayout
extends RefCounted
## Только клеточные данные. Геометрия и дерево сцены строятся отдельно.

const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


static func generate(size: Vector2i, level_seed: int, chambers: int, passage_width: int) -> Dictionary:
	size = size.clamp(Vector2i(16, 16), Vector2i(64, 64))
	chambers = clampi(chambers, 2, 12)
	passage_width = clampi(passage_width, 2, 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = level_seed
	var noise := FastNoiseLite.new()
	noise.seed = level_seed
	noise.frequency = 0.22
	var cells: Dictionary = {}
	var centers: Array[Vector2i] = []
	for index in chambers:
		var center := Vector2i.ZERO
		var best_distance := -1.0
		# Разносим полости, чтобы результат не превращался в один большой зал.
		for attempt in 16:
			var candidate := Vector2i(rng.randi_range(5, size.x - 6), rng.randi_range(5, size.y - 6))
			var nearest := INF
			for previous in centers:
				nearest = minf(nearest, candidate.distance_squared_to(previous))
			if nearest > best_distance:
				center = candidate
				best_distance = nearest
		var radius := Vector2(rng.randf_range(2.8, 4.8), rng.randf_range(2.8, 4.8))
		for y in range(2, size.y - 2):
			for x in range(2, size.x - 2):
				var cell := Vector2i(x, y)
				var distance := (Vector2(cell - center) / radius).length()
				if distance < 1.0 + noise.get_noise_2d(x, y) * 0.35:
					cells[cell] = true
		if not centers.is_empty():
			var nearest := centers[0]
			for previous in centers:
				if center.distance_squared_to(previous) < center.distance_squared_to(nearest):
					nearest = previous
			_carve_passage(cells, center, nearest, passage_width, rng)
		centers.append(center)
	# Шум может отделить одиночный выступ. Оставляем только связанную часть.
	var connected: Dictionary = {centers[0]: true}
	var queue: Array[Vector2i] = [centers[0]]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if cells.has(next) and not connected.has(next):
				connected[next] = true
				queue.append(next)
	return {"cells": connected, "entry": centers[0], "size": size, "seed": level_seed,
		"chambers": chambers, "passage_width": passage_width}


static func _carve_passage(cells: Dictionary, start: Vector2i, end: Vector2i, width: int, rng: RandomNumberGenerator) -> void:
	var current := start
	while true:
		var half := width / 2
		for y in width:
			for x in width:
				cells[current + Vector2i(x - half, y - half)] = true
		if current == end:
			break
		var difference := end - current
		if difference.x != 0 and (difference.y == 0 or rng.randf() < 0.5):
			current.x += signi(difference.x)
		else:
			current.y += signi(difference.y)

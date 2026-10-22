extends SceneTree
## Разовый генератор стартовой сцены таверны:
## godot --headless --path . --script res://tools/build_tavern.gd
## Дальше сцену scenes/levels/tavern.tscn правят в редакторе; повторный запуск её перезапишет.

const WIDTH := 14
const HEIGHT := 10
const FLOOR_THICKNESS := 0.2
const WALL_HEIGHT := 1.0
const OUT := "res://scenes/levels/tavern.tscn"

var _root: Node3D
var _floor: Node3D
var _walls: Node3D
var _props: Node3D


func _init() -> void:
	_root = Node3D.new()
	_root.name = "Tavern"
	_floor = _group("Floor")
	_walls = _group("Walls")
	_props = _group("Props")

	var floor_materials := [Mat.solid(Color("4b505a"), 0.9), Mat.solid(Color("40444d"), 0.9)]
	var wall_material := Mat.solid(Color("8c8279"), 0.85)
	var wall_cells: Array[Vector2i] = []
	for y in range(3, 7):
		wall_cells.append(Vector2i(7, y))

	for x in WIDTH:
		for y in HEIGHT:
			var cell := Vector2i(x, y)
			var is_wall := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1 or cell in wall_cells
			var world := Vector3(x, 0.0, y)
			var tile := Mat.box(Vector3(1, FLOOR_THICKNESS, 1), world + Vector3(0, -FLOOR_THICKNESS * 0.5, 0),
				floor_materials[posmod(x + y, 2)])
			tile.name = "Floor_%d_%d" % [x, y]
			_add(_floor, tile)
			if is_wall:
				var wall := Mat.box(Vector3(1, WALL_HEIGHT, 1), world + Vector3(0, WALL_HEIGHT * 0.5, 0), wall_material)
				wall.name = "Wall_%d_%d" % [x, y]
				_add(_walls, wall)

	_furnish_tavern()

	var scene := PackedScene.new()
	scene.pack(_root)
	DirAccess.make_dir_recursive_absolute("res://scenes/levels")
	print("save: ", error_string(ResourceSaver.save(scene, OUT)))
	quit()


func _group(group_name: String) -> Node3D:
	var node := Node3D.new()
	node.name = group_name
	_root.add_child(node)
	node.owner = _root
	return node


func _add(parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = _root


func add_prop(prop_id: String, cell: Vector2i, rotation_steps := 0, options := {}) -> void:
	var prop := Prop.create(prop_id, cell, rotation_steps, options)
	_add(_props, prop)
	prop.name = "%s_%d_%d" % [prop_id, cell.x, cell.y]


func _furnish_tavern() -> void:
	var snap := {"snap": true}
	var wall_torch := {"snap": true, "elevation": 0.6}
	var table_top := 0.405

	add_prop("Bookcase_2", Vector2i(2, 1), 0, snap)
	add_prop("Bookcase_2", Vector2i(3, 1), 0, snap)
	add_prop("Torch_Metal", Vector2i(4, 1), 0, wall_torch)
	add_prop("Cabinet", Vector2i(5, 1), 0, snap)
	add_prop("Vase_2", Vector2i(5, 1), 0, {"snap": true, "elevation": 0.5})
	add_prop("Torch_Metal", Vector2i(6, 1), 0, wall_torch)
	add_prop("Workbench", Vector2i(8, 1), 0, snap)
	add_prop("Barrel", Vector2i(9, 1), 0, snap)
	add_prop("Barrel_Apples", Vector2i(10, 1), 0, snap)
	add_prop("Crate_Wooden", Vector2i(11, 1), 0, snap)
	add_prop("Crate_Wooden", Vector2i(12, 1), 0, snap)

	add_prop("WeaponStand", Vector2i(1, 3), 1, snap)
	add_prop("Dummy", Vector2i(1, 5), 1, snap)
	add_prop("Bed_Twin1", Vector2i(1, 7), 1, snap)

	add_prop("Table_Large", Vector2i(3, 5))
	add_prop("Chair_1", Vector2i(3, 4), 0)
	add_prop("Chair_1", Vector2i(4, 4), 0)
	add_prop("Chair_1", Vector2i(3, 6), 2)
	add_prop("Chair_1", Vector2i(4, 6), 2)
	add_prop("Stool", Vector2i(2, 5), 1)
	add_prop("Stool", Vector2i(5, 5), 3)
	add_prop("Table_Plate", Vector2i(3, 5), 0, {"elevation": table_top, "offset": Vector2(-0.2, 0.0)})
	add_prop("Table_Plate", Vector2i(4, 5), 0, {"elevation": table_top, "offset": Vector2(0.2, 0.0)})
	add_prop("Mug", Vector2i(3, 5), 0, {"elevation": table_top, "offset": Vector2(0.25, 0.12)})
	add_prop("Mug", Vector2i(4, 5), 0, {"elevation": table_top, "offset": Vector2(-0.25, -0.12)})
	add_prop("CandleStick_Triple", Vector2i(3, 5), 0, {"elevation": table_top, "offset": Vector2(0.5, 0.0)})

	add_prop("Bench", Vector2i(4, 8), 2, snap)
	add_prop("Cage_Small", Vector2i(8, 8), 2, snap)
	add_prop("Anvil", Vector2i(10, 8), 2, snap)
	add_prop("Crate_Wooden", Vector2i(11, 8), 2, snap)
	add_prop("Crate_Metal", Vector2i(12, 8), 2, snap)

	add_prop("Chest_Wood", Vector2i(12, 3), 3, snap)
	add_prop("Barrel", Vector2i(12, 5), 3, snap)
	add_prop("Barrel", Vector2i(12, 6), 3, snap)
	add_prop("Cauldron", Vector2i(8, 7), 2)

	add_prop("Torch_Metal", Vector2i(6, 3), 3, wall_torch)
	add_prop("Torch_Metal", Vector2i(8, 5), 1, wall_torch)

@tool
class_name TileCatalog
extends RefCounted
## Каталог модульных полов и стен. Геометрия уровня хранит только тип плитки,
## идентификатор набора и вариант; конкретный glTF выбирается здесь.

const FLOOR := 0
const WALL := 1
const DIR := "res://assets/walls/"

const _ENTRIES := {
	"floor_stone": {
		"models": ["Floor_Brick", "Floor_UnevenBrick", "Floor_RedBrick"],
		"scale": 0.5,
		"blocks": false,
	},
	"floor_wood": {
		"models": ["Floor_WoodDark", "Floor_WoodLight"],
		"scale": 0.5,
		"blocks": false,
	},
	"wall_stone": {
		"models": ["Wall_UnevenBrick_Straight"],
		"scale": 0.5,
		"blocks": true,
		"offset": Vector3(0.0, 0.0, 0.055),
	},
	"wall_stone_door": {
		"models": ["Wall_UnevenBrick_Door_Flat", "Wall_UnevenBrick_Door_Round"],
		"scale": 0.5,
		"blocks": false,
		"offset": Vector3(0.0, 0.0, 0.055),
	},
	"wall_stone_window": {
		"models": [
			"Wall_UnevenBrick_Window_Thin_Round",
			"Wall_UnevenBrick_Window_Wide_Flat",
			"Wall_UnevenBrick_Window_Wide_Round",
		],
		"scale": 0.5,
		"blocks": true,
		"offset": Vector3(0.0, 0.0, 0.055),
	},
	"wall_plaster": {
		"models": ["Wall_Plaster_Straight", "Wall_Plaster_WoodGrid"],
		"scale": 0.5,
		"blocks": true,
	},
	"wall_corner_interior": {
		"models": ["Corner_Interior_Small", "Corner_Interior_Big"],
		"scale": 0.5,
		"blocks": true,
	},
	"wall_corner_exterior": {
		"models": ["Corner_Exterior_Brick", "Corner_ExteriorWide_Brick"],
		"scale": 0.5,
		"blocks": true,
	},
}


static func entry(model_id: String, fallback_kind := FLOOR) -> Dictionary:
	if _ENTRIES.has(model_id):
		return _ENTRIES[model_id]
	return {
		"models": [model_id],
		"scale": 0.5,
		"blocks": fallback_kind == WALL,
	}


static func model_name(model_id: String, variant: int, fallback_kind := FLOOR) -> String:
	var models: Array = entry(model_id, fallback_kind)["models"]
	return models[posmod(variant, models.size())]


static func model_path(model_id: String, variant: int, fallback_kind := FLOOR) -> String:
	return DIR + model_name(model_id, variant, fallback_kind) + ".gltf"

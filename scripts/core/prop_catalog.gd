@tool
class_name PropCatalog
extends RefCounted
## Каталог пропов: имя модели из assets/props/ -> параметры размещения.
## Модели в паке в «реальных» метрах, а клетка карты ~2 м (токен высотой 0.9),
## поэтому по умолчанию всё уменьшается вдвое.
## Для модели без записи действуют значения DEFAULTS: клетка 1x1, блокирует ход.
##
## Поля записи:
##   footprint  — сколько клеток занимает при повороте 0 (ширина по X, глубина по Z)
##   blocks     — закрывает ли клетки для движения
##   light      — {color, energy, range, offset, shadow, flame}; offset в мировых единицах
##   scale      — множитель масштаба модели

const DIR := "res://assets/props/"

const DEFAULTS := {
	"footprint": Vector2i.ONE,
	"blocks": true,
	"scale": 0.5,
}

const _TORCH_LIGHT := {
	"color": Color("ffa24a"), "energy": 1.6, "range": 5.5,
	"offset": Vector3(0.0, 0.3, 0.2), "shadow": true, "flame": 0.07,
}

const _CANDLE_LIGHT := {
	"color": Color("ffb35c"), "energy": 0.7, "range": 2.5,
	"offset": Vector3(0.0, 0.3, 0.0), "shadow": false, "flame": 0.04,
}

const _ENTRIES := {
	"Table_Large": {"footprint": Vector2i(2, 1)},
	"Bench": {"footprint": Vector2i(2, 1)},
	"Bed_Twin1": {"footprint": Vector2i(1, 2)},
	"Bed_Twin2": {"footprint": Vector2i(1, 2)},
	"Torch_Metal": {"blocks": false, "light": _TORCH_LIGHT},
	"Lantern_Wall": {"blocks": false, "light": {
		"color": Color("ffb85c"), "energy": 1.5, "range": 5.5,
		"offset": Vector3(0.0, 0.3, 0.25), "shadow": true, "flame": 0.08,
	}},
	"CandleStick": {"blocks": false, "light": _CANDLE_LIGHT},
	"CandleStick_Triple": {"blocks": false, "light": _CANDLE_LIGHT},
	"CandleStick_Stand": {"blocks": false, "light": _CANDLE_LIGHT},
}

## Мелочь, которую ставят на столы и полки: сама клетку не закрывает.
const _SMALL := [
	"Candle_1", "Candle_2", "Mug", "Chalice", "Table_Plate", "Table_Fork", "Table_Knife",
	"Table_Spoon", "Potion_1", "Potion_2", "Potion_4", "SmallBottle", "SmallBottles_1",
	"Bottle_1", "Scroll_1", "Scroll_2", "Book_5", "Book_7", "Book_Simplified_Single",
	"Book_Stack_1", "Book_Stack_2", "BookGroup_Small_1", "BookGroup_Small_2",
	"BookGroup_Small_3", "BookGroup_Medium_1", "BookGroup_Medium_2", "BookGroup_Medium_3",
	"Coin", "Coin_Pile", "Coin_Pile_2", "Key_Gold", "Key_Metal", "Pouch_Large", "Bag",
	"Sword_Bronze", "Axe_Bronze", "Pickaxe_Bronze", "Whetstone", "Vase_2", "Vase_4",
]


static func entry(prop_id: String) -> Dictionary:
	var result := DEFAULTS.duplicate()
	if prop_id in _SMALL:
		result["blocks"] = false
	result.merge(_ENTRIES.get(prop_id, {}), true)
	return result


static func model_path(prop_id: String) -> String:
	return DIR + prop_id + ".gltf"

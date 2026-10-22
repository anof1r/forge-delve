class_name PlaceholderTileset
extends RefCounted
## Генерирует изометрический TileSet-заглушку кодом (без внешних ассетов).
## Чтобы подключить настоящий арт, достаточно заменить build() на загрузку своего
## TileSet-ресурса с теми же настройками (Isometric, Diamond Down, 128x64) и
## сохранить ID источников SOURCE_FLOOR / SOURCE_WALL.

const TILE_SIZE := Vector2i(128, 64)
const WALL_HEIGHT := 32
const SOURCE_FLOOR := 0
const SOURCE_WALL := 1

const _FLOOR_COLORS: Array[Color] = [Color("4b505a"), Color("40444d")]
const _FLOOR_EDGE := Color("2c2f36")
const _WALL_TOP := Color("7d828d")
const _WALL_EDGE := Color("4d515a")


static func build() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = TILE_SIZE
	tile_set.add_source(_floor_source(), SOURCE_FLOOR)
	tile_set.add_source(_wall_source(), SOURCE_WALL)
	return tile_set


## Атлас из двух ромбов разной яркости: из них собирается шахматный пол.
static func _floor_source() -> TileSetAtlasSource:
	var image := Image.create(TILE_SIZE.x * 2, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	var half := Vector2(TILE_SIZE) * 0.5
	for variant in 2:
		for y in TILE_SIZE.y:
			for x in TILE_SIZE.x:
				var d := absf(x + 0.5 - half.x) / half.x + absf(y + 0.5 - half.y) / half.y
				if d > 1.0:
					continue
				var color := _FLOOR_EDGE if d > 0.94 else _FLOOR_COLORS[variant]
				image.set_pixel(variant * TILE_SIZE.x + x, y, color)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = TILE_SIZE
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	return source


## Куб-стена. Картинка квадратная, центр совпадает с центром клетки на земле,
## поэтому texture_origin не нужен.
static func _wall_source() -> TileSetAtlasSource:
	var size := TILE_SIZE.x
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half_w := TILE_SIZE.x * 0.5
	var half_h := TILE_SIZE.y * 0.5
	var top_center_y := size * 0.5 - WALL_HEIGHT
	for y in size:
		for x in size:
			var px := x + 0.5
			var py := y + 0.5
			var dx := absf(px - half_w) / half_w
			var reach := half_h * (1.0 - dx)
			if dx > 1.0 or py < top_center_y - reach or py > top_center_y + WALL_HEIGHT + reach:
				continue
			var color: Color
			if py <= top_center_y + reach:
				var d := dx + absf(py - top_center_y) / half_h
				color = _WALL_EDGE if d > 0.94 else _WALL_TOP
			else:
				color = _WALL_TOP.darkened(0.35 if px < half_w else 0.55)
			image.set_pixel(x, y, color)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(size, size)
	source.create_tile(Vector2i(0, 0))
	return source

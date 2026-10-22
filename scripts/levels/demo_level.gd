class_name DemoLevel
extends RefCounted
## Демо-карта в коде. Загрузчик настоящих уровней (JSON/Resource) должен
## вызывать те же методы Dungeon: add_floor / add_wall / add_prop / add_token.

const WIDTH := 14
const HEIGHT := 10


static func build(dungeon: Dungeon) -> void:
	for x in WIDTH:
		for y in HEIGHT:
			var cell := Vector2i(x, y)
			var is_border := x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1
			if is_border:
				dungeon.add_wall(cell)
			else:
				dungeon.add_floor(cell)

	for y in range(3, 7):
		dungeon.add_wall(Vector2i(7, y))

	dungeon.add_prop(_prop(Prop.Kind.TABLE), Vector2i(4, 5))
	dungeon.add_prop(_prop(Prop.Kind.CHAIR), Vector2i(3, 5))
	dungeon.add_prop(_prop(Prop.Kind.CHAIR), Vector2i(5, 5))
	dungeon.add_prop(_prop(Prop.Kind.CHAIR), Vector2i(4, 4))
	dungeon.add_prop(_prop(Prop.Kind.CHEST), Vector2i(11, 2))

	dungeon.add_token(_player("Aria", Color("3b82f6")), Vector2i(2, 2))
	dungeon.add_token(_player("Borin", Color("22c55e")), Vector2i(2, 4))
	dungeon.add_token(_mob("Goblin", Color("ef4444"), 3), Vector2i(10, 6))
	dungeon.add_token(_mob("Goblin", Color("ef4444"), 3), Vector2i(11, 7))
	dungeon.add_token(_mob("Ogre", Color("f97316"), 4), Vector2i(10, 4))


static func _prop(kind: Prop.Kind) -> Prop:
	var prop := Prop.new()
	prop.kind = kind
	return prop


static func _player(token_name: String, color: Color) -> Token:
	var token := Token.create()
	token.display_name = token_name
	token.team = Token.Team.PLAYER
	token.shape = Token.Shape.CIRCLE
	token.body_color = color
	token.move_radius = 6
	return token


static func _mob(token_name: String, color: Color, radius: int) -> Token:
	var token := Token.create()
	token.display_name = token_name
	token.team = Token.Team.MOB
	token.shape = Token.Shape.SQUARE
	token.body_color = color
	token.move_radius = radius
	return token

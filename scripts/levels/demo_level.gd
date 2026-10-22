class_name DemoLevel
extends RefCounted
## Демо-расстановка токенов. Пол, стены и мебель лежат в сцене scenes/levels/tavern.tscn.


static func spawn_tokens(dungeon: Dungeon) -> void:
	dungeon.add_token(_player("Aria", Color("3b82f6")), Vector2i(2, 2))
	var dal := _player("Dal Dayneris", Color("3b82f6"))
	dal.model_scene = load("res://assets/models/dal_dayneris.glb")
	dungeon.add_token(dal, Vector2i(3, 3))
	var maximir := _player("Maximir", Color("a855f7"))
	maximir.model_scene = load("res://assets/models/maximir.glb")
	dungeon.add_token(maximir, Vector2i(2, 6))
	dungeon.add_token(_player("Borin", Color("22c55e")), Vector2i(2, 4))
	dungeon.add_token(_mob("Goblin", Color("ef4444"), 3), Vector2i(10, 6))
	dungeon.add_token(_mob("Goblin", Color("ef4444"), 3), Vector2i(11, 7))
	dungeon.add_token(_mob("Ogre", Color("f97316"), 4), Vector2i(10, 4))



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

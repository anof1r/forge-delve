class_name DemoLevel
extends RefCounted
## Исходная расстановка токенов для одноразового генератора tavern.tscn.


static func populate(parent: Node3D, scene_owner: Node) -> void:
	var dal := _player("Dal Dayneris", Color("3b82f6"))
	dal.model_scene = load("res://assets/models/dal_dayneris.glb")
	_add(parent, scene_owner, dal, Vector2i(3, 3))
	var maximir := _player("Maximir", Color("a855f7"))
	maximir.model_scene = load("res://assets/models/maximir.glb")
	maximir.attack_range = 6
	_add(parent, scene_owner, maximir, Vector2i(5, 7))
	_add(parent, scene_owner, _mob("Goblin", Color("ef4444"), 3), Vector2i(10, 6))
	var goblin_archer := _mob("Goblin", Color("ef4444"), 3)
	goblin_archer.attack_range = 6
	_add(parent, scene_owner, goblin_archer, Vector2i(11, 7))
	_add(parent, scene_owner, _mob("Ogre", Color("f97316"), 4), Vector2i(10, 4))


static func _add(parent: Node3D, scene_owner: Node, token: Token, cell: Vector2i) -> void:
	token.name = token.display_name.replace(" ", "")
	token.cell = cell
	parent.add_child(token)
	token.owner = scene_owner



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

class_name Permissions
extends RefCounted
## Кто чем может управлять. Единая точка для будущей сетевой авторизации.

enum Role { DM, PLAYER }


static func can_control(role: Role, team: Token.Team) -> bool:
	match role:
		Role.DM:
			return team == Token.Team.MOB
		Role.PLAYER:
			return team == Token.Team.PLAYER
	return false

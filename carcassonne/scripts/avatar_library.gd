class_name AvatarLibrary
extends Resource
## The list of avatars the lobby offers. Save one as res://avatars/avatar_library.tres
## (the path GameSession loads). It needs at least 6 avatars so 6 players can all
## have a different one.

@export var avatars: Array[AvatarDef] = []

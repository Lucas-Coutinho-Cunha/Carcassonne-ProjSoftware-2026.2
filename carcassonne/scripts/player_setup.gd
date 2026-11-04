class_name PlayerSetup
extends RefCounted
## One player as chosen in the lobby. Plain data only, so it survives scene changes.
## The Player node (with the 3D model) is created from this when the game starts.

var display_name: String = ""
var avatar: AvatarDef
var is_bot: bool = false


func _init(p_name: String = "", p_avatar: AvatarDef = null, p_is_bot: bool = false) -> void:
	display_name = p_name
	avatar = p_avatar
	is_bot = p_is_bot


## Copies the lobby choices onto a freshly instantiated Player node.
## Call this AFTER add_child(), so the Player's model nodes are ready to receive the material.
func apply_to(player: Player) -> void:
	player.display_name = display_name
	player.is_bot = is_bot
	player.apply_avatar(avatar)

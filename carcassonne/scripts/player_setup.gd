class_name PlayerSetup
extends RefCounted


var display_name: String = ""
var avatar: AvatarDef
var is_bot: bool = false


func _init(p_name: String = "", p_avatar: AvatarDef = null, p_is_bot: bool = false) -> void:
	display_name = p_name
	avatar = p_avatar
	is_bot = p_is_bot


func apply_to(player: Player) -> void:
	player.display_name = display_name
	player.is_bot = is_bot
	player.apply_avatar(avatar)

class_name Player
extends Node3D

@export_category("Appearance")
@export_enum("Orange:1", "Black:2", "White:3", "Green:4", "Blue:5", "Yellow:6", "Red:7", "Pink:8") var body: int = 1

var textures: Array[Resource] = []
var text_color: Color = Color.WHITE

var id: int = 0
var display_name: String = ""
var color: Color = Color.WHITE
var score: int = 0
var meeples_left: int = 0
@export var model_mesh: MeshInstance3D
@export var avatar_surface_index: int = -1

var avatar: AvatarDef
var is_bot: bool = false


func apply_avatar(def: AvatarDef) -> void:
	avatar = def
	def.apply_to(model_mesh, avatar_surface_index)

func setup_game_state(p_id: int, p_color: Color, p_meeples: int) -> void:
	id = p_id
	color = p_color
	meeples_left = p_meeples


func set_body(avatar_id: int) -> void:
	match avatar_id:
		1: pass
		2: pass
		3: pass
		4: pass
		5: pass
		6: pass
		7: pass
		8: pass

class_name Player
extends Node3D

@export_category("Appearance")
@export_enum("Orange:1", "Black:2", "White:3", "Green:4", "Blue:5", "Yellow:6", "Red:7", "Pink:8") var body: int = 1

var textures: Array[Resource] = []
var avatar: int = 0
var text_color: Color = Color.WHITE

# Game state, filled in by Game through setup_game_state().
var id: int = 0
var display_name: String = ""
var color: Color = Color.WHITE
var score: int = 0
var meeples_left: int = 0


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

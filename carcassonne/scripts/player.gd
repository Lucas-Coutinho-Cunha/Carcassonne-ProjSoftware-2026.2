class_name Player extends Node3D


@export_category("Appearance")
@export_enum("Orange:1", "Black:2", "White:3", "Green:4", "Blue:5", "Yellow:6", "Red:7", "Pink:8") var body: int
@export_enum("Blue:1", "Yellow:2", "Homo:3", "Beady:4") var eyes: int

var textures: Array[Resource] = []
var avatar: int = 0
var text_color: Color
var id: int
var color: Color
var display_name: String
var score: int = 0
var meeples_left: int = 0


func _init(p_id: int, p_name: String, p_color: Color, p_meeples: int) -> void:
	id = p_id
	display_name = p_name
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
	

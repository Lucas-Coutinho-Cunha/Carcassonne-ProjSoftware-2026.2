class_name Player extends Node3D



@export_category("Appearance")
@export_enum("Orange:1", "Black:2", "White:3", "Green:4", "Blue:5", "Yellow:6", "Red:7", "Pink:8") var body: int
@export_enum("Blue:1", "Yellow:2", "Homo:3", "Beady:4") var eyes: int

var eye_textures: Array[Texture2D]

var text_color: Color


func set_body(type: int) -> void:
	match type:
		1: pass
		2: pass
		3: pass
		4: pass
		5: pass
		6: pass
		7: pass
		8: pass
		


func _process(delta: float) -> void:
	pass

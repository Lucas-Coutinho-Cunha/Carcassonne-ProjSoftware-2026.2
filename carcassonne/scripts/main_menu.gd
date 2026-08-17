class_name MainMenu extends Node2D


@onready var title_sprite: Sprite2D = $title
@onready var aiaiai: AudioStreamPlayer = $AudioStreamPlayer


var sprite2d: Sprite2D


var num: float = 0

@export var amplit: float
@export var freq: float


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("play"):
		aiaiai.play()


func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	num += 1
	title_sprite.position.y = sin(num/freq)*amplit + 200


func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/node_2d.tscn")

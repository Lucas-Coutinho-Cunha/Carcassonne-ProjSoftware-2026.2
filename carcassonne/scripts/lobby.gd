extends Node3D

@export var sign_mesh: Node3D

@export var text_i: MeshInstance3D
@onready var neon_buzz: AudioStreamPlayer = $Map/NeonBuzz

var black_material: Resource = load("res://resources/black_material_sign.tres")
var neon_material: Resource = load("res://resources/neon_material_sign.tres")
var intro_neon_finished: bool = false
var flicker: int
var mouse_over: int

var spawn_cat: Player
var spawn_cat_anim: AnimationPlayer

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Tap"):
		if mouse_over == 1:
			spawn_player(1)


func _ready() -> void:
	for i: MeshInstance3D in sign_mesh.get_children():
		i.material_override = black_material
		neon_buzz.play()
	await get_tree().create_timer(1.0).timeout
	for i: MeshInstance3D in sign_mesh.get_children():
		i.material_override = neon_material
		neon_buzz.play()
	await get_tree().create_timer(0.2).timeout
	for i: MeshInstance3D in sign_mesh.get_children():
		i.material_override = black_material
		neon_buzz.play()
	await get_tree().create_timer(0.2).timeout
	for i: MeshInstance3D in sign_mesh.get_children():
		i.material_override = neon_material
		neon_buzz.play()
	await get_tree().create_timer(0.2).timeout
	for i: MeshInstance3D in sign_mesh.get_children():
		i.material_override = black_material
		neon_buzz.play()
	await get_tree().create_timer(0.2).timeout
	for i: MeshInstance3D in sign_mesh.get_children():
		i.material_override = neon_material
		neon_buzz.play()
		neon_buzz.volume_db -= 3
	intro_neon_finished = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if intro_neon_finished:
		flicker += 1
		if flicker % 60 == 0:
			text_i.material_override = black_material
			neon_buzz.play()
		elif flicker % 45 == 0:
			text_i.material_override = neon_material
			neon_buzz.play()
	
	


func spawn_player(id: int) -> void:
	spawn_cat = $Map/Boxes/Box1/CatPosition1/Player
	spawn_cat_anim = $Map/Boxes/Box1/CatPosition1/Player/Cat/AnimationPlayer
	spawn_cat.visible = true
	spawn_cat_anim.play("emerge")
	await spawn_cat_anim.animation_finished
	spawn_cat_anim.play("lobbyidle")



func _on_area_3d_mouse_entered() -> void:
	mouse_over = 1

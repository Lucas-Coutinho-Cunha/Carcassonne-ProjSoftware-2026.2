class_name AvatarPreview
extends SubViewportContainer
## A small spinning 3D view of the player model wearing an avatar's material.
## Set `player_scene` (your Player scene, which must have apply_avatar()) before adding
## this node to the tree, then call show_avatar().

@export var player_scene: PackedScene
@export var preview_size: Vector2 = Vector2(160.0, 200.0)
## Tune these two to frame your model.
@export var camera_position: Vector3 = Vector3(0.0, 1.0, 3.0)
@export var camera_target: Vector3 = Vector3(0.0, 0.8, 0.0)
@export var spin_degrees_per_second: float = 30.0

var _pivot: Node3D
var _model: Player
var _avatar: AvatarDef


func _ready() -> void:
	stretch = true
	custom_minimum_size = preview_size

	var viewport: SubViewport = SubViewport.new()
	viewport.own_world_3d = true  # keeps the preview separate from the real game world
	viewport.transparent_bg = true
	add_child(viewport)

	var environment: Environment = Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.65, 0.65)
	var camera: Camera3D = Camera3D.new()
	camera.environment = environment
	viewport.add_child(camera)
	camera.position = camera_position
	camera.look_at(camera_target)
	camera.current = true

	var light: DirectionalLight3D = DirectionalLight3D.new()
	viewport.add_child(light)
	light.rotation_degrees = Vector3(-40.0, 30.0, 0.0)

	_pivot = Node3D.new()
	viewport.add_child(_pivot)
	if player_scene == null:
		push_warning("AvatarPreview: player_scene is not set")
		return
	_model = player_scene.instantiate() as Player
	_pivot.add_child(_model)
	if _avatar != null:
		_model.apply_avatar(_avatar)


func _process(delta: float) -> void:
	if _pivot != null:
		_pivot.rotate_y(deg_to_rad(spin_degrees_per_second) * delta)


func show_avatar(avatar: AvatarDef) -> void:
	_avatar = avatar
	if _model != null and avatar != null:
		_model.apply_avatar(avatar)

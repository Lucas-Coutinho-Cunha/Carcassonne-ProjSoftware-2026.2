extends Control

@export var map_texture: Texture2D
@export_file("*.tscn") var game_scene: String = "res://scenes/game.tscn"

@export_group("Mapa")
@export var map_zoom := 1.3              # >1 dá folga para o mapa se mover
@export var map_speed := 0.2            # velocidade da deriva (rad/s)
@export var map_mouse_strength := 15.0   # parallax do mouse no mapa

@export_group("Nuvens")
@export var cloud_texture: Texture2D     # opcional: se vazio, gera nuvens proceduralmente
@export var cloud_count := 7
@export var cloud_speed := 25.0          # px/s (multiplicado pela "profundidade")
@export var cloud_mouse_strength := 40.0

@onready var map: Sprite2D = $World/Map
@onready var clouds: Node2D = $World/Clouds

var _t := 0.0
var _vp := Vector2.ZERO
var _map_range := Vector2.ZERO
var _puff: GradientTexture2D


func _ready() -> void:
	_vp = get_viewport_rect().size
	_setup_map()
	_spawn_clouds()
	$UI/VBox/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	$UI/VBox/Buttons/OptionsButton.pressed.connect(_on_options_pressed)
	$UI/VBox/Buttons/QuitButton.pressed.connect(get_tree().quit)


func _setup_map() -> void:
	map.texture = map_texture
	var tex_size := map_texture.get_size()
	var s := maxf(_vp.x / tex_size.x, _vp.y / tex_size.y) * map_zoom
	map.scale = Vector2(s, s)
	# quanto o mapa pode andar para cada lado sem mostrar borda
	_map_range = (tex_size * s - _vp) / 2.0


func _process(delta: float) -> void:
	_t += delta

	# mouse em [-1, 1] a partir do centro da tela
	var m := (get_viewport().get_mouse_position() - _vp / 2.0) / (_vp / 2.0)
	m = m.clamp(Vector2(-1, -1), Vector2(1, 1))

	# mapa: vai e volta devagar (não é tileável, então nada de loop)
	var drift := Vector2(sin(_t * map_speed) * _map_range.x * 0.8,
			sin(_t * map_speed * 0.7) * _map_range.y * 0.8)
	map.position = _vp / 2.0 + drift - m * map_mouse_strength

	# nuvens: andam para a direita e reaparecem na esquerda
	for c: Node2D in clouds.get_children():
		var depth: float = c.get_meta("depth")
		var half_w: float = c.get_meta("half_w")
		var base_x: float = c.get_meta("base_x") + cloud_speed * depth * delta
		if base_x - half_w > _vp.x:
			base_x = -half_w
			c.set_meta("base_y", randf_range(0.0, _vp.y * 0.8))
		c.set_meta("base_x", base_x)
		c.position = Vector2(base_x, c.get_meta("base_y")) - m * cloud_mouse_strength * depth


func _spawn_clouds() -> void:
	for i in cloud_count:
		var depth := randf_range(0.5, 1.5)   # mais profundo = maior, mais rápido, mais opaco
		var cloud := Node2D.new()
		var w := 0.0
		if cloud_texture:
			var sp := Sprite2D.new()
			sp.texture = cloud_texture
			cloud.add_child(sp)
			w = cloud_texture.get_width()
		else:
			w = _build_procedural_cloud(cloud)
		cloud.scale = Vector2.ONE * depth
		cloud.modulate.a = remap(depth, 0.5, 1.5, 0.35, 0.8)
		cloud.set_meta("depth", depth)
		cloud.set_meta("half_w", w * depth / 2.0)
		cloud.set_meta("base_x", randf_range(0.0, _vp.x))
		cloud.set_meta("base_y", randf_range(0.0, _vp.y * 0.8))
		clouds.add_child(cloud)


# Monta uma nuvem juntando "bolinhas" com gradiente radial. Retorna a largura.
func _build_procedural_cloud(parent: Node2D) -> float:
	if _puff == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0.0))
		_puff = GradientTexture2D.new()
		_puff.gradient = g
		_puff.fill = GradientTexture2D.FILL_RADIAL
		_puff.fill_from = Vector2(0.5, 0.5)
		_puff.fill_to = Vector2(1.0, 0.5)
		_puff.width = 256
		_puff.height = 256
	for j in 6:
		var p := Sprite2D.new()
		p.texture = _puff
		p.position = Vector2(randf_range(-140, 140), randf_range(-25, 25))
		p.scale = Vector2.ONE * randf_range(0.6, 1.1)
		parent.add_child(p)
	return 560.0


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(game_scene)


func _on_options_pressed() -> void:
	pass # TODO: abrir tela de opções

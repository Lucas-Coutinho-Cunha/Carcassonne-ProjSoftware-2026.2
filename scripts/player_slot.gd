class_name PlayerSlot
extends PanelContainer

## Um jogador no menu: preview 3D do gato, troca de skin e tipo (Humano/IA).

## Emitido ao clicar em ◀ (-1) ou ▶ (+1). Quem decide a próxima skin livre
## é o menu principal, para não repetir skin entre jogadores.
signal skin_step(dir: int)

## true = coluna da direita: o "Tipo" fica à esquerda do preview.
@export var mirrored := false
@export var preview_animation := "lobbyidle"  # se não existir, tenta "idle"
@export var rotate_speed := 0.6               # rad/s; 0 = parado

var skin := 0
var player_number := 1:
	set(value):
		player_number = value
		_refresh_label()

var is_ai: bool:
	get:
		return %TypeButton.selected == 1
	set(value):
		%TypeButton.select(1 if value else 0)

var _model: Node3D


func _ready() -> void:
	if mirrored:
		%Row.move_child(%TipoBox, 0)

	%Camera.position = Vector3(0, 0.92, 1.7)
	%Camera.look_at(Vector3(0, 0.92, 0))
	%Light.rotation_degrees = Vector3(-45, -30, 0)

	%TypeButton.add_item("Humano")
	%TypeButton.add_item("IA")
	%PrevButton.pressed.connect(func(): skin_step.emit(-1))
	%NextButton.pressed.connect(func(): skin_step.emit(1))

	_model = CatSkins.CAT_SCENE.instantiate()
	_model.position.z = -0.2  # centraliza o gato no eixo de rotação
	%Pivot.add_child(_model)
	_play_preview_animation()
	set_skin(skin)
	_refresh_label()


func _process(delta: float) -> void:
	if is_visible_in_tree():
		%Pivot.rotate_y(rotate_speed * delta)


func set_skin(index: int) -> void:
	skin = index
	if _model:
		CatSkins.apply(_model, skin)
	_refresh_label()


func _refresh_label() -> void:
	if not is_node_ready():
		return
	%SkinLabel.text = "Jogador %d · %s" % [player_number, CatSkins.skin_name(skin)]


func _play_preview_animation() -> void:
	var player := _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null:
		return
	var anim := preview_animation if player.has_animation(preview_animation) else "idle"
	if player.has_animation(anim):
		player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
		player.play(anim)

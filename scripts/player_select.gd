extends Control

const MIN_PLAYERS := 4
const MAX_PLAYERS := 6

@export_file("*.tscn") var next_scene := "res://scenes/game.tscn"
@export_file("*.tscn") var back_scene := "res://scenes/main_menu.tscn"

@onready var count_button: OptionButton = %CountButton

var _left_slots: Array[PlayerSlot] = []
var _right_slots: Array[PlayerSlot] = []
var _all_slots: Array[PlayerSlot] = []


func _ready() -> void:
	for child in %LeftColumn.get_children():
		_left_slots.append(child as PlayerSlot)
	for child in %RightColumn.get_children():
		_right_slots.append(child as PlayerSlot)
	_all_slots.append_array(_left_slots)
	_all_slots.append_array(_right_slots)

	# Skins iniciais diferentes; só o primeiro jogador começa como humano.
	for i in _all_slots.size():
		var slot := _all_slots[i]
		slot.set_skin(i % CatSkins.count())
		slot.is_ai = i != 0
		slot.skin_step.connect(_on_skin_step.bind(slot))

	for n in range(MIN_PLAYERS, MAX_PLAYERS + 1):
		count_button.add_item(str(n), n)
	count_button.select(count_button.get_item_index(clampi(GameState.player_count, MIN_PLAYERS, MAX_PLAYERS)))
	count_button.item_selected.connect(func(_i): _update_layout())

	%StartButton.pressed.connect(_on_start_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	_update_layout()


## Divide os jogadores entre as colunas: 4 = 2+2, 5 = 3+2, 6 = 3+3.
func _update_layout() -> void:
	var total := count_button.get_selected_id()
	var left_count := ceili(total / 2.0)
	var right_count := total - left_count

	var number := 1
	for i in _left_slots.size():
		_left_slots[i].visible = i < left_count
		if _left_slots[i].visible:
			_left_slots[i].player_number = number
			number += 1
	for i in _right_slots.size():
		_right_slots[i].visible = i < right_count
		if _right_slots[i].visible:
			_right_slots[i].player_number = number
			number += 1


## Próxima skin que nenhum outro slot esteja usando.
func _on_skin_step(dir: int, slot: PlayerSlot) -> void:
	var used := {}
	for other in _all_slots:
		if other != slot:
			used[other.skin] = true

	var index := slot.skin
	for _i in CatSkins.count():
		index = posmod(index + dir, CatSkins.count())
		if not used.has(index):
			break
	slot.set_skin(index)


func _on_start_pressed() -> void:
	var players: Array[Dictionary] = []
	for slot in _left_slots + _right_slots:
		if slot.visible:
			players.append({"skin": slot.skin, "is_ai": slot.is_ai})
	GameState.player_count = players.size()
	GameState.players = players
	get_tree().change_scene_to_file(next_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(back_scene)

extends Control


@export var player_scene: PackedScene
@export var game_scene: PackedScene
@export var reset_on_open: bool = true

var _slots_box: VBoxContainer
var _status_label: Label
var _add_button: Button
var _start_button: Button


func _ready() -> void:
	_build_ui()
	Sfx.hook_buttons(self)
	GameSession.roster_changed.connect(_rebuild_slots, CONNECT_DEFERRED)
	if reset_on_open:
		GameSession.reset_to_defaults()
	else:
		_rebuild_slots()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var title: Label = Label.new()
	title.text = "Lobby"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	root.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_slots_box = VBoxContainer.new()
	_slots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_slots_box)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status_label)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	root.add_child(buttons)

	_add_button = Button.new()
	_add_button.text = "Add player"
	_add_button.pressed.connect(_on_add_pressed)
	buttons.add_child(_add_button)

	_start_button = Button.new()
	_start_button.text = "Start game"
	_start_button.pressed.connect(_on_start_pressed)
	buttons.add_child(_start_button)


func _rebuild_slots() -> void:
	for child: Node in _slots_box.get_children():
		_slots_box.remove_child(child)
		child.queue_free()
	for i: int in GameSession.players.size():
		var slot: LobbySlot = LobbySlot.new()
		slot.player_scene = player_scene
		_slots_box.add_child(slot)
		slot.setup(i, i >= GameSession.MIN_PLAYERS)
		slot.remove_requested.connect(_on_remove_requested)

	var count: int = GameSession.players.size()
	_add_button.disabled = count >= GameSession.MAX_PLAYERS
	_start_button.disabled = not GameSession.can_start()
	_status_label.text = "%d players (%d to %d allowed)" % [count, GameSession.MIN_PLAYERS, GameSession.MAX_PLAYERS]


func _on_add_pressed() -> void:
	GameSession.add_player()


func _on_remove_requested(index: int) -> void:
	GameSession.remove_player(index)


func _on_start_pressed() -> void:
	if game_scene == null:
		push_error("Lobby: game_scene is not set")
		return
	for i: int in GameSession.players.size():
		var setup: PlayerSetup = GameSession.players[i]
		if setup.display_name.strip_edges().is_empty():
			setup.display_name = "Player %d" % (i + 1)
	get_tree().change_scene_to_packed(game_scene)

extends Node

const BANK_PATH: String = "res://audio/sound_bank.tres"
const BUS_NAME: StringName = &"SFX"
const VOICES: int = 8

var bank: SoundBank = SoundBank.new()

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	if ResourceLoader.exists(BANK_PATH):
		var loaded: SoundBank = load(BANK_PATH) as SoundBank
		if loaded != null:
			bank = loaded
	else:
		push_warning("Sfx: no sound bank found at %s, the game will be silent" % BANK_PATH)

	var bus: StringName = BUS_NAME
	if AudioServer.get_bus_index(BUS_NAME) == -1:
		bus = &"Master"
	for i: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = bus
		add_child(voice)
		_voices.append(voice)


func play_ui_click() -> void:
	_play(bank.ui_click)


func play_tile_placed() -> void:
	_play(bank.tile_placed)


func play_meeple_placed() -> void:
	_play(bank.meeple_placed)


func play_camera_away() -> void:
	_play(bank.camera_away)



func hook_buttons(root: Node) -> void:
	for button: BaseButton in _find_buttons(root):
		_hook(button)

	var on_node_added: Callable = func(node: Node) -> void:
		var button: BaseButton = node as BaseButton
		if button != null and root.is_ancestor_of(button):
			_hook(button)
	get_tree().node_added.connect(on_node_added)
	root.tree_exiting.connect(
		func() -> void: get_tree().node_added.disconnect(on_node_added),
		CONNECT_ONE_SHOT
	)


func _hook(button: BaseButton) -> void:
	if not button.pressed.is_connected(play_ui_click):
		button.pressed.connect(play_ui_click)


func _find_buttons(node: Node) -> Array[BaseButton]:
	var found: Array[BaseButton] = []
	var as_button: BaseButton = node as BaseButton
	if as_button != null:
		found.append(as_button)
	for child: Node in node.get_children():
		found.append_array(_find_buttons(child))
	return found


func _play(stream: AudioStream) -> void:
	if stream == null or _voices.is_empty():
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.pitch_scale = 1.0 + randf_range(-bank.pitch_variation, bank.pitch_variation)
	voice.play()

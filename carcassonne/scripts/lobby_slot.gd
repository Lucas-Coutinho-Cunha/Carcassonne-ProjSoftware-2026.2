class_name LobbySlot
extends PanelContainer
## One row of the lobby: the player's name, an avatar picker with a 3D preview, and a
## human/bot setting. It edits GameSession.players[index] directly.
## Set `player_scene`, add the slot to the tree, then call setup().

signal remove_requested(index: int)

var player_scene: PackedScene

var _index: int = 0
var _setup: PlayerSetup
var _preview: AvatarPreview
var _avatar_label: Label


func setup(index: int, removable: bool) -> void:
	_index = index
	_setup = GameSession.players[index]

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	add_child(row)

	# Name column.
	var name_column: VBoxContainer = VBoxContainer.new()
	row.add_child(name_column)
	var title: Label = Label.new()
	title.text = "Player %d" % (index + 1)
	name_column.add_child(title)
	var name_edit: LineEdit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(180.0, 0.0)
	name_edit.text = _setup.display_name
	name_edit.placeholder_text = "Player %d" % (index + 1)
	name_edit.text_changed.connect(_on_name_changed)
	name_column.add_child(name_edit)

	# 3D preview of the avatar on the model.
	_preview = AvatarPreview.new()
	_preview.player_scene = player_scene
	row.add_child(_preview)
	_preview.show_avatar(_setup.avatar)

	# Avatar picker and human/bot setting.
	var choice_column: VBoxContainer = VBoxContainer.new()
	choice_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(choice_column)

	var picker: HBoxContainer = HBoxContainer.new()
	choice_column.add_child(picker)
	var previous_button: Button = Button.new()
	previous_button.text = "<"
	previous_button.pressed.connect(_on_step_pressed.bind(-1))
	picker.add_child(previous_button)
	_avatar_label = Label.new()
	_avatar_label.custom_minimum_size = Vector2(120.0, 0.0)
	_avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	picker.add_child(_avatar_label)
	var next_button: Button = Button.new()
	next_button.text = ">"
	next_button.pressed.connect(_on_step_pressed.bind(1))
	picker.add_child(next_button)
	_update_avatar_label()

	var type_option: OptionButton = OptionButton.new()
	type_option.add_item("Human", 0)
	type_option.add_item("Bot", 1)
	type_option.selected = 1 if _setup.is_bot else 0
	type_option.item_selected.connect(_on_type_selected)
	choice_column.add_child(type_option)

	if removable:
		var remove_button: Button = Button.new()
		remove_button.text = "Remove"
		remove_button.pressed.connect(_on_remove_pressed)
		row.add_child(remove_button)


func _update_avatar_label() -> void:
	if _setup.avatar != null:
		_avatar_label.text = _setup.avatar.display_name
	else:
		_avatar_label.text = "-"


func _on_name_changed(new_text: String) -> void:
	_setup.display_name = new_text


func _on_step_pressed(direction: int) -> void:
	GameSession.step_avatar(_index, direction)
	_preview.show_avatar(_setup.avatar)
	_update_avatar_label()


func _on_type_selected(item_index: int) -> void:
	_setup.is_bot = item_index == 1


func _on_remove_pressed() -> void:
	remove_requested.emit(_index)

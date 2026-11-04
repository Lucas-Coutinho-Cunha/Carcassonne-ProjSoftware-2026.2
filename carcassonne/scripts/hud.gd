extends CanvasLayer
## Child of the Game node. Shows ONLY the players' scores, as one card per player, plus the
## "X's turn" banner. Everything is built in code. The old status Label (if your scene still
## has one named "Label") is removed automatically.

## Optional custom font (import a .ttf/.otf and drag it here). Empty = Godot's default font.
@export var font: Font
## Distance from the top-left corner of the screen.
@export var margin: int = 20
@export var card_width: float = 240.0
@export var name_font_size: int = 22
@export var score_font_size: int = 36
## Text of the turn banner; %s is replaced by the player's name.
@export var turn_banner_format: String = "%s's turn"
@export var banner_font_size: int = 64
## Seconds the banner stays fully visible.
@export var banner_hold_time: float = 1.2
## Seconds for the fade out (the fade in takes half of this).
@export var banner_fade_time: float = 0.5

const CARD_BACKGROUND: Color = Color(0.09, 0.09, 0.13, 0.85)
const INACTIVE_ALPHA: float = 0.7

@onready var game: Game = get_parent()

var _card_box: VBoxContainer
var _cards: Array[Card] = []
var _banner_label: Label
var _banner_tween: Tween


## The visual parts of one player's card.
class Card extends RefCounted:
	var panel: PanelContainer
	var score_label: Label
	var normal_style: StyleBoxFlat
	var active_style: StyleBoxFlat
	var shown_score: int = 0
	var tween: Tween


func _ready() -> void:
	var old_label: Node = get_node_or_null("Label")
	if old_label != null:
		old_label.queue_free()

	_card_box = VBoxContainer.new()
	_card_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, margin)
	_card_box.add_theme_constant_override("separation", 10)
	_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_box)
	_build_banner()

	# The first handoff is emitted at the end of Game._ready(), once the players exist.
	game.handoff.connect(_on_handoff)
	game.scores_changed.connect(_on_scores_changed)
	game.game_over.connect(_on_game_over)


# ---------------------------------------------------------------- score cards

func _build_cards() -> void:
	for player: Player in game.players:
		var card: Card = Card.new()
		card.normal_style = _make_style(player.color, false)
		card.active_style = _make_style(player.color, true)

		card.panel = PanelContainer.new()
		card.panel.custom_minimum_size = Vector2(card_width, 0.0)
		card.panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.panel.add_theme_stylebox_override("panel", card.normal_style)
		card.panel.modulate.a = INACTIVE_ALPHA
		_card_box.add_child(card.panel)

		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.panel.add_child(row)

		var name_label: Label = Label.new()
		name_label.text = player.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(name_label, name_font_size)
		row.add_child(name_label)

		card.score_label = Label.new()
		card.score_label.text = str(player.score)
		card.score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		card.score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_style_label(card.score_label, score_font_size)
		row.add_child(card.score_label)

		card.shown_score = player.score
		_cards.append(card)


func _make_style(accent: Color, active: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CARD_BACKGROUND
	style.set_corner_radius_all(14)
	style.border_color = accent
	if active:
		style.set_border_width_all(2)
		style.border_width_left = 12
	else:
		style.border_width_left = 6
	style.content_margin_left = 18.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 6
	return style


func _style_label(label: Label, font_size: int) -> void:
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 4)


## Brightens the card of the player whose turn it is and dims the others.
func _set_active(index: int) -> void:
	for i: int in _cards.size():
		var card: Card = _cards[i]
		var active: bool = i == index
		card.panel.add_theme_stylebox_override("panel", card.active_style if active else card.normal_style)
		var fade: Tween = create_tween()
		fade.tween_property(card.panel, "modulate:a", 1.0 if active else INACTIVE_ALPHA, 0.25)


func _on_scores_changed() -> void:
	for i: int in _cards.size():
		var card: Card = _cards[i]
		var target: int = game.players[i].score
		if target == card.shown_score:
			continue
		if card.tween != null and card.tween.is_valid():
			card.tween.kill()
		# Count up to the new score and flash the number.
		card.score_label.modulate = Color(1.0, 0.85, 0.3)
		card.tween = create_tween()
		card.tween.set_parallel(true)
		card.tween.tween_method(_set_score_text.bind(card), float(card.shown_score), float(target), 0.5)
		card.tween.tween_property(card.score_label, "modulate", Color.WHITE, 0.6)


func _set_score_text(value: float, card: Card) -> void:
	card.shown_score = roundi(value)
	card.score_label.text = str(card.shown_score)


# --------------------------------------------------------------------- banner

func _build_banner() -> void:
	_banner_label = Label.new()
	_banner_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # never blocks clicks on the board
	_style_label(_banner_label, banner_font_size)
	_banner_label.add_theme_constant_override("outline_size", 12)
	_banner_label.modulate.a = 0.0
	add_child(_banner_label)


## Connected to Game.handoff, which fires every time the turn passes to a player.
func _on_handoff(player: Player) -> void:
	if _cards.is_empty():
		_build_cards()
	_set_active(game.players.find(player))
	_show_turn_banner(player)


func _show_turn_banner(player: Player) -> void:
	_banner_label.text = turn_banner_format % player.display_name
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_label.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner_label, "modulate:a", 1.0, banner_fade_time * 0.5)
	_banner_tween.tween_interval(banner_hold_time)
	_banner_tween.tween_property(_banner_label, "modulate:a", 0.0, banner_fade_time)


## End of the game: the winner's name stays on screen.
func _on_game_over(winners: Array) -> void:
	var names: String = ", ".join(winners.map(func(p: Player) -> String: return p.display_name))
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_label.text = "Winner: %s" % names
	_banner_label.modulate.a = 1.0

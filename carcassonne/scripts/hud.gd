extends CanvasLayer
## Child of the Game node, with a Label child named "Label" (anchor it to the top-left).

const HINTS: Dictionary = {
	&"handoff": "Pass the mouse, then click to start your turn",
	&"place_tile": "Click: place tile | R or right click: rotate | wheel: zoom | middle drag: pan",
	&"place_meeple": "Click a marker to place a meeple | right click / Space: skip",
}

@onready var label: Label = $Label
@onready var game: Game = get_parent()

var _banner: String= ""


func _ready() -> void:
	game.sm.state_changed.connect(func(_from: StringName, _to: StringName) -> void: _refresh())
	game.scores_changed.connect(_refresh)
	game.tile_drawn.connect(func(_def: TileDef, _left: int) -> void: _refresh())
	game.game_over.connect(_on_game_over)


func _on_game_over(winners: Array) -> void:
	var names: String = ", ".join(winners.map(func(p: Player) -> String: return p.display_name))
	_banner = "Game over. Winner: %s" % names
	_refresh()


func _refresh() -> void:
	var lines: PackedStringArray = []
	if _banner != "":
		lines.append(_banner)
	else:
		lines.append("%s - %s" % [game.current_player().display_name, HINTS.get(game.sm.current_name, "")])
	lines.append("Tiles left: %d" % game.deck.size())
	for p: Player in game.players:
		lines.append("%s: %d pts, %d meeples" % [p.display_name, p.score, p.meeples_left])
	label.text = "\n".join(lines)

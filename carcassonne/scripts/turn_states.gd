class_name TurnStates


static func left_click(e: InputEvent) -> bool:
	var mb := e as InputEventMouseButton
	return mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT


static func right_click(e: InputEvent) -> bool:
	var mb := e as InputEventMouseButton
	return mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT


static func key(e: InputEvent, keycode: Key) -> bool:
	var k := e as InputEventKey
	return k != null and k.pressed and not k.echo and k.keycode == keycode


class Handoff extends State:
	var _ready_for_click: bool = false

	func enter(_data: Dictionary = {}) -> void:
		_ready_for_click = false
		game.handoff.emit(game.current_player())
		await game.rig.show_player(game.turn_number)
		if game.current_player().is_bot:
			# Bots don't need a click: bring the camera back to the board and carry on.
			await game.rig.show_board(game.turn_number)
			game.sm.change_to.call_deferred(&"draw")
			return
		_ready_for_click = true

	func unhandled_input(event: InputEvent) -> void:
		if _ready_for_click and TurnStates.left_click(event):
			_ready_for_click = false
			game.get_viewport().set_input_as_handled()
			await game.rig.show_board(game.turn_number)
			game.sm.change_to(&"draw")


class Draw extends State:
	func enter(_data := {}) -> void:
		if game.draw_playable_tile():
			var next: StringName = &"bot_turn" if game.current_player().is_bot else &"place_tile"
			game.sm.change_to.call_deferred(next)
		else:
			game.sm.change_to.call_deferred(&"game_end")


class PlaceTile extends State:
	func enter(_data := {}) -> void:
		game.show_ghost()

	func exit() -> void:
		game.hide_ghost()

	func process(_delta: float) -> void:
		var cell := game.world_to_cell(game.mouse_world())
		game.move_ghost(cell, game.board.can_place(game.tile_def, game.rot, cell))

	func unhandled_input(event: InputEvent) -> void:
		if TurnStates.key(event, KEY_R) or TurnStates.right_click(event):
			game.rotate_tile()
		elif TurnStates.left_click(event):
			var cell := game.world_to_cell(game.mouse_world())
			if game.board.can_place(game.tile_def, game.rot, cell):
				game.commit_tile(cell)
				game.sm.change_to(&"place_meeple")


class PlaceMeeple extends State:
	var options: Array[int] = []

	func enter(_data := {}) -> void:
		options.clear()
		if game.current_player().meeples_left > 0:
			var p := game.last_placed
			for i in p.def.features.size():
				if game.board.can_place_meeple(p.cell, i):
					options.append(i)
		if options.is_empty():
			game.sm.change_to.call_deferred(&"score")
			return
		game.show_meeple_slots(options)

	func exit() -> void:
		game.clear_meeple_slots()

	func unhandled_input(event: InputEvent) -> void:
		if TurnStates.left_click(event):
			var i := game.pick_slot(options)
			if i >= 0:
				game.put_meeple(i)
				game.sm.change_to(&"score")
		elif TurnStates.right_click(event) or TurnStates.key(event, KEY_SPACE) or TurnStates.key(event, KEY_ENTER):
			game.sm.change_to(&"score")


class BotTurn extends State:
	const STEP_DELAY := 0.5   # seconds, so the tile and the meeple don't appear instantly

	var _done := false

	func enter(_data := {}) -> void:
		_done = false
		var ai := game.ai
		ai.move_ready.connect(_on_move_ready, CONNECT_ONE_SHOT)
		ai.search_failed.connect(_on_failed, CONNECT_ONE_SHOT)
		if not ai.request_move(CarcassonneAI.context_from_game(game)) and not _done:
			_fallback()

	func exit() -> void:
		if game.ai.move_ready.is_connected(_on_move_ready):
			game.ai.move_ready.disconnect(_on_move_ready)
		if game.ai.search_failed.is_connected(_on_failed):
			game.ai.search_failed.disconnect(_on_failed)

	func _on_move_ready(move: Dictionary, _info: Dictionary) -> void:
		if move.is_empty():
			_fallback()
		else:
			_play(move)

	func _on_failed(reason: String) -> void:
		push_error("Bot search failed: %s" % reason)
		_fallback()

	# Same calls a human click goes through: rot + commit_tile, then put_meeple, then Score.
	func _play(move: Dictionary) -> void:
		if _done:
			return
		_done = true
		await game.get_tree().create_timer(STEP_DELAY).timeout
		if game.sm.current_name != &"bot_turn":
			return
		game.rot = move.rot
		game.commit_tile(move.cell)
		if int(move.get("meeple", -1)) >= 0:
			await game.get_tree().create_timer(STEP_DELAY).timeout
			if game.sm.current_name != &"bot_turn":
				return
			game.put_meeple(move.meeple)
		game.sm.change_to(&"score")

	# If the AI fails, play the first legal tile placement (no meeple) so the game never stalls.
	func _fallback() -> void:
		if _done:
			return
		for cell: Vector2i in game.board.frontier():
			for r: int in 4:
				if game.board.can_place(game.tile_def, r, cell):
					_play({"cell": cell, "rot": r, "meeple": -1})
					return
		_done = true
		game.sm.change_to.call_deferred(&"draw")   # nowhere to place: discard and draw again


class Score extends State:
	func enter(_data := {}) -> void:
		game.apply_results(game.board.collect_completed(game.last_placed.cell))
		game.advance_player()
		game.sm.change_to.call_deferred(&"handoff")


class GameEnd extends State:
	func enter(_data := {}) -> void:
		game.finish_game()

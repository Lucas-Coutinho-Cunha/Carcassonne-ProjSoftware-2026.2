class_name TurnStates
## One turn:  handoff -> draw -> place_tile -> place_meeple -> score -> (next player) handoff
## Transitions triggered from enter() are deferred so the machine never re-enters itself.


static func left_click(e: InputEvent) -> bool:
	var mb := e as InputEventMouseButton
	return mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT


static func right_click(e: InputEvent) -> bool:
	var mb := e as InputEventMouseButton
	return mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT


static func key(e: InputEvent, keycode: Key) -> bool:
	var k := e as InputEventKey
	return k != null and k.pressed and not k.echo and k.keycode == keycode


## "Pass the mouse" screen: waits for a click so the next player starts deliberately.
class Handoff extends State:
	func enter(_data := {}) -> void:
		game.handoff.emit(game.current_player())

	func unhandled_input(event: InputEvent) -> void:
		if TurnStates.left_click(event):
			game.get_viewport().set_input_as_handled()
			game.sm.change_to(&"draw")


class Draw extends State:
	func enter(_data := {}) -> void:
		if game.draw_playable_tile():
			game.sm.change_to.call_deferred(&"place_tile")
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
	var options: Array[int] = []  # feature indexes on the tile just placed

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
			game.sm.change_to(&"score")  # skip placing a meeple


class Score extends State:
	func enter(_data := {}) -> void:
		game.apply_results(game.board.collect_completed(game.last_placed.cell))
		game.advance_player()
		game.sm.change_to.call_deferred(&"handoff")


class GameEnd extends State:
	func enter(_data := {}) -> void:
		game.finish_game()

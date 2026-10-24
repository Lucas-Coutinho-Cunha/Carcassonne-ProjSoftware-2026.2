class_name StateMachine
extends Node

signal state_changed(from: StringName, to: StringName)

var game: Game
var current: State
var current_name: StringName = &""
var _states: Dictionary = {}


func add_state(state_name: StringName, state: State) -> void:
	state.game = game
	_states[state_name] = state


func change_to(state_name: StringName, data := {}) -> void:
	assert(_states.has(state_name), "Unknown state: %s" % state_name)
	if current:
		current.exit()
	var previous := current_name
	current = _states[state_name]
	current_name = state_name
	state_changed.emit(previous, state_name)
	current.enter(data)


func _process(delta: float) -> void:
	if current:
		current.process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current:
		current.unhandled_input(event)

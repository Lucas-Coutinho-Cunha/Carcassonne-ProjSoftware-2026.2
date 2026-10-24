class_name State
extends RefCounted
## Base class for turn states. `game` is assigned by StateMachine.add_state().

var game: Game


func enter(_data := {}) -> void:
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func unhandled_input(_event: InputEvent) -> void:
	pass

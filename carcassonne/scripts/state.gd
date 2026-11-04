class_name State
extends RefCounted

var game: Game


func enter(_data := {}) -> void:
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func unhandled_input(_event: InputEvent) -> void:
	pass

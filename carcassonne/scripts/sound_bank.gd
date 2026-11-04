class_name SoundBank
extends Resource

@export var ui_click: AudioStream
@export var tile_placed: AudioStream
@export var meeple_placed: AudioStream
@export var camera_away: AudioStream

@export_range(0.0, 0.3, 0.01) var pitch_variation: float = 0.05

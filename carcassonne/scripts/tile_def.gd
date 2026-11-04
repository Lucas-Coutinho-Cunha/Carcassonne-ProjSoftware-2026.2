class_name TileDef
extends Resource

enum Side { N, E, S, W }
enum Kind { FIELD, ROAD, CITY, MONASTERY }

@export var id: StringName
@export var count: int = 1
@export var edges: Array[int] = [Kind.FIELD, Kind.FIELD, Kind.FIELD, Kind.FIELD]
@export var features: Array[Dictionary] = []
@export var texture: Texture2D


static func feature(kind: int, sides: Array, anchor: Vector2 = Vector2.ZERO, shield: bool = false) -> Dictionary:
	return {"kind": kind, "sides": sides, "anchor": anchor, "shield": shield}

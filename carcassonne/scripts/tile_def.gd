class_name TileDef
extends Resource
## Static description of one tile TYPE (not a tile on the board).
## Conventions: sides are ordered N, E, S, W (clockwise). N = -Z in the 3D world.
## The tile mesh must be authored with its "north" edge pointing to -Z.

enum Side { N, E, S, W }
enum Kind { FIELD, ROAD, CITY, MONASTERY }

@export var id: StringName
@export var count := 1
## Terrain on each side, used for placement validation. Index = Side.
@export var edges: Array[int] = [Kind.FIELD, Kind.FIELD, Kind.FIELD, Kind.FIELD]
## Scoring features, see feature(). Fields (farmers) are not modelled yet.
@export var features: Array[Dictionary] = []
## Optional 3D mesh scene. If null, Game builds a coloured placeholder box.
@export var mesh: PackedScene


## sides: the Side values this feature touches (unrotated).
## anchor: where the meeple stands, in tile-local units (-0.5..0.5), x = east, y = south.
static func feature(kind: Kind, sides: Array, anchor := Vector2.ZERO, shield := false) -> Dictionary:
	return {"kind": kind, "sides": sides, "anchor": anchor, "shield": shield}

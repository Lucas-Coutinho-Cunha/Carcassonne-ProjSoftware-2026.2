class_name TileDef
extends Resource
## Static description of one tile TYPE (not a tile on the board).
## Conventions: sides are ordered N, E, S, W (clockwise). N = -Z in the 3D world.
## The texture must be drawn "north up": the top of the image is the tile's N edge.

enum Side { N, E, S, W }
enum Kind { FIELD, ROAD, CITY, MONASTERY }

@export var id: StringName
@export var count: int = 1
## Terrain on each side, used for placement validation. Index = Side.
@export var edges: Array[int] = [Kind.FIELD, Kind.FIELD, Kind.FIELD, Kind.FIELD]
## Scoring features, see feature(). Fields (farmers) are not modelled yet.
@export var features: Array[Dictionary] = []
## Picture wrapped on the shared tile mesh. Loaded by TileCatalog from the tile id.
@export var texture: Texture2D


## sides: the Side values this feature touches (unrotated).
## anchor: where the meeple stands, in tile-local units (-0.5..0.5), x = east, y = south.
static func feature(kind: int, sides: Array, anchor: Vector2 = Vector2.ZERO, shield: bool = false) -> Dictionary:
	return {"kind": kind, "sides": sides, "anchor": anchor, "shield": shield}

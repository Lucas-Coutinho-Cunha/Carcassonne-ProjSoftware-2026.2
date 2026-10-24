class_name TileCatalog
extends RefCounted
## Starter subset of tiles so the game is playable. Extend _defs() with the rest
## of the official tile distribution (and set `mesh` on each when your 3D
## models are ready). Counts below are placeholders for testing.

const F := TileDef.Kind.FIELD
const R := TileDef.Kind.ROAD
const C := TileDef.Kind.CITY
const M := TileDef.Kind.MONASTERY
const N := TileDef.Side.N
const E := TileDef.Side.E
const S := TileDef.Side.S
const W := TileDef.Side.W

static var _cache: Array[TileDef] = []


static func start_tile() -> TileDef:
	return _defs()[0]


static func build_deck() -> Array[TileDef]:
	var deck: Array[TileDef] = []
	var start := start_tile()
	for def in _defs():
		# One copy of the starting tile is already on the board.
		var n := def.count - (1 if def == start else 0)
		for i in n:
			deck.append(def)
	return deck


static func _defs() -> Array[TileDef]:
	if _cache.is_empty():
		_cache.assign([
			# Index 0 is the starting tile: city on N, road running E-W.
			_t(&"start_city_road", 4, [C, R, F, R], [
				TileDef.feature(C, [N], Vector2(0, -0.32)),
				TileDef.feature(R, [E, W], Vector2(0, 0.12)),
			]),
			_t(&"road_straight", 8, [R, F, R, F], [
				TileDef.feature(R, [N, S]),
			]),
			_t(&"road_curve", 9, [F, F, R, R], [
				TileDef.feature(R, [S, W], Vector2(-0.15, 0.15)),
			]),
			_t(&"city_cap", 5, [C, F, F, F], [
				TileDef.feature(C, [N], Vector2(0, -0.3)),
			]),
			_t(&"city_bridge", 1, [C, F, C, F], [
				TileDef.feature(C, [N, S]),
			]),
			_t(&"city_full_shield", 1, [C, C, C, C], [
				TileDef.feature(C, [N, E, S, W], Vector2.ZERO, true),
			]),
			_t(&"monastery", 4, [F, F, F, F], [
				TileDef.feature(M, []),
			]),
			_t(&"monastery_road", 2, [F, F, R, F], [
				TileDef.feature(M, [], Vector2(0, -0.1)),
				TileDef.feature(R, [S], Vector2(0, 0.35)),
			]),
		])
	return _cache


static func _t(id: StringName, count: int, edges: Array, features: Array) -> TileDef:
	var t := TileDef.new()
	t.id = id
	t.count = count
	t.edges.assign(edges)
	t.features.assign(features)
	return t

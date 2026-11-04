class_name TileCatalog
extends RefCounted

const F: int = TileDef.Kind.FIELD
const R: int = TileDef.Kind.ROAD
const C: int = TileDef.Kind.CITY
const M: int = TileDef.Kind.MONASTERY
const N: int = TileDef.Side.N
const E: int = TileDef.Side.E
const S: int = TileDef.Side.S
const W: int = TileDef.Side.W

const START_TILE_ID: StringName = &"start_tile"
const TEXTURE_FOLDER: String = "res://tiles/textures"
const TEXTURE_EXTENSIONS: Array[String] = ["png", "webp", "jpg"]

static var _cache: Array[TileDef] = []


static func start_tile() -> TileDef:
	for def: TileDef in all_defs():
		if def.id == START_TILE_ID:
			return def
	push_error("TileCatalog: no entry with id %s" % START_TILE_ID)
	return all_defs()[0]


static func build_deck() -> Array[TileDef]:
	var deck: Array[TileDef] = []
	var start: TileDef = start_tile()
	for def: TileDef in all_defs():
		var copies: int = def.count - (1 if def == start else 0)
		for i: int in copies:
			deck.append(def)
	return deck


static func all_defs() -> Array[TileDef]:
	if _cache.is_empty():
		_cache.assign([
			# ============================== Sheet row 1 ==============================
			_t(&"monastery", 4, [F, F, F, F], [
				_ft(M, [], Vector2.ZERO),
			]),
			_t(&"monastery_road", 2, [F, F, R, F], [
				_ft(M, [], Vector2(0.0, -0.1)),
				_ft(R, [S], Vector2(0.0, 0.35)),
			]),
			_t(&"city_full_shield", 1, [C, C, C, C], [
				_ft(C, [N, E, S, W], Vector2.ZERO, true),
			]),
			_t(&"city_three", 3, [C, C, F, C], [
				_ft(C, [N, E, W], Vector2(0.0, -0.1)),
			]),
			_t(&"city_three_shield", 1, [C, C, F, C], [
				_ft(C, [N, E, W], Vector2(0.0, -0.1), true),
			]),

			# ============================== Sheet row 2 ==============================
			_t(&"city_three_road", 1, [C, C, R, C], [
				_ft(C, [N, E, W], Vector2(0.0, -0.15)),
				_ft(R, [S], Vector2(0.0, 0.38)),
			]),
			_t(&"city_three_road_shield", 2, [C, C, R, C], [
				_ft(C, [N, E, W], Vector2(0.0, -0.15), true),
				_ft(R, [S], Vector2(0.0, 0.38)),
			]),
			_t(&"city_corner", 3, [C, F, F, C], [
				_ft(C, [N, W], Vector2(-0.2, -0.2)),
			]),
			_t(&"city_corner_shield", 2, [C, F, F, C], [
				_ft(C, [N, W], Vector2(-0.2, -0.2), true),
			]),
			_t(&"city_corner_road", 3, [C, R, R, C], [
				_ft(C, [N, W], Vector2(-0.2, -0.2)),
				_ft(R, [E, S], Vector2(0.2, 0.2)),
			]),

			# ============================== Sheet row 3 ==============================
			_t(&"city_corner_road_shield", 2, [C, R, R, C], [
				_ft(C, [N, W], Vector2(-0.2, -0.2), true),
				_ft(R, [E, S], Vector2(0.2, 0.2)),
			]),
			_t(&"city_band", 1, [F, C, F, C], [
				_ft(C, [E, W], Vector2.ZERO),
			]),
			_t(&"city_band_shield", 2, [F, C, F, C], [
				_ft(C, [E, W], Vector2.ZERO, true),
			]),
			_t(&"city_caps_adjacent", 2, [C, F, F, C], [
				_ft(C, [N], Vector2(0.0, -0.32)),
				_ft(C, [W], Vector2(-0.32, 0.0)),
			]),
			_t(&"city_caps_opposite", 3, [C, F, C, F], [
				_ft(C, [N], Vector2(0.0, -0.32)),
				_ft(C, [S], Vector2(0.0, 0.32)),
			]),

			# ============================== Sheet row 4 ==============================
			_t(&"city_cap", 5, [C, F, F, F], [
				_ft(C, [N], Vector2(0.0, -0.3)),
			]),
			_t(&"city_cap_road_curve_left", 3, [C, F, R, R], [
				_ft(C, [N], Vector2(0.0, -0.32)),
				_ft(R, [S, W], Vector2(-0.2, 0.2)),
			]),
			_t(&"city_cap_road_curve_right", 3, [C, R, R, F], [
				_ft(C, [N], Vector2(0.0, -0.32)),
				_ft(R, [E, S], Vector2(0.2, 0.2)),
			]),
			_t(&"city_cap_road_junction", 3, [C, R, R, R], [
				_ft(C, [N], Vector2(0.0, -0.32)),
				_ft(R, [E], Vector2(0.35, 0.05)),
				_ft(R, [S], Vector2(0.0, 0.38)),
				_ft(R, [W], Vector2(-0.35, 0.05)),
			]),
			_t(&"city_cap_road_straight", 3, [C, R, F, R], [
				_ft(C, [N], Vector2(0.0, -0.3)),
				_ft(R, [E, W], Vector2(0.0, 0.15)),
			]),

			# ============================== Sheet row 5 ==============================
			_t(&"road_straight", 8, [R, F, R, F], [
				_ft(R, [N, S], Vector2.ZERO),
			]),
			_t(&"road_curve", 9, [F, F, R, R], [
				_ft(R, [S, W], Vector2(-0.15, 0.15)),
			]),
			_t(&"road_junction", 4, [F, R, R, R], [
				_ft(R, [E], Vector2(0.35, 0.05)),
				_ft(R, [S], Vector2(0.0, 0.35)),
				_ft(R, [W], Vector2(-0.35, 0.05)),
			]),
			_t(&"road_crossroads", 1, [R, R, R, R], [
				_ft(R, [N], Vector2(0.0, -0.35)),
				_ft(R, [E], Vector2(0.35, 0.0)),
				_ft(R, [S], Vector2(0.0, 0.35)),
				_ft(R, [W], Vector2(-0.35, 0.0)),
			]),
			_t(&"start_tile", 1, [C, R, F, R], [
				_ft(C, [N], Vector2(0.0, -0.3)),
				_ft(R, [E, W], Vector2(0.0, 0.15)),
			]),
		])
	return _cache


static func _t(id: StringName, count: int, edges: Array, features: Array) -> TileDef:
	var def: TileDef = TileDef.new()
	def.id = id
	def.count = count
	def.edges.assign(edges)
	def.features.assign(features)
	def.texture = _load_texture(id)
	return def


static func _ft(kind: int, sides: Array, anchor: Vector2 = Vector2.ZERO, shield: bool = false) -> Dictionary:
	return TileDef.feature(kind, sides, anchor, shield)


static func _load_texture(id: StringName) -> Texture2D:
	for extension: String in TEXTURE_EXTENSIONS:
		var path: String = "%s/%s.%s" % [TEXTURE_FOLDER, id, extension]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

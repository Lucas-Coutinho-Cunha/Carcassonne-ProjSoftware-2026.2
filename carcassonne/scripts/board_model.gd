class_name BoardModel
extends RefCounted
## Pure game logic, no nodes. Cells are Vector2i; x = east, y = south (world Z).
## Cities and roads are tracked with a union-find: every feature of every placed
## tile is a node, and touching features are merged as tiles are placed.

const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)] # N E S W


class Placed:
	var def: TileDef
	var rot := 0                      # clockwise quarter turns
	var cell := Vector2i.ZERO
	var feature_ids: Array[int] = []  # index-aligned with def.features
	var side_feature: Array[int] = [-1, -1, -1, -1]  # board side -> feature id

	func edge_at(side: int) -> int:
		return def.edges[posmod(side - rot, 4)]


class Feat:
	var kind := 0
	var open_ends := 0
	var tiles: Dictionary = {}          # Vector2i -> true
	var shields := 0
	var meeples: Array[Dictionary] = [] # {player, cell, index}
	var scored := false


var tiles: Dictionary = {}              # Vector2i -> Placed
var _parent: Array[int] = []
var _feats: Array[Feat] = []


# ---------------------------------------------------------------- placement

func can_place(def: TileDef, rot: int, cell: Vector2i) -> bool:
	if tiles.has(cell):
		return false
	var touching := false
	for side in 4:
		var n: Placed = tiles.get(cell + DIRS[side])
		if n == null:
			continue
		touching = true
		if n.edge_at((side + 2) % 4) != def.edges[posmod(side - rot, 4)]:
			return false
	return touching or tiles.is_empty()


func frontier() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var seen := {}
	for c: Vector2i in tiles:
		for d in DIRS:
			var n := c + d
			if not tiles.has(n) and not seen.has(n):
				seen[n] = true
				out.append(n)
	return out


func has_any_placement(def: TileDef) -> bool:
	for cell in frontier():
		for r in 4:
			if can_place(def, r, cell):
				return true
	return false


func place(def: TileDef, rot: int, cell: Vector2i) -> Placed:
	var p := Placed.new()
	p.def = def
	p.rot = rot
	p.cell = cell
	for i in def.features.size():
		var fd: Dictionary = def.features[i]
		var f := Feat.new()
		f.kind = fd.kind
		f.tiles[cell] = true
		f.shields = 1 if fd.get("shield", false) else 0
		var id := _feats.size()
		_feats.append(f)
		_parent.append(id)
		p.feature_ids.append(id)
		if f.kind == TileDef.Kind.CITY or f.kind == TileDef.Kind.ROAD:
			for s in fd.sides:
				p.side_feature[(s + rot) % 4] = id
				f.open_ends += 1
	tiles[cell] = p
	# Merge with the features on the neighbouring tiles.
	for side in 4:
		var mine := p.side_feature[side]
		if mine < 0:
			continue
		var n: Placed = tiles.get(cell + DIRS[side])
		if n != null:
			_join(mine, n.side_feature[(side + 2) % 4])
	return p


func _find(i: int) -> int:
	while _parent[i] != i:
		_parent[i] = _parent[_parent[i]]
		i = _parent[i]
	return i


func _join(a: int, b: int) -> void:
	var ra := _find(a)
	var rb := _find(b)
	if ra == rb:                      # closes a loop inside one feature
		_feats[ra].open_ends -= 2
		return
	var fa := _feats[ra]
	var fb := _feats[rb]
	_parent[rb] = ra
	fa.open_ends += fb.open_ends - 2  # the two touching edges are now closed
	fa.tiles.merge(fb.tiles)
	fa.shields += fb.shields
	fa.meeples.append_array(fb.meeples)


# ------------------------------------------------------------------ meeples

func _root(cell: Vector2i, index: int) -> Feat:
	var p: Placed = tiles[cell]
	return _feats[_find(p.feature_ids[index])]


func can_place_meeple(cell: Vector2i, index: int) -> bool:
	return _root(cell, index).meeples.is_empty()


func place_meeple(cell: Vector2i, index: int, player: int) -> void:
	_root(cell, index).meeples.append({"player": player, "cell": cell, "index": index})


# ------------------------------------------------------------------ scoring

## Call right after a tile (and optional meeple) was placed. Returns one entry per
## feature that just got completed: {kind, points, winners, meeples}.
## Meeples on those features are removed from the model; the caller returns them.
func collect_completed(cell: Vector2i) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for dx in range(-1, 2):          # 3x3 covers the placed tile and nearby monasteries
		for dy in range(-1, 2):
			var p: Placed = tiles.get(cell + Vector2i(dx, dy))
			if p == null:
				continue
			for id in p.feature_ids:
				var r := _find(id)
				if seen.has(r):
					continue
				seen[r] = true
				var f := _feats[r]
				if not f.scored and _is_complete(f):
					out.append(_resolve(f, false))
	return out


## End-of-game scoring for everything still unfinished that has meeples.
func final_scoring() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in _feats.size():
		if _parent[i] != i:
			continue
		var f := _feats[i]
		if not f.scored and not f.meeples.is_empty():
			out.append(_resolve(f, true))
	return out


func _is_complete(f: Feat) -> bool:
	match f.kind:
		TileDef.Kind.CITY, TileDef.Kind.ROAD:
			return f.open_ends == 0
		TileDef.Kind.MONASTERY:
			return _neighbor_count(f.tiles.keys()[0]) == 8
	return false


func _neighbor_count(cell: Vector2i) -> int:
	var n := 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if (dx != 0 or dy != 0) and tiles.has(cell + Vector2i(dx, dy)):
				n += 1
	return n


func _resolve(f: Feat, final: bool) -> Dictionary:
	var pts := 0
	match f.kind:
		TileDef.Kind.CITY:
			pts = (f.tiles.size() + f.shields) * (1 if final else 2)
		TileDef.Kind.ROAD:
			pts = f.tiles.size()
		TileDef.Kind.MONASTERY:
			pts = 1 + _neighbor_count(f.tiles.keys()[0])  # 9 when complete
	var counts := {}
	for m in f.meeples:
		counts[m.player] = counts.get(m.player, 0) + 1
	var best := 0
	for c in counts.values():
		best = maxi(best, c)
	var winners: Array[int] = []
	for pl in counts:
		if counts[pl] == best:
			winners.append(pl)
	var returned := f.meeples.duplicate()
	f.meeples.clear()
	f.scored = true
	return {"kind": f.kind, "points": pts, "winners": winners, "meeples": returned}

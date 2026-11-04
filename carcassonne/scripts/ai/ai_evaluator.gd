class_name AIEvaluator
extends RefCounted

#precisa ajustar
const DEFAULT_WEIGHTS := {
	"city_open_decay": 0.55,
	"road_open_decay": 0.35,
	"monastery_growth": 0.8,
	"meeple_in_hand": 1.6,
	"hopeless_penalty": 0.9,
	"opponent_weight": 1.0,     # > 1 deixa a IA "rancorosa"(isso é uma palavra?), < 1 gananciosa
}


static func utilities(state: AIBoardSim.SimState, w: Dictionary = DEFAULT_WEIGHTS) -> PackedFloat32Array:
	var n := state.players()
	var out := PackedFloat32Array()
	out.resize(n)
	for p: int in n:
		out[p] = float(state.scores[p]) + float(state.meeples[p]) * float(w.meeple_in_hand)

	var board := state.board
	for i: int in board._feats.size():
		if board._parent[i] != i:
			continue
		var f: BoardModel.Feat = board._feats[i]
		if f.scored or f.meeples.is_empty():
			continue
		var value := _projected_value(board, f, w)
		# Maioria de meeples leva os pontos mas empate divide
		var counts := {}
		for m: Dictionary in f.meeples:
			counts[m.player] = counts.get(m.player, 0) + 1
		var best := 0
		for c: int in counts.values():
			best = maxi(best, c)
		var winners: Array = []
		for pl: int in counts:
			if counts[pl] == best:
				winners.append(pl)
		var share := value / float(winners.size())
		for pl: int in winners:
			out[pl] += share
	return out


# de (Hans im Glück / Z-Man Games, livro de regras do Carcassonne base)
static func _projected_value(board: BoardModel, f: BoardModel.Feat, w: Dictionary) -> float:
	match f.kind:
		TileDef.Kind.CITY:
			var size_c := float(f.tiles.size() + f.shields)
			var v := size_c * (1.0 + _completion_chance(f.open_ends, float(w.city_open_decay)))
			if f.open_ends > 3:
				v -= float(f.open_ends - 3) * float(w.hopeless_penalty)
			return v
		TileDef.Kind.ROAD:
			return float(f.tiles.size()) + _completion_chance(f.open_ends, float(w.road_open_decay)) * 0.5
		TileDef.Kind.MONASTERY:
			var have := AIBoardSim.neighbour_count(board, f.tiles.keys()[0])
			return 1.0 + float(have) + float(8 - have) * float(w.monastery_growth)
	return 0.0


static func _completion_chance(open_ends: int, decay: float) -> float:
	if open_ends <= 0:
		return 1.0
	return 1.0 / (1.0 + float(open_ends) * decay)


static func relative(util: PackedFloat32Array, pov: int, w: Dictionary = DEFAULT_WEIGHTS) -> float:
	var best_other := -INF
	for p: int in util.size():
		if p != pov:
			best_other = maxf(best_other, util[p])
	if best_other == -INF:
		return util[pov]
	return util[pov] - best_other * float(w.opponent_weight)

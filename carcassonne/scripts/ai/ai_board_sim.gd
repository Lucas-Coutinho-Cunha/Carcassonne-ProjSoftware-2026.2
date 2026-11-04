## simulação da ia aqui
class_name AIBoardSim
extends RefCounted


class SimState extends RefCounted:
	var board: BoardModel
	var scores: PackedInt32Array
	var meeples: PackedInt32Array
	var deck: Dictionary = {}   
	var turn: int = 0  

	func players() -> int:
		return scores.size()

	func copy() -> SimState:
		var s := SimState.new()
		s.board = AIBoardSim.clone_board(board)
		s.scores = scores.duplicate()
		s.meeples = meeples.duplicate()
		s.deck = deck.duplicate()
		s.turn = turn
		return s


# adivinha, copia a board lol
static func clone_board(src: BoardModel) -> BoardModel:
	var dst := BoardModel.new()
	for cell: Vector2i in src.tiles:
		var p: BoardModel.Placed = src.tiles[cell]
		var q := BoardModel.Placed.new()
		q.def = p.def
		q.rot = p.rot
		q.cell = p.cell
		q.feature_ids = p.feature_ids.duplicate()
		q.side_feature = p.side_feature.duplicate()
		dst.tiles[cell] = q
	dst._parent = src._parent.duplicate()
	var feats: Array[BoardModel.Feat] = []
	for f: BoardModel.Feat in src._feats:
		var g := BoardModel.Feat.new()
		g.kind = f.kind
		g.open_ends = f.open_ends
		g.tiles = f.tiles.duplicate()
		g.shields = f.shields
		g.scored = f.scored
		var ms: Array[Dictionary] = []
		for m: Dictionary in f.meeples:
			ms.append(m.duplicate())
		g.meeples = ms
		feats.append(g)
	dst._feats = feats
	return dst



static func legal_moves(state: SimState, def: TileDef, with_meeples: bool = true) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var board := state.board
	var has_meeple: bool = with_meeples and state.meeples[state.turn] > 0
	for cell: Vector2i in board.frontier():
		for rot: int in 4:
			if not board.can_place(def, rot, cell):
				continue
			out.append({"cell": cell, "rot": rot, "meeple": -1})
			if not has_meeple:
				continue
			# A feature só pode ser reivindicada se estiver livre DEPOIS da fusão com as vizinhas, então precisa de um tabuleiro de prova com a peça já posta.
			var probe := clone_board(board)
			probe.place(def, rot, cell)
			for i: int in def.features.size():
				if probe.can_place_meeple(cell, i):
					out.append({"cell": cell, "rot": rot, "meeple": i})
	return out


static func apply(state: SimState, def: TileDef, move: Dictionary) -> SimState:
	var s := state.copy()
	var mover: int = s.turn
	s.board.place(def, move.rot, move.cell)
	var mi: int = move.get("meeple", -1)
	if mi >= 0 and s.meeples[mover] > 0 and s.board.can_place_meeple(move.cell, mi):
		s.board.place_meeple(move.cell, mi, mover)
		s.meeples[mover] -= 1
	for r: Dictionary in s.board.collect_completed(move.cell):
		for pid: int in r.winners:
			s.scores[pid] += r.points
		for m: Dictionary in r.meeples:
			s.meeples[m.player] += 1
	if s.deck.get(def, 0) > 0:
		s.deck[def] -= 1
		if s.deck[def] <= 0:
			s.deck.erase(def)
	s.turn = (mover + 1) % s.players()
	return s


# wuantas das 8 cwlulas ao redor estão ocupadas (progresso de um mosteiro)
static func neighbour_count(board: BoardModel, cell: Vector2i) -> int:
	var n := 0
	for dx: int in range(-1, 2):
		for dy: int in range(-1, 2):
			if (dx != 0 or dy != 0) and board.tiles.has(cell + Vector2i(dx, dy)):
				n += 1
	return n

#iwnndy
class_name CarcassonneAI
extends Node

# API SAIDA AQUI
# move = {cell: Vector2i, rot: int, meeple: int, value: float}
#   meeple == -1 -> não colocar meeple neste turno
#   move  == {}  -> a peça sorteada não encaixa em lugar nenhum
# info = {nodes, moves, depth, value, ms, truncated}
signal move_ready(move: Dictionary, info: Dictionary)
signal search_failed(reason: String)

#profundidade da busca
@export_range(1, 8) var difficulty: int = 2
#quantos lanes sao aprofundados
@export_range(1, 64) var beam_width: int = 8
# quanidade de amostras
@export_range(1, 12) var chance_samples: int = 2

@export_range(2, 400) var interior_moves: int = 12
@export_range(1, 16) var interior_beam: int = 3


@export var max_time_ms: int = 4000
@export var weights: Dictionary = AIEvaluator.DEFAULT_WEIGHTS.duplicate()

var _thread: Thread
var _mutex := Mutex.new()
var _abort := false
var _result: Dictionary = {}
var _info: Dictionary = {}
var _has_result := false
var _deadline := 0
var _nodes := 0
var _rng := RandomNumberGenerator.new()



# API ENTRADA AQUI
static func context_from_game(game: Game, player_id: int = -1) -> Dictionary:
	var scores := PackedInt32Array()
	var meeples := PackedInt32Array()
	scores.resize(game.players.size())
	meeples.resize(game.players.size())
	for p: Player in game.players:
		scores[p.id] = p.score
		meeples[p.id] = p.meeples_left
	return {
		"board": game.board,
		"tile": game.tile_def,
		"turn": game.current if player_id < 0 else player_id,
		"scores": scores,
		"meeples": meeples,
		"deck": game.deck,
	}


# API ENTRADA AQUI
func request_move(ctx: Dictionary) -> bool:
	if is_thinking():
		return false
	var state := _state_from_context(ctx)
	if state == null:
		search_failed.emit("erro, o contexto parece invalido")
		return false
	var def: TileDef = ctx.tile
	_mutex.lock()
	_abort = false
	_has_result = false
	_result = {}
	_info = {}
	_mutex.unlock()
	_thread = Thread.new()
	var err := _thread.start(_worker.bind(state, def))
	if err != OK:
		_thread = null
		search_failed.emit("thread init falhou (%d)" % err)
		return false
	return true


# API ENTRADA AQUI (essa bloqueia)
func think_now(ctx: Dictionary) -> Dictionary:
	var state := _state_from_context(ctx)
	if state == null:
		return {}
	var out := _search_root(state, ctx.tile)
	return out[0]


func is_thinking() -> bool:
	return _thread != null and _thread.is_alive()


func has_result() -> bool:
	_mutex.lock()
	var h := _has_result
	_mutex.unlock()
	return h


# API SAIDA AQUI (versao por pooling)
func take_result() -> Dictionary:
	_mutex.lock()
	var r := _result
	_has_result = false
	_mutex.unlock()
	return r


# {nodes, moves, depth, value, ms} 
func last_info() -> Dictionary:
	_mutex.lock()
	var i := _info.duplicate()
	_mutex.unlock()
	return i

func cancel() -> void:
	_mutex.lock()
	_abort = true
	_mutex.unlock()

func join() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null

func _exit_tree() -> void:
	cancel()
	join()
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		cancel()
		join()




func _worker(state: AIBoardSim.SimState, def: TileDef) -> void:
	var t0 := Time.get_ticks_msec()
	var out := _search_root(state, def)
	_mutex.lock()
	_result = out[0]
	_info = out[1]
	_info["ms"] = Time.get_ticks_msec() - t0
	_has_result = true
	_mutex.unlock()
	_finish.call_deferred()


## Volta para a main thread, então o sinal é seguro para código de cena/UI.
func _finish() -> void:
	join()
	_mutex.lock()
	var r := _result
	var i := _info.duplicate()
	_mutex.unlock()
	move_ready.emit(r, i)

#algo de procura
func _search_root(state: AIBoardSim.SimState, def: TileDef) -> Array:
	_nodes = 0
	_deadline = Time.get_ticks_msec() + max_time_ms
	_rng.seed = hash([state.board.tiles.size(), state.turn, def.id])
	var me := state.turn
	var moves := AIBoardSim.legal_moves(state, def)
	if moves.is_empty():
		return [{}, {"nodes": 0, "moves": 0, "depth": difficulty, "value": 0.0, "reason": "sem posição legal"}]

	var scored: Array[Dictionary] = []
	for m: Dictionary in moves:
		var child := AIBoardSim.apply(state, def, m)
		_nodes += 1
		var v := AIEvaluator.relative(AIEvaluator.utilities(child, weights), me, weights)
		scored.append({"move": m, "value": v})
		if _stop():
			break
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.value > b.value)

	var best: Dictionary = scored[0].move
	var best_value: float = scored[0].value
	if difficulty >= 2:
		best_value = -INF
		var limit := mini(beam_width, scored.size())
		for i: int in limit:
			if _stop():
				break
			var entry: Dictionary = scored[i]
			var child := AIBoardSim.apply(state, def, entry.move)
			var v := AIEvaluator.relative(_chance(child, difficulty - 1), me, weights)
			if v > best_value:
				best_value = v
				best = entry.move
		if best_value == -INF:        # tempo estourou antes de qualquer resultado fundo
			best = scored[0].move
			best_value = scored[0].value

	var out := best.duplicate()
	out["value"] = best_value
	return [out, {
		"nodes": _nodes, "moves": moves.size(), "depth": difficulty,
		"value": best_value, "truncated": _stop(),
	}]


# nó interno
func _search(state: AIBoardSim.SimState, def: TileDef, depth: int) -> PackedFloat32Array:
	_nodes += 1
	var mover := state.turn
	var moves := AIBoardSim.legal_moves(state, def)
	if moves.is_empty() or _stop():
		return AIEvaluator.utilities(state, weights)

	var children: Array[Dictionary] = []
	for m: Dictionary in _narrow(state, moves):
		var child := AIBoardSim.apply(state, def, m)
		children.append({"state": child, "util": AIEvaluator.utilities(child, weights)})
		if _stop():
			break
	if children.is_empty():
		return AIEvaluator.utilities(state, weights)
	children.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.util[mover] > b.util[mover])

	if depth <= 1:
		return children[0].util

	var best_util: PackedFloat32Array = children[0].util
	var best_value := -INF
	for i: int in mini(interior_beam, children.size()):
		var util := _chance(children[i].state, depth - 1)
		if util[mover] > best_value:
			best_value = util[mover]
			best_util = util
		if _stop():
			break
	return best_util


func _chance(state: AIBoardSim.SimState, depth: int) -> PackedFloat32Array:
	if depth <= 0 or _stop():
		return AIEvaluator.utilities(state, weights)
	var sample := _sample_deck(state)
	if sample.is_empty():
		return AIEvaluator.utilities(state, weights)
	var acc := PackedFloat32Array()
	acc.resize(state.players())
	var total := 0.0
	for entry: Array in sample:
		var weight := float(entry[1])
		var util := _search(state, entry[0], depth)
		for p: int in acc.size():
			acc[p] += util[p] * weight
		total += weight
	if total > 0.0:
		for p: int in acc.size():
			acc[p] /= total
	return acc




func _sample_deck(state: AIBoardSim.SimState) -> Array:
	var types: Array = []
	var total := 0
	for def: TileDef in state.deck:
		var c: int = state.deck[def]
		if c > 0:
			types.append([def, c])
			total += c
	if types.is_empty():
		return []
	if chance_samples >= types.size():
		return types
	var out: Array = []
	for i: int in chance_samples:
		var pick := _rng.randi_range(0, total - 1)
		var acc := 0
		for j: int in types.size():
			acc += types[j][1]
			if pick < acc:
				out.append([types[j][0], 1.0])
				total -= types[j][1]
				types.remove_at(j)
				break
	return out



func _narrow(state: AIBoardSim.SimState, moves: Array[Dictionary]) -> Array[Dictionary]:
	if moves.size() <= interior_moves:
		return moves
	var board := state.board
	var keyed: Array[Dictionary] = moves.duplicate()
	keyed.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ka := AIBoardSim.neighbour_count(board, a.cell) * 2 + (1 if a.meeple >= 0 else 0)
		var kb := AIBoardSim.neighbour_count(board, b.cell) * 2 + (1 if b.meeple >= 0 else 0)
		return ka > kb)
	var out: Array[Dictionary] = []
	out.assign(keyed.slice(0, interior_moves))
	return out


func _stop() -> bool:
	if Time.get_ticks_msec() > _deadline:
		return true
	_mutex.lock()
	var a := _abort
	_mutex.unlock()
	return a



func _state_from_context(ctx: Dictionary) -> AIBoardSim.SimState:
	var board: BoardModel = ctx.get("board")
	var def: TileDef = ctx.get("tile")
	if board == null or def == null:
		return null
	var s := AIBoardSim.SimState.new()
	#clona thread
	s.board = AIBoardSim.clone_board(board)
	s.scores = PackedInt32Array(ctx.get("scores", PackedInt32Array([0, 0])))
	s.meeples = PackedInt32Array(ctx.get("meeples", PackedInt32Array([7, 7])))
	s.turn = ctx.get("turn", 0)
	s.deck = _deck_counts(ctx.get("deck"))
	if s.scores.is_empty():
		return null
	return s



func _deck_counts(src: Variant) -> Dictionary:
	var out := {}
	if src is Dictionary:
		return (src as Dictionary).duplicate()
	if src is Array:
		for def: TileDef in src:
			out[def] = out.get(def, 0) + 1
		return out
	for def: TileDef in TileCatalog.all_defs():
		out[def] = def.count
	return out

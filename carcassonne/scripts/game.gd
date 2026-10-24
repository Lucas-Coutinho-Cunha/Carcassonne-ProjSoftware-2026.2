class_name Game
extends Node3D
## Attach to the root Node3D. Expected children: Camera (Camera3D with board_camera.gd),
## Tiles (Node3D), Meeples (Node3D), plus any lights / HUD you like.

signal handoff(player: Player)
signal tile_drawn(def: TileDef, remaining: int)
signal scores_changed
signal game_over(winners: Array)

const PLAYER_COLORS: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.BLACK]
const MEEPLES_PER_PLAYER := 7
const MEEPLE_PICK_RADIUS := 0.45  # in tile units

@export var tile_size := 2.0
@export var player_names: PackedStringArray = ["Player 1", "Player 2"]

@onready var camera: Camera3D = $Camera
@onready var tiles_root: Node3D = $Tiles
@onready var meeples_root: Node3D = $Meeples

var sm := StateMachine.new()
var board := BoardModel.new()
var players: Array[Player] = []
var current := 0
var deck: Array[TileDef] = []
var tile_def: TileDef            # tile being placed this turn
var rot := 0                     # its rotation, clockwise quarter turns
var last_placed: BoardModel.Placed

var _ghost: Node3D
var _ghost_mat: StandardMaterial3D
var _slots: Array[Node3D] = []
var _meeple_nodes: Dictionary = {}  # Vector3i(cell.x, cell.y, feature index) -> Node3D


func _ready() -> void:
	for i in player_names.size():
		players.append(Player.new(i, player_names[i], PLAYER_COLORS[i], MEEPLES_PER_PLAYER))

	deck.assign(TileCatalog.build_deck())
	deck.shuffle()
	var start := TileCatalog.start_tile()
	board.place(start, 0, Vector2i.ZERO)
	_spawn_tile(start, 0, Vector2i.ZERO)

	sm.game = self
	add_child(sm)
	sm.add_state(&"handoff", TurnStates.Handoff.new())
	sm.add_state(&"draw", TurnStates.Draw.new())
	sm.add_state(&"place_tile", TurnStates.PlaceTile.new())
	sm.add_state(&"place_meeple", TurnStates.PlaceMeeple.new())
	sm.add_state(&"score", TurnStates.Score.new())
	sm.add_state(&"game_end", TurnStates.GameEnd.new())
	sm.change_to(&"handoff")


# ------------------------------------------------------------------ turn flow

func current_player() -> Player:
	return players[current]


func advance_player() -> void:
	current = (current + 1) % players.size()


## Rules: a tile that fits nowhere is discarded and another one is drawn.
func draw_playable_tile() -> bool:
	while not deck.is_empty():
		var t: TileDef = deck.pop_back()
		if board.has_any_placement(t):
			tile_def = t
			rot = 0
			tile_drawn.emit(t, deck.size())
			return true
	return false


func commit_tile(cell: Vector2i) -> void:
	last_placed = board.place(tile_def, rot, cell)
	_spawn_tile(tile_def, rot, cell)


func put_meeple(index: int) -> void:
	var p := current_player()
	board.place_meeple(last_placed.cell, index, p.id)
	p.meeples_left -= 1
	var node := _make_meeple(p.color)
	node.position = anchor_world(last_placed, index) + Vector3(0, 0.1, 0)
	meeples_root.add_child(node)
	_meeple_nodes[Vector3i(last_placed.cell.x, last_placed.cell.y, index)] = node
	scores_changed.emit()


func apply_results(results: Array[Dictionary]) -> void:
	for r in results:
		for pid in r.winners:
			players[pid].score += r.points
		for m in r.meeples:
			players[m.player].meeples_left += 1
			var key := Vector3i(m.cell.x, m.cell.y, m.index)
			if _meeple_nodes.has(key):
				_meeple_nodes[key].queue_free()
				_meeple_nodes.erase(key)
	scores_changed.emit()


func finish_game() -> void:
	apply_results(board.final_scoring())
	var best := 0
	for p in players:
		best = maxi(best, p.score)
	game_over.emit(players.filter(func(p: Player) -> bool: return p.score == best))


# -------------------------------------------------------------------- picking
# With an orthogonal top-down camera every pixel is a parallel ray, so a ray vs.
# the ground plane gives the exact world position. No physics bodies needed.

func mouse_world() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, dir)
	return hit if hit != null else Vector3.ZERO


func world_to_cell(p: Vector3) -> Vector2i:
	return Vector2i(roundi(p.x / tile_size), roundi(p.z / tile_size))


func cell_to_world(c: Vector2i) -> Vector3:
	return Vector3(c.x * tile_size, 0.0, c.y * tile_size)


func anchor_world(p: BoardModel.Placed, feature_index: int) -> Vector3:
	var a: Vector2 = p.def.features[feature_index].get("anchor", Vector2.ZERO)
	for i in p.rot:
		a = Vector2(-a.y, a.x)  # 90 degrees clockwise seen from above
	return cell_to_world(p.cell) + Vector3(a.x, 0.0, a.y) * tile_size


# ------------------------------------------------------------- ghost / slots

func show_ghost() -> void:
	_ghost = _make_tile_node(tile_def, rot)
	add_child(_ghost)
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var marker := MeshInstance3D.new()   # flat green/red overlay: valid / invalid cell
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE * tile_size * 0.96
	marker.mesh = quad
	marker.material_override = _ghost_mat
	marker.position.y = 0.1
	_ghost.add_child(marker)


func move_ghost(cell: Vector2i, valid: bool) -> void:
	_ghost.position = cell_to_world(cell) + Vector3(0, 0.3, 0)
	_ghost_mat.albedo_color = Color(0.2, 0.9, 0.2, 0.35) if valid else Color(0.9, 0.2, 0.2, 0.35)


func rotate_tile() -> void:
	rot = (rot + 1) % 4
	_ghost.rotation_degrees.y = -90.0 * rot  # +Y rotation is counter-clockwise from above


func hide_ghost() -> void:
	if _ghost:
		_ghost.queue_free()
		_ghost = null


func show_meeple_slots(options: Array[int]) -> void:
	var color := current_player().color
	color.a = 0.6
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	for i in options:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.12 * tile_size
		s.height = s.radius * 2.0
		mi.mesh = s
		mi.material_override = mat
		mi.position = anchor_world(last_placed, i) + Vector3(0, 0.25, 0)
		meeples_root.add_child(mi)
		_slots.append(mi)


func clear_meeple_slots() -> void:
	for n in _slots:
		n.queue_free()
	_slots.clear()


## Returns the feature index whose anchor is closest to the mouse, or -1.
func pick_slot(options: Array[int]) -> int:
	var mouse := mouse_world()
	var best := -1
	var best_d := MEEPLE_PICK_RADIUS * tile_size
	for i in options:
		var d := mouse.distance_to(anchor_world(last_placed, i))
		if d < best_d:
			best_d = d
			best = i
	return best


# ------------------------------------------------------------------- visuals

func _spawn_tile(def: TileDef, r: int, cell: Vector2i) -> void:
	var n := _make_tile_node(def, r)
	n.position = cell_to_world(cell)
	tiles_root.add_child(n)


func _make_tile_node(def: TileDef, r: int) -> Node3D:
	var n: Node3D
	if def.mesh:
		n = def.mesh.instantiate()
	else:
		n = _placeholder_tile(def)
	n.rotation_degrees.y = -90.0 * r
	return n


## Coloured slab with a dark nub on the north edge so rotation is visible.
func _placeholder_tile(def: TileDef) -> Node3D:
	var root := Node3D.new()
	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(tile_size * 0.98, 0.1, tile_size * 0.98)
	slab.mesh = box
	slab.position.y = -0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.from_hsv(float(absi(hash(def.id)) % 360) / 360.0, 0.45, 0.85)
	slab.material_override = mat
	root.add_child(slab)
	var nub := MeshInstance3D.new()
	var nb := BoxMesh.new()
	nb.size = Vector3(tile_size * 0.2, 0.06, tile_size * 0.1)
	nub.mesh = nb
	nub.position = Vector3(0, 0.03, -tile_size * 0.42)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.1, 0.1)
	nub.material_override = dark
	root.add_child(nub)
	return root


func _make_meeple(color: Color) -> Node3D:
	var k := tile_size * 0.5
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.18 * k
	cap.height = 0.6 * k
	mi.mesh = cap
	mi.position.y = 0.3 * k
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	root.add_child(mi)
	return root

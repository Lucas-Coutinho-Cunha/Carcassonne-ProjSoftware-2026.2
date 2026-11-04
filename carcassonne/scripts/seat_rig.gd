class_name SeatRig
extends Node3D


signal arrived(player: Player)

@export var board_camera: Camera3D
@export var table_center: Vector3 = Vector3.ZERO
@export var seat_radius: float = 12.0
@export var camera_radius: float = 7.0
@export var camera_height: float = 3.0
@export var look_height: float = 1.0
@export var seat_fov: float = 55.0
@export var base_angle: float = 0.0
@export var fly_in_time: float = 1.2
@export var fly_out_time: float = 0.8
@export var model_front_is_plus_z: bool = false

var _seat_camera: Camera3D
var _players: Array[Player] = []


func _ready() -> void:
	_seat_camera = Camera3D.new()
	_seat_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_seat_camera.near = 0.1
	_seat_camera.far = 200.0
	add_child(_seat_camera)


func place_players(players: Array[Player]) -> void:
	_players = players
	for i: int in _players.size():
		var player: Player = _players[i]
		player.global_position = seat_position(_turn_angle(i))
		var focus: Vector3 = Vector3(table_center.x, player.global_position.y, table_center.z)
		player.look_at(focus, Vector3.UP)
		if model_front_is_plus_z:
			player.rotate_y(PI)


func seat_position(angle: float) -> Vector3:
	return table_center + Vector3(cos(angle), 0.0, sin(angle)) * seat_radius


func show_player(turn: int) -> void:
	if _players.is_empty():
		return
	var angle_to: float = _turn_angle(turn)
	var angle_from: float = _turn_angle(turn - 1) if turn > 0 else angle_to
	_apply_pose(angle_from, 0.0)
	_seat_camera.make_current()
	await _fly(angle_from, angle_to, 0.0, 1.0, fly_in_time)
	arrived.emit(_players[turn % _players.size()])


func show_board(turn: int) -> void:
	var angle: float = _turn_angle(turn)
	Sfx.play_camera_away()
	await _fly(angle, angle, 1.0, 0.0, fly_out_time)
	board_camera.make_current()


func _turn_angle(turn: int) -> float:
	return base_angle + float(turn) * TAU / float(maxi(_players.size(), 1))


func _fly(angle_from: float, angle_to: float, blend_from: float, blend_to: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_fly_step.bind(angle_from, angle_to, blend_from, blend_to), 0.0, 1.0, duration)
	await tween.finished


func _fly_step(t: float, angle_from: float, angle_to: float, blend_from: float, blend_to: float) -> void:
	_apply_pose(lerpf(angle_from, angle_to, t), lerpf(blend_from, blend_to, t))


func _apply_pose(angle: float, blend: float) -> void:
	var board_pose: Transform3D = board_camera.global_transform
	_seat_camera.global_transform = board_pose.interpolate_with(_seat_pose(angle), blend)
	_seat_camera.fov = lerpf(_board_fov(), seat_fov, blend)


func _seat_pose(angle: float) -> Transform3D:
	var direction: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
	var position_cam: Vector3 = table_center + direction * camera_radius + Vector3(0.0, camera_height, 0.0)
	var target: Vector3 = table_center + direction * seat_radius + Vector3(0.0, look_height, 0.0)
	return Transform3D(Basis.looking_at(target - position_cam, Vector3.UP), position_cam)


func _board_fov() -> float:
	var height: float = maxf(board_camera.global_position.y, 0.01)
	return rad_to_deg(2.0 * atan(board_camera.size / (2.0 * height)))

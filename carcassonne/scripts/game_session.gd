extends Node
## Autoload. Register it in Project Settings > Globals (Autoload) with the name "GameSession".
## Do NOT give this script a class_name: the autoload name is already the global identifier.
##
## The lobby writes the chosen players here; Game reads them when it starts.
## It stores plain data (PlayerSetup), never Player nodes, so it survives scene changes.
## Every player must have a DIFFERENT avatar, because the avatar decides the meeple colour.

## Emitted when players are added, removed or the roster is reset. Edits to a player's
## name, avatar or bot flag change the PlayerSetup directly and do not emit it.
signal roster_changed

const MIN_PLAYERS: int = 2
const MAX_PLAYERS: int = 6
## Where the AvatarLibrary resource lives. Change this if you save it somewhere else.
const LIBRARY_PATH: String = "res://avatars/avatar_library.tres"

var library: AvatarLibrary = AvatarLibrary.new()
var players: Array[PlayerSetup] = []


func _ready() -> void:
	if ResourceLoader.exists(LIBRARY_PATH):
		var loaded: AvatarLibrary = load(LIBRARY_PATH) as AvatarLibrary
		if loaded != null:
			library = loaded
	if library.avatars.size() < MAX_PLAYERS:
		push_error("GameSession: %s needs at least %d avatars so every player can have a different one (found %d)" % [LIBRARY_PATH, MAX_PLAYERS, library.avatars.size()])
	# Lets you run the game scene directly (F6) without going through the lobby.
	if players.is_empty():
		reset_to_defaults()


func reset_to_defaults() -> void:
	players.clear()
	for i: int in MIN_PLAYERS:
		_append_player("Player %d" % (i + 1), false)
	roster_changed.emit()


func clear() -> void:
	players.clear()
	roster_changed.emit()


## Adds a player with the first free avatar. Returns false when the roster is full
## or no free avatar is left.
func add_player(display_name: String = "", is_bot: bool = false) -> bool:
	if players.size() >= MAX_PLAYERS:
		return false
	var chosen_name: String = display_name
	if chosen_name.is_empty():
		chosen_name = "Player %d" % (players.size() + 1)
	if not _append_player(chosen_name, is_bot):
		return false
	roster_changed.emit()
	return true


func remove_player(index: int) -> void:
	if index < 0 or index >= players.size():
		return
	players.remove_at(index)
	roster_changed.emit()


func can_start() -> bool:
	if players.size() < MIN_PLAYERS or players.size() > MAX_PLAYERS:
		return false
	for setup: PlayerSetup in players:
		if setup.avatar == null:
			return false
	return true


# ------------------------------------------------------------------- avatars

func is_avatar_taken(avatar: AvatarDef, ignore_index: int = -1) -> bool:
	for i: int in players.size():
		if i != ignore_index and players[i].avatar == avatar:
			return true
	return false


func first_free_avatar() -> AvatarDef:
	for avatar: AvatarDef in library.avatars:
		if not is_avatar_taken(avatar):
			return avatar
	return null


## Moves player `index` to the next (direction 1) or previous (direction -1) avatar that
## nobody else has. Returns the avatar the player now has.
func step_avatar(index: int, direction: int) -> AvatarDef:
	var setup: PlayerSetup = players[index]
	var count: int = library.avatars.size()
	if count == 0:
		return setup.avatar
	var start: int = library.avatars.find(setup.avatar)
	for offset: int in range(1, count + 1):
		var candidate: AvatarDef = library.avatars[posmod(start + offset * direction, count)]
		if not is_avatar_taken(candidate, index):
			setup.avatar = candidate
			return candidate
	return setup.avatar


func _append_player(display_name: String, is_bot: bool) -> bool:
	var avatar: AvatarDef = first_free_avatar()
	if avatar == null:
		push_error("GameSession: no free avatar left for a new player")
		return false
	players.append(PlayerSetup.new(display_name, avatar, is_bot))
	return true

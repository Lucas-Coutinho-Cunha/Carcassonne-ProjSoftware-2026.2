extends Node3D
## Debug scene: attach to an empty Node3D in a new scene and run it (F6).
## Shows every tile type in a grid, labelled with its id, so you can compare each
## texture against its catalog entry. Also runs CatalogValidator and prints problems.

## The same tile scene Game uses (root has tile_view.gd). Leave empty to use the fallback mesh.
@export var tile_scene: PackedScene
@export var tile_size: float = 2.0
@export var spacing: float = 0.5
@export var columns: int = 5


func _ready() -> void:
	var defs: Array[TileDef] = TileCatalog.all_defs()
	var problems: PackedStringArray = CatalogValidator.validate(defs, 72)
	for message: String in problems:
		push_error(message)
	if problems.is_empty():
		print("Catalog OK: %d tile types, 72 tiles" % defs.size())

	var step: float = tile_size + spacing
	for i: int in defs.size():
		var column: int = i % columns
		var row: int = floori(float(i) / float(columns))
		var origin: Vector3 = Vector3(float(column) * step, 0.0, float(row) * step)

		var view: TileView = _make_view()
		view.setup(defs[i], tile_size)
		view.position = origin
		add_child(view)

		var label: Label3D = Label3D.new()
		label.text = "%s (x%d)" % [defs[i].id, defs[i].count]
		label.font_size = 32
		label.pixel_size = 0.008
		label.modulate = Color.WHITE
		label.outline_size = 8
		label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)  # lie flat, readable from above
		label.position = origin + Vector3(0.0, 0.02, tile_size * 0.5 + 0.18)
		add_child(label)

	var rows: int = ceili(float(defs.size()) / float(columns))
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(rows) * step + 1.0
	camera.position = Vector3(float(columns - 1) * step * 0.5, 20.0, float(rows - 1) * step * 0.5)
	camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(camera)
	camera.current = true

	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60.0, 30.0, 0.0)
	add_child(light)


func _make_view() -> TileView:
	if tile_scene != null:
		return tile_scene.instantiate() as TileView
	return TileView.new()

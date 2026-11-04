class_name TileView
extends Node3D

@export var mesh_node_path: NodePath = ^"Mesh"
@export var mesh_size: float = 2.0
@export var top_surface_index: int = -1
@export var unshaded: bool = false

static var _material_cache: Dictionary = {}


func setup(def: TileDef, tile_size: float) -> void:
	var mesh_instance: MeshInstance3D = _get_or_create_mesh_instance()
	var factor: float = tile_size / mesh_size
	mesh_instance.scale = Vector3(factor, 1.0, factor)
	var material: StandardMaterial3D = _material_for(def)
	if top_surface_index < 0:
		mesh_instance.material_override = material
	else:
		mesh_instance.set_surface_override_material(top_surface_index, material)


func _get_or_create_mesh_instance() -> MeshInstance3D:
	var existing: MeshInstance3D = get_node_or_null(mesh_node_path) as MeshInstance3D
	if existing != null:
		return existing
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(mesh_size, mesh_size)
	var created: MeshInstance3D = MeshInstance3D.new()
	created.name = "Mesh"
	created.mesh = plane
	add_child(created)
	return created


func _material_for(def: TileDef) -> StandardMaterial3D:
	var key: String = "%s|%d|%d" % [def.id, int(unshaded), top_surface_index]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	if def.texture != null:
		material.albedo_texture = def.texture
	else:
		material.albedo_color = Color.from_hsv(float(absi(hash(def.id)) % 360) / 360.0, 0.45, 0.85)
	material.roughness = 1.0
	material.texture_repeat = false
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_cache[key] = material
	return material

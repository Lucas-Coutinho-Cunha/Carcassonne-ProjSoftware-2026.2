class_name TileView
extends Node3D
## Visual for one tile (placed tile or ghost). Every tile type uses the SAME flat-square
## mesh; only the texture changes. Materials are cached per tile type, so 72 tiles
## share 24 materials.
##
## Scene setup (e.g. res://tiles/tile_view.tscn):
##     TileView (Node3D, this script)
##     └─ Mesh (MeshInstance3D)   <- your flattened-square mesh
## The mesh's top face must point up (+Y) and its UVs must cover the whole texture,
## with the top of the image at the mesh's -Z edge (north).

## Path to the child MeshInstance3D that holds your mesh. If no such child exists, a
## plain flat PlaneMesh is created so the game still runs.
@export var mesh_node_path: NodePath = ^"Mesh"
## Edge length of your mesh in world units, as it is in the editor at scale 1.
@export var mesh_size: float = 2.0
## Index of the mesh surface that should show the texture. -1 = all surfaces. Use a
## surface index if your mesh has separate surfaces for the top and the sides.
@export var top_surface_index: int = -1
## Show the texture without lighting, so colours match the image exactly.
@export var unshaded: bool = false

static var _material_cache: Dictionary = {}


## Call right after instantiating, before adding to the scene tree.
func setup(def: TileDef, tile_size: float) -> void:
	var mesh_instance: MeshInstance3D = _get_or_create_mesh_instance()
	var factor: float = tile_size / mesh_size
	mesh_instance.scale = Vector3(factor, 1.0, factor)  # thickness is not scaled
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
		# No texture yet: flat colour derived from the tile id.
		material.albedo_color = Color.from_hsv(float(absi(hash(def.id)) % 360) / 360.0, 0.45, 0.85)
	material.roughness = 1.0
	material.texture_repeat = false  # avoids bleeding at the tile borders
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_cache[key] = material
	return material

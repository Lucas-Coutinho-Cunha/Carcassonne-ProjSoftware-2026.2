class_name MeepleView
extends Node3D

@export var mesh_node_path: NodePath = ^"Mesh"
@export var colored_surface_index: int = -1
@export var reference_tile_size: float = 2.0


func setup(color: Color, tile_size: float) -> void:
	scale = Vector3.ONE * (tile_size / reference_tile_size)
	var mesh_instance: MeshInstance3D = _get_or_create_mesh_instance()
	_apply_color(mesh_instance, color)


func _get_or_create_mesh_instance() -> MeshInstance3D:
	var existing: MeshInstance3D = get_node_or_null(mesh_node_path) as MeshInstance3D
	if existing != null:
		return existing
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.18
	capsule.height = 0.6
	var created: MeshInstance3D = MeshInstance3D.new()
	created.name = "Mesh"
	created.mesh = capsule
	created.position.y = 0.3
	add_child(created)
	return created


func _apply_color(mesh_instance: MeshInstance3D, color: Color) -> void:
	if mesh_instance.mesh == null:
		return
	var surfaces: Array[int] = []
	if colored_surface_index < 0:
		for i: int in mesh_instance.mesh.get_surface_count():
			surfaces.append(i)
	else:
		surfaces.append(colored_surface_index)

	for surface: int in surfaces:
		var base: BaseMaterial3D = mesh_instance.get_active_material(surface) as BaseMaterial3D
		var tinted: BaseMaterial3D
		if base != null:
			tinted = base.duplicate() as BaseMaterial3D
		else:
			tinted = StandardMaterial3D.new()
		tinted.albedo_color = color
		mesh_instance.set_surface_override_material(surface, tinted)

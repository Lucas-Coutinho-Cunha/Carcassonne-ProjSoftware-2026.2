class_name AvatarDef
extends Resource


@export var id: StringName
@export var display_name: String = ""
@export var material: Material
@export var color: Color = Color.WHITE


func apply_to(mesh_instance: MeshInstance3D, surface_index: int = -1) -> void:
	if mesh_instance == null:
		return
	if surface_index < 0:
		mesh_instance.material_override = material
	else:
		mesh_instance.set_surface_override_material(surface_index, material)

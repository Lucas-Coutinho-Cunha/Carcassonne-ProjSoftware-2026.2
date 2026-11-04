class_name AvatarDef
extends Resource
## One selectable avatar: a material wrapped over the shared player model, plus the colour
## that this avatar's meeples (and UI accents) use. Create one .tres per avatar.

@export var id: StringName
@export var display_name: String = ""
## Material (texture, colour, ...) applied to the player model.
@export var material: Material
## Meeple colour for a player who picks this avatar. Make it match the material visually.
@export var color: Color = Color.WHITE


## Puts this avatar's material on a mesh. surface_index -1 = every surface of the mesh.
func apply_to(mesh_instance: MeshInstance3D, surface_index: int = -1) -> void:
	if mesh_instance == null:
		return
	if surface_index < 0:
		mesh_instance.material_override = material
	else:
		mesh_instance.set_surface_override_material(surface_index, material)

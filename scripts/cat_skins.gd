class_name CatSkins
extends RefCounted

## Lista central das skins do gato. Use em qualquer cena:
##   CatSkins.apply(modelo_do_gato, GameState.players[i].skin)

const CAT_SCENE: PackedScene = preload("res://assets/models/Cat.gltf")

const NAMES := [
	"Clássico", "Laranja", "Malhado", "Verde", "Amarelo",
	"Azul", "Preto", "Cinza", "Bege",
]

const TEXTURES := [
	preload("res://assets/models/CatTexture1.png"),
	preload("res://assets/models/CatTexture2.png"),
	preload("res://assets/models/CatTexture3.png"),
	preload("res://assets/models/CatTexture4.png"),
	preload("res://assets/models/CatTexture5.png"),
	preload("res://assets/models/CatTexture6.png"),
	preload("res://assets/models/CatTexture7.png"),
	preload("res://assets/models/CatTexture8.png"),
	preload("res://assets/models/CatTexture9.png"),
]

## Skins que brilham: índice da skin -> textura de emissão.
const EMISSIONS := {
	4: preload("res://assets/models/CatTexture5emission.png"),
}


static func count() -> int:
	return TEXTURES.size()


static func skin_name(index: int) -> String:
	return NAMES[index] if index < NAMES.size() else "Skin %d" % (index + 1)


static func make_material(index: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = TEXTURES[index]
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # visual pixelado do Blockbench
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	if EMISSIONS.has(index):
		mat.emission_enabled = true
		mat.emission = Color.WHITE  # no Godot 4 a cor multiplica a textura
		mat.emission_texture = EMISSIONS[index]
	return mat


## Aplica a skin em todos os MeshInstance3D do modelo.
static func apply(model: Node, index: int) -> void:
	var mat := make_material(index)
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = mat

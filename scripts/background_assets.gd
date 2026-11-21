extends RefCounted
## Independent native-resolution textures. Only the active stage is held by the renderer.
const ROOT: String = "res://assets/backgrounds/"
const Stages=preload("res://scripts/stage_catalog.gd")
static func load_stage(stage: int) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for region in Stages.definition(stage).regions:
		textures.append(load(region.path))
	return textures
static func bind(material: ShaderMaterial, stage: int, textures: Array[Texture2D]) -> void:
	var earth_lunar: bool=Stages.definition(stage).layout=="earth_lunar"
	material.set_shader_parameter("stage",4 if earth_lunar else 1)
	for i in range(3): material.set_shader_parameter("region%d_texture"%(i+1),textures[i])
	material.set_shader_parameter("earth_texture",textures[0] if earth_lunar else null)
	material.set_shader_parameter("cavern_texture",textures[3] if earth_lunar else null)
	if earth_lunar:
		var earth: Texture2D = textures[0]
		material.set_shader_parameter("earth_uv_width",400.0/960.0*earth.get_height()/earth.get_width())

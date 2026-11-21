extends RefCounted
## Independent native-resolution textures. Only the active stage is held by the renderer.
const ROOT: String = "res://assets/backgrounds/"
const FILES: Array = [
	["stage01/region01-ocean.png","stage01/region02-coast.png","stage01/region03-forest.png"],
	["stage02/region01-green-valleys.png","stage02/region02-snow-peaks.png","stage02/region03-forest-ridges.png"],
	["stage03/region01-night-snow.png","stage03/region02-night-outpost.png","stage03/region03-night-ocean.png"],
	["stage04/region01-earth.png","stage04/region02-space.png","stage04/region03-moon-surface.png","stage04/region04-lunar-cavern.png"]]
static func load_stage(stage: int) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for file in FILES[clampi(stage,1,FILES.size())-1]:
		textures.append(load(ROOT+file))
	return textures
static func bind(material: ShaderMaterial, stage: int, textures: Array[Texture2D]) -> void:
	material.set_shader_parameter("stage",stage)
	for i in range(3): material.set_shader_parameter("region%d_texture"%(i+1),textures[i])
	material.set_shader_parameter("earth_texture",textures[0] if stage==4 else null)
	material.set_shader_parameter("cavern_texture",textures[3] if stage==4 else null)
	if stage==4:
		var earth: Texture2D = textures[0]
		material.set_shader_parameter("earth_uv_width",400.0/960.0*earth.get_height()/earth.get_width())

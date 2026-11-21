extends RefCounted
## Shared lazy texture loader for whole PNGs and optional transparent-border crops.
var textures: Dictionary={}
func get_texture(path: String, region: Array = []) -> Texture2D:
	var key: String=path+str(region)
	if not textures.has(key):
		var source: Texture2D=load(path)
		if region.is_empty():textures[key]=source
		else:
			var frame:=AtlasTexture.new()
			frame.atlas=source
			frame.region=Rect2(region[0],region[1],region[2],region[3])
			frame.filter_clip=true
			textures[key]=frame
	return textures[key]
func for_definition(d: Dictionary) -> Texture2D:
	return get_texture(d.sprite_path,d.get("sprite_region",[]))
func for_asset(asset: Dictionary) -> Texture2D:
	return get_texture(asset.path,asset.get("region",[]))
static func native_size(d: Dictionary) -> Vector2:
	var region: Array=d.get("sprite_region",[])
	if not region.is_empty():return Vector2(region[2],region[3])
	var texture: Texture2D=load(d.sprite_path)
	return texture.get_size()

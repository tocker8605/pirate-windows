extends SceneTree
## Import selected per-entity paintings; keep alpha and normalize the long edge to ring_rotor's832px.
const MANIFEST="res://art_source/entity-sheets/high-resolution-manifest.json"
static func visible_bounds(image: Image) -> Rect2i:
	var low:=image.get_size()
	var high:=Vector2i(-1,-1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a<=0.05:continue
			low=low.min(Vector2i(x,y))
			high=high.max(Vector2i(x,y))
	return Rect2i(low,high-low+Vector2i.ONE)
func _initialize() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for entry in manifest.entries:
		var source:=Image.load_from_file("res://"+entry.source)
		var bounds: Rect2i=visible_bounds(source)
		if maxi(bounds.size.x,bounds.size.y)<int(manifest.long_edge):
			push_error("Generated art is below the required native resolution: "+entry.name)
			quit(1)
			return
		var image: Image=source.get_region(bounds)
		var factor: float=float(manifest.long_edge)/maxi(bounds.size.x,bounds.size.y)
		image.resize(maxi(1,roundi(bounds.size.x*factor)),maxi(1,roundi(bounds.size.y*factor)),Image.INTERPOLATE_LANCZOS)
		if image.save_png("res://"+entry.output)!=OK:
			push_error("Cannot save "+entry.output)
			quit(1)
			return
		print("HIGH RES: %s %s"%[entry.name,image.get_size()])
	print("IMPORTED:14 standalone paintings at832px long edge")
	quit()

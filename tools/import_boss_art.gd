extends SceneTree
## Preserve selected high-resolution boss paintings at native resolution; no AI or upscaling here.
const Crop=preload("res://tools/import_entity_art.gd")
const MANIFEST="res://art_source/boss-high-resolution/manifest.json"
func _initialize() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var count: int=0
	for entry in manifest.entries:
		var source:=Image.load_from_file("res://"+entry.source)
		var bounds: Rect2i=Crop.visible_bounds(source)
		if maxi(bounds.size.x,bounds.size.y)<1024:
			push_error("Boss painting is below the requested native resolution: "+entry.name)
			quit(1)
			return
		var image: Image=source.get_region(bounds)
		for output in entry.outputs:
			if image.save_png("res://"+output)!=OK:
				push_error("Cannot save "+output)
				quit(1)
				return
			count+=1
			print("BOSS HIGH RES: %s %s"%[output,image.get_size()])
	print("IMPORTED: %d independent boss body/part images"%count)
	quit()

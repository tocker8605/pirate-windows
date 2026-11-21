extends SceneTree
## Deterministic extraction only: no resampling, repainting or sprite packing.
const MANIFEST="res://art_source/entity-sheets/split-manifest.json"
func _initialize() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var sources: Dictionary={}
	var written: int=0
	for entry in manifest.entries:
		if FileAccess.file_exists("res://"+entry.output) and "--overwrite" not in OS.get_cmdline_user_args():continue
		if not sources.has(entry.source):
			var source:=Image.load_from_file("res://"+entry.source)
			source.convert(Image.FORMAT_RGBA8)
			sources[entry.source]=source
		var image: Image=sources[entry.source]
		var result: Image
		if entry.mode=="crop":
			if entry.rect==null:result=image.duplicate()
			else:result=image.get_region(Rect2i(entry.rect[0],entry.rect[1],entry.rect[2],entry.rect[3]))
		else:
			var w: int=int(entry.rect[2])
			var h: int=int(entry.rect[3])
			result=Image.create(w*int(entry.frames),h,false,Image.FORMAT_RGBA8)
			for frame in range(int(entry.frames)):
				for y in range(h):
					for x in range(w):
						var pixel: Color=image.get_pixel(int(entry.rect[0])+frame*w+x,int(entry.rect[1])+y)
						pixel.a=1-image.get_pixel(int(entry.mask[0])+frame*w+x,int(entry.mask[1])+y).r
						result.set_pixel(frame*w+x,y,pixel)
		var path: String="res://"+entry.output
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
		if result.save_png(path)!=OK:
			push_error("Failed to save "+path)
			quit(1)
			return
		written+=1
	print("SPLIT: %d created; %d existing images preserved"%[written,manifest.entries.size()-written])
	quit()

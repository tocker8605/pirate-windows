extends SceneTree
## The editor profiler opens user:// before it creates its snapshot directory.
## Prepare this directory using Godot's path rules, without starting the game.
func _initialize() -> void:
	var path: String=OS.get_user_data_dir()
	var error: Error=DirAccess.make_dir_recursive_absolute(path)
	if error!=OK:
		push_error("Cannot prepare build user data: %s (%s)"%[path,error_string(error)])
		quit(1)
		return
	print("Prepared build user data: "+path)
	quit()

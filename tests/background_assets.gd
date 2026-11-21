extends SceneTree
const Assets = preload("res://scripts/background_assets.gd")
const Regions = preload("res://scripts/background_regions.gd")
const Game = preload("res://scripts/game.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var paths: Array = []
	for stage in range(1,6):
		var textures: Array[Texture2D] = Assets.load_stage(stage)
		check(textures.size()==Regions.count(stage),"stage%d keeps its original region count"%stage)
		for i in range(textures.size()):
			var texture: Texture2D = textures[i]
			check(texture.get_width()>=960 and texture.get_height()>=960,"stage%d region%d has native resolution of at least960x960"%[stage,i+1])
			check(not paths.has(texture.resource_path) and texture.resource_path.begins_with(Assets.ROOT+"stage%02d/"%stage),"stage%d region%d uses its own stage-local image"%[stage,i+1])
			paths.append(texture.resource_path)
	check(paths.size()==16,"all sixteen regions have independent image resources")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g._load_stage(1)
	var material: ShaderMaterial = g.view.background.material
	check(g.view.background_textures.size()==3 and material.get_shader_parameter("earth_texture")==null and material.get_shader_parameter("cavern_texture")==null,"ordinary stage holds only three local textures")
	var first_path: String = g.view.background_textures[0].resource_path
	g._load_stage(2)
	check(g.view.background_stage==2 and g.view.background_textures[0].resource_path!=first_path,"stage change replaces the bound terrain set")
	g._load_stage(4)
	check(g.view.background_textures.size()==4 and material.get_shader_parameter("earth_texture")==g.view.background_textures[0] and material.get_shader_parameter("cavern_texture")==g.view.background_textures[3],"stage4 binds its four independent regions")
	var earth: Texture2D = g.view.background_textures[0]
	g._return_title()
	g.title.confirm()
	g._redraw()
	check(material.get_shader_parameter("earth_texture")==earth,"title reveal shares the exact same stage4 Earth resource")
	g._load_stage(1)
	check(g.view.background_textures.size()==3 and material.get_shader_parameter("earth_texture")==null and material.get_shader_parameter("cavern_texture")==null,"leaving stage4 releases its extra panorama and cave bindings")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

extends RefCounted
## Resolve the stage's authored spawn manifest without spawning actors or advancing clocks.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Campaign=preload("res://scripts/campaign_rules.gd")
const HUD=preload("res://scripts/hud.gd")
const ClearScreen=preload("res://scripts/clear_screen.gd")
static func manifest(stage: int,events: Array,boss_rush: bool) -> Dictionary:
	var entities: Array=[]
	var music: Array=[]
	var screen_textures: Array=[]
	var has_boss: bool=false
	if not boss_rush:music.append(Campaign.music(stage))
	for event in events:
		if event.get("action")!="spawn":continue
		var kind: int=event.definition_id
		if kind not in entities:entities.append(kind)
		var definition: Dictionary=Catalog.definition(kind)
		has_boss=has_boss or definition.role=="boss"
		var track: String=definition.get("music","")
		if not track.is_empty() and track not in music:music.append(track)
	if stage==Campaign.stage_count(boss_rush):
		screen_textures.append(ClearScreen.BACKGROUND_PATH)
		if ClearScreen.MUSIC_TRACK not in music: music.append(ClearScreen.MUSIC_TRACK)
	return {"entities":entities,"music":music,"has_boss":has_boss,"screen_textures":screen_textures}
static func prepare(g: Node) -> void:
	var resources: Dictionary=manifest(g.stage,g.events,g.run_settings.boss_rush)
	for path in resources.screen_textures: g.screen_textures.get_texture(path)
	g.view.prepare_entities(resources.entities,g.renewed_art)
	if resources.has_boss:
		HUD.prepare_boss(g.art)
		g.art.sprite("picwarn",Rect2i(0,0,250,60),Vector2i(0,60))
	if g.audio!=null:g.audio.prepare_music(resources.music)

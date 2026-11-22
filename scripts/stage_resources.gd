extends RefCounted
## Resolve the stage's authored spawn manifest without spawning actors or advancing clocks.
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Campaign=preload("res://scripts/campaign_rules.gd")
const HUD=preload("res://scripts/hud.gd")
static func manifest(stage: int,events: Array,boss_rush: bool) -> Dictionary:
	var entities: Array=[]
	var music: Array=[]
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
	return {"entities":entities,"music":music,"has_boss":has_boss}
static func prepare(g: Node) -> void:
	var resources: Dictionary=manifest(g.stage,g.events,g.run_settings.boss_rush)
	g.view.prepare_entities(resources.entities,g.renewed_art)
	if resources.has_boss:
		HUD.prepare_boss(g.art)
		g.art.sprite("picwarn",Rect2i(0,0,250,60),Vector2i(0,60))
	if g.audio!=null:g.audio.prepare_music(resources.music)

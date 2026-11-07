extends RefCounted
## Presentation anchors. Native60Hz play displays the current completed simulation state.
const Clock = preload("res://scripts/timing.gd")
const Regions = preload("res://scripts/background_regions.gd")
var alpha: float = 1.0
var sample_frame: int = -1
var previous_player: Vector2
var previous_shield_ticks: float = 0
var previous_shield: Vector2
var previous_background: float = 0
var previous_clouds: Array = [Vector2.ZERO,Vector2.ZERO]
func reset(g: Node) -> void:
	alpha = 1.0
	sample_frame = -1
	previous_player = g.player
	previous_shield = g.shield_center
	previous_shield_ticks = g.shield
	previous_background = g.background_y
	for i in range(2): previous_clouds[i] = g.clouds[i]
func remember(collection: Variant) -> void:
	for entity in collection: entity.previous_pos = entity.pos
func capture(g: Node) -> void:
	sample_frame = g.frame+1
	previous_player = g.player
	previous_shield = g.shield_center
	previous_shield_ticks = g.shield
	previous_background = g.background_y
	for i in range(2): previous_clouds[i] = g.clouds[i]
	remember(g.enemies)
	remember(g.bullets)
	remember(g.items)
	remember(g.shots)
	remember(g.explosions)
	if not g.boss.is_empty(): g.boss.previous_pos = g.boss.pos
func refresh(g: Node) -> void:
	if g.state=="paused": return
	alpha = 1.0 # Simulation and presentation both run at60Hz; no33Hz interpolation delay.
func position(entity: Dictionary) -> Vector2:
	return entity.get("previous_pos",entity.pos).lerp(entity.pos,alpha)
func player(g: Node) -> Vector2: return previous_player.lerp(g.player,alpha) if sample_frame==g.frame else g.player
func shield(g: Node) -> Vector2:
	if previous_shield_ticks<=0 or sample_frame!=g.frame: return g.shield_center
	return previous_shield.lerp(g.shield_center,alpha)
func background(g: Node) -> float:
	if alpha>=1 or sample_frame!=g.frame: return g.background_y
	var travel: float = g.background_y-previous_background
	if travel>0: travel -= Regions.SCREEN
	return Regions.wrap(previous_background+travel*alpha,g.map_mode)
func cloud(g: Node, index: int) -> Vector2:
	var current: Vector2 = g.clouds[index]
	var previous: Vector2 = previous_clouds[index]
	if sample_frame!=g.frame or current.y<previous.y-300 or absf(current.x-previous.x)>150: return current
	return previous.lerp(current,alpha)
func phase(g: Node) -> float: return g.timeline()-g.tick_units+g.tick_units*alpha if sample_frame==g.frame else g.timeline()

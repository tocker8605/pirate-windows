class_name PirateSpecialEffects
extends RefCounted
## Original picpil / picshi / piclaz frame layout and timing.
static func beam_frame(ticks: int) -> int:
	if ticks<=0: return -1
	if ticks>12: return 0
	if ticks>9: return 1
	if ticks>5: return 2
	if ticks>3: return 1
	return 0

static func shield_frame(ticks: int) -> int:
	if ticks<=0: return -1
	if ticks==200: return 0
	if ticks>197: return 1
	if ticks>50: return 2 if ticks%2==0 else 3
	return 2 if ticks%2==0 else -1

static func shield_contains(center: Vector2, point: Vector2, ticks: int) -> bool:
	# Original shield has two ticks of deployment before it can intercept.
	return ticks>0 and ticks<198 and point.x>center.x-42 and point.x<center.x+38 and point.y>center.y-40 and point.y<center.y+40

static func render(canvas: Node2D, art: RefCounted, player: Vector2, beam_ticks: int, shield_center: Vector2, shield_ticks: int, beam_contacts: Array, shield_contacts: Array) -> void:
	var shield_index: int = shield_frame(shield_ticks)
	if shield_index>=0:
		canvas.draw_texture(art.sprite("picshi",Rect2i(shield_index*100,0,100,100),Vector2i(shield_index*100,100)),shield_center-Vector2(50,50))
	var beam_index: int = beam_frame(beam_ticks)
	if beam_index>=0:
		canvas.draw_texture(art.sprite("picpil",Rect2i(beam_index*15,0,15,480),Vector2i(45+beam_index*15,0)),player+Vector2(18,-470))
	for point in beam_contacts:
		canvas.draw_texture(art.sprite("piclaz",Rect2i(0,0,30,30),Vector2i(0,30)),point)
	for point in shield_contacts:
		canvas.draw_texture(art.sprite("piclaz",Rect2i(30,0,60,60),Vector2i(90,0)),point-Vector2(20,20))

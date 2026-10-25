class_name PirateHUD
extends RefCounted
const Weapons = preload("res://scripts/player_weapons.gd")
## Original pichud/picbhp artwork and 400x480 pixel layout.
static func masked(canvas: Node2D, art: RefCounted, id: String, pos: Vector2, rect: Rect2i, mask: Vector2i) -> void:
	canvas.draw_texture(art.sprite(id,rect,mask),pos)

static func opaque(canvas: Node2D, art: RefCounted, id: String, pos: Vector2, rect: Rect2i) -> void:
	if rect.size.x > 0: canvas.draw_texture_rect_region(art.texture(id),Rect2(pos,Vector2(rect.size)),Rect2(rect))

static func render(canvas: Node2D, art: RefCounted, hull: int, energy: float, weapon: int, power: int, score: int, boss_hp: int = -1, boss_max: int = 1000) -> void:
	masked(canvas,art,"pichud",Vector2(250,5),Rect2i(0,0,134,24),Vector2i(0,24))
	if hull > 0:
		opaque(canvas,art,"pichud",Vector2(352-hull,7),Rect2i((100 if hull>40 else 40)-hull,96 if hull>40 else 116,hull,20))
	masked(canvas,art,"pichud",Vector2(15,5),Rect2i(0,48,134,24),Vector2i(0,72))
	var fill: int = Weapons.vb_integer(energy)
	if fill > 0: opaque(canvas,art,"pichud",Vector2(47,7),Rect2i(0,96 if energy>40 else 116,fill,20))
	match weapon:
		1: masked(canvas,art,"pichud",Vector2(15,35),Rect2i(40,116,30,20),Vector2i(40,136))
		2: masked(canvas,art,"pichud",Vector2(15,35),Rect2i(100,156,30,20),Vector2i(100,176))
		3: masked(canvas,art,"pichud",Vector2(15,35),Rect2i(10,136,30,20),Vector2i(100,96))
	masked(canvas,art,"pichud",Vector2(33,35),Rect2i(10*power,156,10,20),Vector2i(10*power,176))
	if energy>7: masked(canvas,art,"pichud",Vector2(47,35),Rect2i(70,116,30,20),Vector2i(70,136))
	if energy>39: masked(canvas,art,"pichud",Vector2(79,35),Rect2i(100,116,30,20),Vector2i(100,136))
	var digits: String = str(maxi(score,0))
	for i in range(mini(digits.length(),6)):
		var digit: int = int(digits[digits.length()-1-i])
		masked(canvas,art,"pichud",Vector2(375-i*10,35),Rect2i(digit*10,156,10,20),Vector2i(digit*10,176))
	if boss_hp >= 0:
		masked(canvas,art,"picbhp",Vector2(60,455),Rect2i(0,0,284,24),Vector2i(0,24))
		opaque(canvas,art,"picbhp",Vector2(92,457),Rect2i(0,48,clampi(int(boss_hp/(6.0 if boss_max==1500 else 4.0)),0,250),20))

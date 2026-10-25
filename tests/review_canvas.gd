extends Node2D
const Art = preload("res://scripts/art.gd")
const Weapons = preload("res://scripts/player_weapons.gd")
const HUD = preload("res://scripts/hud.gd")
var art = Art.new()
var font: Font = ThemeDB.fallback_font

func _draw() -> void:
	draw_texture_rect_region(art.texture("stage0"),Rect2(0,0,400,480),Rect2(0,240,400,480))
	for i in range(3):
		draw_set_transform(Vector2(0,i*83))
		HUD.render(self,art,80 if i==0 else (25 if i==1 else 0),90 if i==0 else (35 if i==1 else 0),i+1,7-i,12345+i)
	draw_set_transform(Vector2.ZERO)
	var labels: Array = ["LAUNCH","FLIGHT","HIT 1","HIT 2","HIT 3"]
	var anchors: Array = [25,90,165,245,325]
	for i in range(5): draw_string(font,Vector2(anchors[i]-14,253),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,10)
	for weapon in range(1,4):
		var y: float = 270+(weapon-1)*57
		for i in range(5):
			var shot: Dictionary = {"pos":Vector2(0,100 if i==1 else 140),"impact_ticks":9-(i-2)*3 if i>=2 else -1}
			var visual: Dictionary = Weapons.visual(shot,Vector2(0,140))
			draw_texture(art.sprite("weapon%d"%weapon,visual.rect,visual.mask),Vector2(anchors[i],y)+visual.offset)
		draw_string(font,Vector2(9,y+42),"WEAPON %d"%weapon,HORIZONTAL_ALIGNMENT_LEFT,-1,10)
	HUD.masked(self,art,"picbhp",Vector2(60,455),Rect2i(0,0,284,24),Vector2i(0,24))
	HUD.opaque(self,art,"picbhp",Vector2(92,457),Rect2i(0,48,125,20))

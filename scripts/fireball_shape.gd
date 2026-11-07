extends RefCounted
## Canonical procedural flame used by the offline atlas generator and visual tests.
## Runtime bullets use the cached atlas, not these polygons/circles every frame.
const HOT = Color("ff8945")
const FRAMES: int = 128
const COLUMNS: int = 16
const CELL: int = 64
const PIXEL_SCALE: int = 2
const PHASE_PERIOD: float = TAU*10.0
static func glow_texture() -> Texture2D:
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var radius: float = Vector2(x-31.5,y-31.5).length()/31.5
			image.set_pixel(x,y,Color(1,1,1,pow(maxf(0,1-radius),2.5)))
	return ImageTexture.create_from_image(image)
static func draw(c: Node2D, p: Vector2, direction: Vector2, phase: float, glow: Texture2D) -> void:
	var tail: Vector2 = -direction
	var side: Vector2 = direction.orthogonal()
	var flicker: float = sin(phase*0.9)
	c.draw_texture_rect(glow,Rect2(p-Vector2(18,18),Vector2(36,36)),false,Color(HOT,0.65))
	# Three animated tongues follow the instantaneous parabolic velocity, not a metal missile body.
	for i in range(3):
		var offset: float = (i-1)*3.0
		var length: float = 16+sin(phase*0.7+i*2)*5
		var base: Vector2 = p+side*offset
		var tip: Vector2 = base+tail*length+side*sin(phase+i)*3
		c.draw_colored_polygon(PackedVector2Array([base+side*3,tip,base-side*3]),Color(1,0.22+0.1*i,0.02,0.75))
	c.draw_circle(p,5.5,Color("ff571c"),true,-1,true)
	c.draw_colored_polygon(PackedVector2Array([p+direction*4,p+side*3,p+tail*(12+flicker*2),p-side*3]),Color("ffc13b"))
	c.draw_circle(p+tail,2.8,Color("fff2ad"),true,-1,true)

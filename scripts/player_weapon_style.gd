extends RefCounted
## Shared hue/tone and compact footprints for player projectiles and their particles.
const Geometry=preload("res://scripts/player_projectile_geometry.gd")
const CENTRE: Vector2=Geometry.SHOT_CENTRE
const BASE = [Color("ceb6fa"),Color("5aa9cf"),Color("81bb6a")]
const LIGHT = [Color("eee4ff"),Color("abd9ed"),Color("c4e5a0")]
const SIZES = [Vector2i(13,26),Vector2i(14,26),Vector2i(12,24)]
const PORTS = [[0.0],[0.0],[0.0]]
static func color(weapon: int) -> Color: return BASE[clampi(weapon,1,3)-1]
static func highlight(weapon: int) -> Color: return LIGHT[clampi(weapon,1,3)-1]
static func grade(source: Color, weapon: int) -> Color:
	var value: float = maxf(source.r,maxf(source.g,source.b))
	var luma: float = source.r*0.2126+source.g*0.7152+source.b*0.0722
	var level: float = pow(clampf((luma-0.15)/0.85,0,1),2)
	var result: Color = color(weapon).lerp(highlight(weapon),level)*(0.58+0.42*value)
	result.a = source.a
	return result

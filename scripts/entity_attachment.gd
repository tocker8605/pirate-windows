extends RefCounted
## One owner of attached axes; free axes retain their authored or independent position.
const Catalog=preload("res://scripts/enemy_catalog.gd")
static func follows_y(actor: Dictionary,parent: Dictionary) -> bool:
	return not parent.is_empty() and Catalog.for_actor(actor).get("attachment",{}).get("follow_y",false)
static func apply(actor: Dictionary,parent: Dictionary) -> void:
	if parent.is_empty():return
	var attachment: Dictionary=Catalog.for_actor(actor).get("attachment",{})
	if attachment.is_empty():return
	var offset:=Vector2(attachment.offset[0],attachment.offset[1])
	if attachment.get("follow_x",true):actor.pos.x=parent.pos.x+offset.x
	if attachment.follow_y:actor.pos.y=parent.pos.y+offset.y

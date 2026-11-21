extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Schema=preload("res://scripts/projectile_volley_schema.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func plasma(shots: Array) -> Array:return shots.filter(func(s):return s.kind==5)
func actor(kind: int) -> Dictionary:return Catalog.create(kind,Vector2(100,125))
func boss_for(kind: int) -> Dictionary:return Catalog.create(94,Vector2(200,60 if kind!=132 else 140))
func _initialize() -> void:
	var sequence: Array=[12,4,-4,-12,-4,4,12,4,-4,-12,-4,4,12]
	for kind in [22,131,132]:
		var e: Dictionary=actor(kind)
		var boss: Dictionary=boss_for(kind)
		for index in range(sequence.size()):
			var player:=Vector2(30+index*23,350-index*4)
			var shots: Array=plasma(Fire.advance(e,0.06,player,boss))
			var expected: Vector2=(player-e.pos).normalized().rotated(deg_to_rad(sequence[index]))*300
			check(shots.size()==1,"entity%d fires one plasma bullet every60ms"%kind)
			if shots.size()!=1:continue
			check(shots[0].velocity.distance_to(expected)<0.001,"entity%d shot%d uses current aim plus the clockwise/counterclockwise sweep"%[kind,index])
			check(absf(shots[0].velocity.length()-300)<0.001,"angular sweep preserves constant300px/s")
			var port: Array=Catalog.fire_channel(kind,"plasma").volley.ports[0]
			check(shots[0].pos==e.pos+Vector2(port[0],port[1]),"muzzle position remains unchanged")
		var fresh: Dictionary=actor(kind)
		check(plasma(Fire.advance(fresh,0.059,Vector2(175,380),boss)).is_empty(),"first shot waits the complete60ms")
		check(plasma(Fire.advance(fresh,0.001,Vector2(175,380),boss)).size()==1,"independent fresh actor starts at12degrees")
		# Disable the original gate; no queued fire and the angle resumes from the next shot.
		if kind==22:fresh.pos.y=100
		else:boss.pos.y=100
		check(plasma(Fire.advance(fresh,1,Vector2(175,380),boss)).is_empty(),"original Y gate still disables plasma")
		fresh.pos.y=125
		boss=boss_for(kind)
		check(plasma(Fire.advance(fresh,0.059,Vector2(175,380),boss)).is_empty(),"gate reentry does not bank a partial firing interval")
		var resumed: Array=plasma(Fire.advance(fresh,0.001,Vector2(175,380),boss))
		check(resumed.size()==1 and resumed[0].velocity.distance_to((Vector2(175,380)-fresh.pos).normalized().rotated(deg_to_rad(4))*300)<0.001,"sweep advances on actual shots, independently for each actor")
		var coarse: Array=plasma(Fire.advance(actor(kind),0.36,Vector2(175,380),boss))
		check(coarse.size()==6,"coarse update retains all6due volleys")
		for i in range(coarse.size()):check(coarse[i].velocity.distance_to((Vector2(175,380)-Vector2(100,125)).normalized().rotated(deg_to_rad(sequence[i]))*300)<0.001,"catchup preserves the angle sequence")
	var charge: Dictionary=actor(22)
	var shots: Array=Fire.advance(charge,0.12,Vector2(175,380))
	var orange: Array=shots.filter(func(s):return s.kind==7)
	check(orange.size()==1 and orange[0].velocity.distance_to((Vector2(175,380)-charge.pos).normalized()*333.33333333333337)<0.001,"charge orange shot retains120ms cadence and original aiming/speed")
	for y in [100,150]:
		charge=actor(22);charge.pos.y=y
		check(Fire.advance(charge,1,Vector2(175,380)).is_empty(),"charge gate remains strictly betweenY100and150")
	var errors:=PackedStringArray()
	Schema.validate({"type":"aimed_sequence","ports":[[25,25]],"speed":300,"projectile_kind":5,"angles_degrees":[]},"test.",errors)
	check(not errors.is_empty(),"empty angle sequence is rejected")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Scheduler=preload("res://scripts/attack_timer.gd")
const Geometry=preload("res://scripts/entity_geometry.gd")
const Rng=preload("res://scripts/random.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var left_channel: Dictionary=Catalog.fire_channel(143,"missiles")
	var right_channel: Dictionary=Catalog.fire_channel(144,"missiles")
	check(Geometry.vector(left_channel.window_seconds)==Vector2(12,0) and float(left_channel.window_seconds[2])==4 and Geometry.vector(right_channel.window_seconds)==Vector2(12,6) and float(right_channel.window_seconds[2])==10,"12second cycle is left4/rest2/right4/rest2")
	for kind in [143,144]:
		var channel: Dictionary=Catalog.fire_channel(kind,"missiles")
		var owner: Dictionary={}
		var events: Array=[]
		for frame in range(1440):events.append_array(Scheduler.advance(owner,[channel],1.0/60,func(_c):return true))
		var coarse: Array=Scheduler.advance({},[channel],24,func(_c):return true)
		var same: bool=events.size()==coarse.size()
		for i in range(mini(events.size(),coarse.size())):same=same and is_equal_approx(events[i].at,coarse[i].at) and events[i].name==coarse[i].name
		check(same,"60Hz and24second catchup produce identical phase/timing records")
		check(events.size()==66,"each wing emits33missiles per4second burst,66over two cycles")
		var start: float=0 if kind==143 else 6
		for cycle in range(2):
			for index in range(33):
				var at: float=events[cycle*33+index].at
				check(is_equal_approx(at,cycle*12+start+(index+1)*0.12),"missile spacing is120ms and rest periods never bank shots")
		for boundary in [4.0,5.0,10.0,11.0]:check(not Scheduler.in_window(channel,boundary),"both wings remain silent throughout both gaps")
		var e: Dictionary=Catalog.create(kind,Vector2(168 if kind==143 else 232,107))
		var definition: Dictionary=Catalog.definition(kind)
		var uv:=Vector2((670.0-68)/1281,(660.0-45)/1007)
		var expected_muzzle: Vector2=Geometry.image_point(definition,e.pos,uv,Vector2(1281,1007))
		var side: int=-1 if kind==143 else 1
		Rng.state=0x50000
		var seen: Dictionary={}
		var launch_events: Array=Scheduler.advance({},[channel],120,func(_c):return true)
		var shots: Array=Fire.advance(e,120,Vector2(175,380))
		for i in range(shots.size()):
			var shot: Dictionary=shots[i]
			var at: float=launch_events[i].at
			var angle: float=deg_to_rad(15 if kind==143 else -15)*(1-cos(TAU*at/6))/2
			expected_muzzle=e.pos+Vector2(channel.volley.ports[0][0],channel.volley.ports[0][1]).rotated(angle)
			check(shot.kind==2 and is_equal_approx(shot.velocity.y,-33.333333333333336),"existing missile type and initial upward speed are used")
			check(shot.pos.distance_to(expected_muzzle)<0.001,"missile emerges at the actual mirrored artwork pod centre")
			var speed_x: float=shot.velocity.x*side
			check(speed_x>=5 and speed_x<=50,"missile Xspeed stays within the requested outward5to50px/s range")
			seen[roundi(speed_x)]=true
		check(seen.size()==46 and seen.has(5) and seen.has(50),"random launch samples cover all46integer speeds including endpoints")
		e.hp=0
		check(Fire.advance(e,12).is_empty(),"destroyed wing stops firing")
	var left: Dictionary=Catalog.create(143,Vector2(168,107))
	var right: Dictionary=Catalog.create(144,Vector2(232,107))
	check(Fire.advance(left,0.119).is_empty() and Fire.advance(right,0.119).is_empty(),"neither wing fires at spawn")
	check(Fire.advance(left,0.001).size()==1 and Fire.advance(right,0.001).is_empty(),"only left wing starts at120ms")
	check(Fire.advance(right,5.99).is_empty() and Fire.advance(right,0.01).size()==1,"right wing starts at6.12seconds independently of left")
	var left_port: Array=left_channel.volley.ports[0]
	var right_port: Array=right_channel.volley.ports[0]
	check(is_equal_approx(left_port[0],-right_port[0]) and is_equal_approx(left_port[1],right_port[1]),"launch ports mirror around each wing hinge")
	check(Catalog.definition(141).hp==1000 and Catalog.definition(142).hp==1000 and Catalog.definition(143).hp==800 and Catalog.definition(144).hp==800,"requested arm/wing HP are retained")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

extends SceneTree
const Scheduler = preload("res://scripts/attack_timer.gd")
const Fire = preload("res://scripts/enemy_fire.gd")
const Boss = preload("res://scripts/boss.gd")
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Game = preload("res://scripts/game.gd")
const Clock = preload("res://scripts/timing.gd")
const Rng = preload("res://scripts/random.gd")
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for id in Catalog.ids():
		for channel in Catalog.definition(id).get("fire_channels",[]):
			var owner: Dictionary = {}
			var events: Array = []
			for tick in range(540): events.append_array(Scheduler.advance(owner,[channel],1.0/60,func(_c): return true))
			var coarse: Array = Scheduler.advance({},[channel],9.0,func(_c): return true)
			var same: bool = events.size()==coarse.size()
			if same:
				for i in range(events.size()): same = same and is_equal_approx(events[i].at,coarse[i].at)
			check(same,"entity%d/%s native ticks and9second catchup produce identical event times"%[id,channel.name])
			if not channel.has("window_seconds"):
				check(events.size()==floori(9.0/float(channel.interval_seconds)+0.000001),"entity%d/%s maintains configured rate across all former wrap boundaries"%[id,channel.name])
				var uniform := true
				for i in range(1,events.size()): uniform = uniform and is_equal_approx(events[i].at-events[i-1].at,float(channel.interval_seconds))
				check(uniform,"entity%d/%s has constant event spacing"%[id,channel.name])
			else:
				var expected: Array=window_times(channel,9.0)
				var matches: bool=expected.size()==events.size()
				for i in range(mini(expected.size(),events.size())):matches=matches and is_equal_approx(float(expected[i]),float(events[i].at))
				check(matches,"entity%d/%s obeys its declared burst/rest windows without banking shots"%[id,channel.name])
	# Fixed examples test the timer contract independently of the catalog's enemy IDs/count.
	var timed: Array=Scheduler.advance({},[{"name":"probe","interval_seconds":0.25,"window_seconds":[3.0,1.0,2.0]}],6.0,func(_c):return true)
	check(timed.map(func(e):return e.at)==[1.25,1.5,1.75,4.25,4.5,4.75],"synthetic windows exclude endpoints and never bank cooldown time")
	var a: Dictionary = Catalog.create(1,Vector2(100,100))
	var b: Dictionary = Catalog.create(1,Vector2(100,100))
	var player := Vector2(175,380)
	var wing: Dictionary = Catalog.create(2,Vector2(100,79.99))
	check(Fire.advance(wing,1.0,player).is_empty(),"variable wing does not fire aimed orange shots aboveY80")
	wing.pos.y = 80
	check(Fire.advance(wing,0.47,player).is_empty() and Fire.advance(wing,0.01,player).size()==1,"variable wing enables aim atY80 with480ms cadence and no banked shots")
	wing = Catalog.create(2,Vector2(100,79.99))
	wing.velocity.x = 100
	check(Fire.advance(wing,0.18,player).size()==1,"variable wing moving shot remains enabled aboveY80")
	check(Fire.advance(a,0.35,player).is_empty() and Fire.advance(b,0.1,player).is_empty(),"new actors each wait their own first interval")
	check(Fire.advance(a,0.01,player).size()==1 and Fire.advance(b,0.01,player).is_empty(),"one actor firing cannot advance another actor clock")
	a.velocity.y = (4/0.03)
	check(Fire.advance(a,5,player).is_empty(),"disabled movement gate emits no queued attacks")
	a.velocity.y = (0/0.03)
	check(Fire.advance(a,0.35,player).is_empty() and Fire.advance(a,0.01,player).size()==1,"reactivated gate waits one complete interval without a burst")
	a.hp = 0
	check(Fire.advance(a,10,player).is_empty(),"destroyed actors cannot fire")
	var body: Dictionary = Catalog.create(92,Vector2(200,100))
	var parts: Array = [Catalog.create(111,Vector2.ZERO),Catalog.create(112,Vector2.ZERO),Catalog.create(113,Vector2.ZERO)]
	check(Boss.advance(body,parts,10).all(func(s):return s.pos.x==200),"stage2 only chest fan fires while centre survives; enrage cannot bank attacks")
	check(body.hp==1250 and body.max_hp==1250,"stage2 bodyHP is1250")
	check(parts[0].hp==300 and parts[1].hp==300 and parts[2].hp==400,"stage2 armsHP300 each and centreHP400")
	check(Boss.advance(Catalog.create(92,Vector2.ZERO),[parts[2]],1).all(func(s):return s.pos.x==0),"centre alone enables chest fan and suppresses enrage after both arms are destroyed")
	var dead_centre: Dictionary = parts[2].duplicate(true)
	dead_centre.hp = 0
	check(Boss.advance(Catalog.create(92,Vector2.ZERO),[parts[0],parts[1],dead_centre],0.09).size()==2,"dead centre pending removal enables enrage while both arms survive")
	parts.pop_back()
	Rng.state = 0x50000
	check(Boss.advance(body,parts,0.089).is_empty() and Rng.state==0x50000,"stage2 enrage waits90ms without consuming RNG")
	var shots: Array = Boss.advance(body,parts,0.001)
	check(shots.size()==2 and shots.all(func(s): return s.kind==5),"stage2 emits simultaneous pink orb pair at90ms with both arms still alive")
	check(shots[0].pos==Vector2(215,160) and shots[1].pos==Vector2(185,160),"stage2 retains both original muzzle positions")
	var total := 0
	body = Catalog.create(92,Vector2(200,100))
	for tick in range(540): total += Boss.advance(body,[],1.0/60).size()
	check(total==200,"stage2 has exactly100paired volleys over9seconds without wrap gaps")
	check(Boss.advance(Catalog.create(92,Vector2(200,100)),[],0.27).size()==6,"large stage2 time step retains all three due volleys")
	body = Catalog.create(93,Vector2(200,100))
	shots = Boss.advance(body,[],9,player)
	check(shots.filter(func(s): return s.kind==6).size()==116 and shots.filter(func(s): return s.kind==2).size()==36,"stage3 alternating300ms fans and480ms missiles retain their configured rates")
	var window_channel: Dictionary = Catalog.definition(121).fire_channels[0]
	check(Scheduler.advance({},[window_channel],1.8,func(_c): return true).is_empty(),"left arm rests before its local firing window opens")
	var invalid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	invalid.entities["1"].fire_channels[0].interval_seconds = 0
	check(not Catalog.validate_document(invalid).is_empty(),"invalid zero channel interval rejected")
	invalid = JSON.parse_string(FileAccess.get_file_as_string(Catalog.PATH))
	invalid.entities["111"].fire_channels[0].window_seconds = [2,1,3]
	check(not Catalog.validate_document(invalid).is_empty(),"invalid rest window rejected")
	var g = Game.new()
	g.automatic = false
	g.mute = true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g._load_stage(2)
	g.delta_seconds = 0.03
	g.events = []
	g.boss = Catalog.create(92,Vector2(200,100))
	g.enemies.clear()
	g.bullets.clear()
	g.invulnerability_seconds = 300.0
	for i in range(5): g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.bullets.is_empty(),"native stage2 loop emits nothing before90ms")
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.bullets.size()==2 and g.bullets.all(func(s): return s.kind==5),"native stage2 sixth tick emits pink orb pair using independent90ms clock")
	var velocity_before: Vector2 = g.bullets.at(0).velocity
	g._update_bullets()
	check(g.bullets.at(0).velocity==velocity_before,"pink orbs have no fireball gravity")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures==0 else 1)

func window_times(channel: Dictionary,horizon: float) -> Array:
	var window: Array=channel.window_seconds
	var interval: float=channel.interval_seconds
	var times: Array=[]
	if float(window[1])==0 and float(window[2])==float(window[0]):
		for i in range(1,floori(horizon/interval+0.0000001)+1):times.append(i*interval)
		return times
	var cycle: int=0
	while cycle*float(window[0])+float(window[1])<horizon:
		var start: float=cycle*float(window[0])+float(window[1])
		var finish: float=cycle*float(window[0])+float(window[2])
		var step: int=1
		while start+step*interval<finish-0.0000001 and start+step*interval<=horizon+0.0000001:
			times.append(start+step*interval);step+=1
		cycle+=1
	return times

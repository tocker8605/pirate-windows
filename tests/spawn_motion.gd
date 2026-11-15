extends SceneTree
const Game=preload("res://scripts/game.gd")
const Clock=preload("res://scripts/timing.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Movement=preload("res://scripts/movement.gd")
const Boss=preload("res://scripts/boss.gd")
var checks:=0
var failures:=0
func check(ok:bool,message:String)->void:
	checks+=1
	if ok:print("PASS: "+message)
	else:
		failures+=1
		push_error("FAIL: "+message)
func _initialize()->void:call_deferred("run")
func run()->void:
	var g=Game.new()
	g.automatic=false
	g.mute=true
	root.add_child(g)
	await process_frame
	g.set_process(false)
	var reference=[]
	for phase in [0.0,0.05,0.13,0.26]:
		g._load_stage(1)
		g.clock=Clock.new()
		g.clock.animation_elapsed_seconds=phase
		g.events=[]
		for index in range(8):
			g.events.append({"at":0.5+index*0.5,"action":"spawn","definition_id":10 if index%4==3 else 1,"position":[50+index*30,-50],"pattern":1011 if index%4<2 else 1012})
		g.supply_director.schedule=[]
		g.invulnerability_seconds=10000
		var records=[]
		var owners={}
		for tick in range(300):
			g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
			for e in g.enemies:
				if not owners.has(e.entity_id):
					owners[e.entity_id]=records.size()
					records.append({"birth":g.stage_elapsed_seconds,"entry":-1.0,"immediate":e.pos.y> -50})
				var record=records[owners[e.entity_id]]
				if record.entry<0 and e.pos.y>=0:record.entry=g.stage_elapsed_seconds
		check(records.size()==8,"phase%.2f creates all eight scheduled actors"%phase)
		check(records.all(func(r):return r.immediate and r.entry>0),"phase%.2f actors move immediately on their spawn tick"%phase)
		var uniform=true
		for i in range(1,records.size()):uniform=uniform and absf(records[i].birth-records[i-1].birth-0.5)<0.00001 and absf(records[i].entry-records[i-1].entry-0.5)<0.00001
		check(uniform,"phase%.2f timeline and visible entry intervals both remain500ms"%phase)
		var entries=records.map(func(r):return r.entry)
		if reference.is_empty():reference=entries
		check(entries==reference,"phase%.2f animation clock cannot change movement timing"%phase)
	for rate in [30,60,120]:
		var actor=Catalog.create(1,Vector2(100,100),1092)
		var dt:float=1.0/rate
		var continuous=true
		for i in range(rate/2):
			var before:float=actor.velocity.y
			Movement.steer(actor,Vector2.ZERO,Vector2.ZERO,dt)
			continuous=continuous and actor.velocity.y>before
			actor.pos+=Movement.displacement(actor.velocity,dt)
		check(continuous and not actor.has("steering_remaining_seconds"),"%dHz acceleration changes every frame without a steering timer"%rate)
		check(absf(actor.velocity.y-Movement.BASE_ACCELERATION*0.5)<0.002,"%dHz retains the same acceleration in pixels per second squared"%rate)
		check(absf(actor.pos.y-100-0.5*Movement.BASE_ACCELERATION*0.25)<1.1,"%dHz displacement stays close to constant-acceleration physics"%rate)
		var body=Catalog.create(92,Vector2(200,100))
		for i in range(rate/2):Boss.steer(body,Vector2(300,400),[],dt)
		check(absf(body.velocity.x-Movement.BASE_ACCELERATION*0.5)<0.002,"%dHz boss steering also uses per-second acceleration"%rate)
	var capped=Catalog.create(1,Vector2(100,100),1092)
	Movement.steer(capped,Vector2.ZERO,Vector2.ZERO,10.0)
	check(absf(capped.velocity.y-Movement.MAX_SPEED)<0.001,"continuous acceleration retains the original speed cap")
	var turning=Catalog.create(1,Vector2(100,200),1011)
	turning.velocity=Vector2(0,166.6666666666667)
	Movement.steer(turning,Vector2.ZERO,Vector2.ZERO,Clock.FIXED_STEP_SECONDS)
	check(turning.pattern==1091 and turning.velocity.y<166.666,"Y threshold begins deceleration in the current frame")
	var oscillator=Catalog.create(4,Vector2(100,100),1061)
	var peaks=[]
	for tick in range(600):
		var pattern:int=oscillator.pattern
		Movement.steer(oscillator,Vector2.ZERO,Vector2.ZERO,Clock.FIXED_STEP_SECONDS)
		if pattern==1061 and oscillator.pattern==1063:peaks.append((tick+1)*Clock.FIXED_STEP_SECONDS)
	check(peaks.size()>=3 and absf((peaks[2]-peaks[1])-3.24)<0.04,"oscillation keeps its authored200px/s peaks and approximately3.24second period")
	g._load_stage(1)
	g.events=[{"at":0,"action":"spawn","definition_id":1,"position":[100,-50],"pattern":1011}]
	g.supply_director.schedule=[]
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	var actor=g.enemies.at(0)
	var position:Vector2=actor.pos
	var velocity:Vector2=actor.velocity
	g.state="paused"
	for i in range(30):g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(actor.pos==position and actor.velocity==velocity,"pause freezes both position and velocity")
	g._load_stage(2)
	g.events=[{"at":0,"action":"spawn","definition_id":1,"position":[100,-50],"pattern":1011}]
	g.supply_director.schedule=[]
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.enemies.at(0).pos.y> -50,"new stage and recycled entity slots cannot inherit a movement wait")
	g._load_stage(2)
	g.events=[{"at":0,"action":"spawn","definition_id":92,"position":[200,-100],"pattern":0}]
	g.supply_director.schedule=[]
	g._tick(Vector2.ZERO,false,false,false,Clock.FIXED_STEP_SECONDS)
	check(g.boss.pos.y> -100,"boss body starts accelerating on its spawn tick")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

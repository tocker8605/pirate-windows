extends SceneTree
const Game=preload("res://scripts/game.gd")
const Style=preload("res://scripts/player_weapon_style.gd")
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
	for weapon in range(1,4):
		g._load_stage(1)
		g.events=[]
		g.run_settings = g.run_settings.with_weapon(weapon)
		g.power=1
		g.death_remaining_seconds=0.03
		g.delta_seconds=1.0/60
		g._fire()
		var fx=g.view.vfx
		g.frame=1
		fx.observe(g)
		var launch_count:int=4
		check(fx.particles.filter(func(p):return p.get("player_effect","")=="launch").size()==launch_count,"type%d emits one compact muzzle event per shot/port"%weapon)
		var count:int=fx.particles.size()
		fx.observe(g)
		check(fx.particles.size()==count,"same-frame redraw never duplicates muzzle event")
		g.shots.at(0).impact_remaining_seconds=0.27
		g.frame=2
		fx.observe(g)
		check(fx.particles.filter(func(p):return p.get("player_effect","")=="impact").size()==10,"type%d impact emits ten stronger sparks once"%weapon)
		check(fx.particles.all(func(p):return p.size<=1.5 and p.life<=0.241 and p.color in [Style.color(weapon),Style.highlight(weapon)]),"type%d player effects keep bounded sizes/lifetimes and shared body tones"%weapon)
		g.frame=3
		fx.observe(g)
		check(fx.particles.filter(func(p):return p.get("player_effect","")=="impact").size()==10,"impact state cannot re-emit every tick")
		g.shots.clear()
		g.frame=4
		fx.observe(g)
		check(fx.launches.is_empty() and fx.impacts.is_empty(),"removed shots release emitter ID records")
		for frame in range(5,30):
			g.frame=frame
			fx.observe(g)
		check(fx.particles.is_empty(),"transient muzzle/hit sparks expire without lingering large artwork")
	g.audio.stop_all()
	g.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

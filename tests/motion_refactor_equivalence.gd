extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Pose=preload("res://scripts/entity_pose_motion.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Formation=preload("res://scripts/projectile_formation.gd")
const Game=preload("res://scripts/game.gd")
const PATH="res://tests/fixtures/motion_before_refactor.json"
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in [141,142,143,144]:
		var actor: Dictionary=Catalog.create(kind,Vector2(200,100))
		for tick in range(1200):
			Pose.advance(actor,1.0/60)
			rows.append(["pose",kind,tick,actor.pose_angle])
	for kind in [141,142]:
		var actor: Dictionary=Catalog.create(kind,Vector2(200,100))
		for tick in range(600):
			for shot in Fire.advance(actor,1.0/60):rows.append(["launch",kind,tick,shot.kind,shot.pos.x,shot.pos.y,shot.velocity.x,shot.velocity.y])
	var shot: Dictionary=Fire.advance(Catalog.create(141,Vector2.ZERO),0.48)[0]
	for tick in range(160):
		var delta: Vector2=Formation.advance(shot,[1.0/60,0.013,0.071][tick%3])
		rows.append(["expansion",tick,delta.x,delta.y,shot.formation.age])
	var g=Game.new();g.automatic=false;g.mute=true
	root.add_child(g)
	await process_frame
	g._load_stage(1);g.events=[];g.invulnerability_seconds=999
	for kind in [1,2,3,4,5,6,7,8]:
		g.bullets.clear()
		g._bullet(Vector2(200,60),Vector2(10,-33.333333333333336),kind)
		for tick in range(200):
			g._update_bullets()
			for bullet in g.bullets:rows.append(["physics",kind,tick,bullet.pos.x,bullet.pos.y,bullet.velocity.x,bullet.velocity.y,bullet.render_pos.x,bullet.render_pos.y,bullet.render_velocity.x,bullet.render_velocity.y])
	g.bullets.clear()
	g.BulletPool.group(g,Fire.advance(Catalog.create(141,Vector2(200,-20)),0.48))
	for tick in range(130):
		g._update_bullets()
		for bullet in g.bullets:rows.append(["hexagon",tick,bullet.pos.x,bullet.pos.y,bullet.velocity.x,bullet.velocity.y])
	g.audio.stop_all();g.queue_free();await process_frame;await create_timer(0.2).timeout
	if "--capture" in OS.get_cmdline_user_args():
		var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(rows))
		print("Captured%dpre-refactor motion records"%rows.size());quit();return
	var reference: Array=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var failures: int=0 if rows.size()==reference.size() else 1
	for i in range(mini(rows.size(),reference.size())):
		var same: bool=rows[i].size()==reference[i].size()
		for j in range(mini(rows[i].size(),reference[i].size())):
			if rows[i][j] is float or rows[i][j] is int:same=same and absf(float(rows[i][j])-float(reference[i][j]))<0.00001
			else:same=same and rows[i][j]==reference[i][j]
		if not same:
			failures+=1
			if failures<=5:push_error("FAIL: motion record%d differs: %s / %s"%[i,reference[i],rows[i]])
	print("RESULT: %d checks, %d failures"%[rows.size()+1,failures]);quit(0 if failures==0 else 1)

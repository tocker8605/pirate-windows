extends SceneTree
const Catalog=preload("res://scripts/enemy_catalog.gd")
const Fire=preload("res://scripts/enemy_fire.gd")
const Boss=preload("res://scripts/boss.gd")
const Rng=preload("res://scripts/random.gd")
var rows: Array=[]
var checks: int=0
var failures: int=0
func pack_volley(owner: int, scenario: int, tick: int, shots: Array) -> void:
    for s in shots: rows.append([owner,scenario,tick,s.kind,s.pos.x,s.pos.y,s.velocity.x,s.velocity.y])
func _initialize() -> void:
    var reference: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/attacks_before_structure_refactor.json"))
    var original_ids: Dictionary={}
    for row in reference:original_ids[int(row[0])]=true
    for kind in Catalog.ids():
        if not original_ids.has(kind) or kind in [51,52]:continue # Ground attacks intentionally rebalanced; see turret_health_patterns.
        var d: Dictionary=Catalog.definition(kind)
        if d.role not in ["enemy","part"]:continue
        for scenario in range(3):
            Rng.state=0x50000
            var e: Dictionary=Catalog.create(kind,Vector2(120+scenario*70,100))
            var b: Dictionary=Catalog.create(94,Vector2(200,60))
            for tick in range(720):
                var phase: int=(tick/90)%8
                e.pos.y=[50,100,140,200,300,395,401,80][phase]
                e.velocity=Vector2(0 if phase%2==0 else 80,-200+phase*60)
                e.orb_y_stationary=phase%2==0
                e.orb_stationary=phase%2==0
                e.deployment_progress=1.0
                b.pos.y=50 if phase%2==0 else 140
                b.velocity=Vector2(70,-100)
                var shots: Array=Fire.advance(e,1.0/60,Vector2(40+scenario*130,380),b)
                pack_volley(kind,scenario,tick,shots)
            rows.append([kind,scenario,"rng",Rng.state])
    for stage in range(1,6):
        for scenario in range(3):
            Rng.state=0x50000
            var b: Dictionary=Catalog.create(90+stage,Vector2(200,100))
            var parts: Array=[]
            for kind in Catalog.ids():
                if Catalog.is_part(kind): parts.append(Catalog.create(kind,Vector2.ZERO))
            for tick in range(720):
                if tick==240:parts=[]
                b.velocity=Vector2(40,-100+float(tick%60)*4)
                pack_volley(90+stage,scenario,tick,Boss.advance(b,parts,1.0/60,Vector2(40+scenario*130,380)))
            rows.append([90+stage,scenario,"rng",Rng.state])
    reference=reference.filter(func(row):return int(row[0]) not in [51,52])
    # Redesigned plasma angles are covered by charge_aimed_sequence; keep orange shots/RNG checks.
    var unchanged_plasma: Callable=func(row):return not (row.size()>4 and int(row[0]) in [22,131,132] and int(row[3])==5)
    reference=reference.filter(unchanged_plasma)
    rows=rows.filter(unchanged_plasma)
    # Stage5 arms/wings now have authored attacks; their new volleys/RNG are tested separately.
    reference=reference.filter(func(row):return int(row[0]) not in [141,142,143,144])
    rows=rows.filter(func(row):return int(row[0]) not in [141,142,143,144])
    # Stage3 angular arms and alternating shoulder fans have dedicated behavior coverage.
    var unchanged_stage3: Callable=func(row):return not (row.size()>4 and (int(row[0]) in [121,122,123,124] or (int(row[0])==93 and int(row[3])==6)))
    reference=reference.filter(unchanged_stage3)
    rows=rows.filter(unchanged_stage3)
    # New stage2 chest fan uses X200; retain all original side-muzzle enrage/RNG records.
    rows=rows.filter(func(row):return not (int(row[0])==92 and row.size()>4 and is_equal_approx(float(row[4]),200)))
    # Stage1 body now fires paired angular sweeps; boss1_rocket_fists verifies its new behavior.
    reference=reference.filter(func(row):return not (int(row[0])==91 and row.size()>4))
    rows=rows.filter(func(row):return not (int(row[0])==91 and row.size()>4))
    # Stage5 body patterns are intentionally new; preserve its RNG checkpoint.
    reference=reference.filter(func(row):return not (int(row[0])==95 and row.size()>4))
    rows=rows.filter(func(row):return not (int(row[0])==95 and row.size()>4))
    reference=reference.filter(func(row):return not (int(row[0])==145 and row.size()>4))
    rows=rows.filter(func(row):return not (int(row[0])==145 and row.size()>4))
    # HeavyB fan speed is deliberately250px/s; preserve missile and RNG comparisons.
    var old_heavy_fan: Callable=func(row):return not (row.size()>4 and int(row[0])==42 and int(row[3])==6)
    reference=reference.filter(old_heavy_fan)
    rows=rows.filter(old_heavy_fan)
    # Requested normal-enemy ballistics tuning has dedicated speed/cadence/trajectory tests.
    var tuned: Dictionary={1:[1],2:[1],3:[5],5:[6],6:[7],11:[7,5],10:[1],21:[1],22:[7],41:[6]}
    var unchanged_ballistics: Callable=func(row):return not (row.size()>4 and int(row[3]) in tuned.get(int(row[0]),[]))
    reference=reference.filter(unchanged_ballistics);rows=rows.filter(unchanged_ballistics)
    checks+=1
    if rows.size()!=reference.size():failures+=1;push_error("FAIL: volley record count differs")
    for i in range(mini(rows.size(),reference.size())):
        checks+=1
        var a: Array=reference[i]
        var b: Array=rows[i]
        var same: bool=a.size()==b.size()
        for j in range(a.size()):
            if j<4:same=same and a[j]==b[j]
            else:same=same and absf(float(a[j])-float(b[j]))<0.001
        if not same:
            failures+=1
            if failures<=5:push_error("FAIL: volley checkpoint%d differs: %s / %s"%[i,a,b])
    print("RESULT: %d checks, %d failures"%[checks,failures])
    quit(0 if failures==0 else 1)

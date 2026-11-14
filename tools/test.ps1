param(
 [string]$Godot = 'godot',
 [string]$AudioDriver = 'WASAPI',
 [switch]$Render
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$logRoot=Join-Path $projectRoot 'work\test-logs'
New-Item -ItemType Directory -Force -Path $logRoot|Out-Null
$import=& $Godot --headless --path $projectRoot --editor --import --quit 2>&1
$import|Set-Content (Join-Path $logRoot 'import.log') -Encoding utf8
if(($import-join"
") -match 'SCRIPT ERROR|ERROR:'){throw 'Project import contained errors'}
if($LASTEXITCODE -ne 0){throw 'Project import failed'}
$tests=@('smoke','combat_reference','special_effects','campaign','presentation_audio','full_audit','pool_reference','random_reference','combat_vfx','entity_store','entity_scale','renewal','regions_turning','stage4_regions','presentation','native_tick','boss_mecha','carrier_reward','cockpit_fireball','weapon_parallel','claw_smoke','supply_boss_v20','enemy_catalog','weapon_motion','spiral_contact','ascent_depth','projectile_trails','boss_body_patterns','folding_speed_spread','heavy_aimed_fan','boss3_aimed_fan','player_energy','boss4_core_centre','independent_fire','timeline_seconds','boss_shield_score','core_radial','boss3_orb_cross','boss3_orb_stations','rewards_damage','refactor_contracts','refactor_equivalence')
if($Render){$tests+=@('render_rop','render_renewal','render_60fps','render_title_earth','render_combat_style','render_vfx_strength','render_catalog_hud','render_station_weapons','render_smoke_overlay','render_ascent_depth','render_fireball_cache','render_boss4_final','render_cloud_copies','render_streak_cache','render_boss4_sweep','render_heavy_fans','render_core_radial','render_boss3_rework','render_rush_background','render_particle_extent')}
$total=0
foreach($name in $tests){
 $arguments=@('--path',$projectRoot,'--script',"tests/$name.gd")
 if($name -like 'render_*'){$arguments+=@('--position','0,0')}else{$arguments+=@('--headless','--audio-driver',$AudioDriver)}
 $output=& $Godot @arguments 2>&1
 $status=$LASTEXITCODE
 $lines=$output|ForEach-Object{$_.ToString()}
 $lines|Set-Content (Join-Path $logRoot "$name.log") -Encoding utf8
 $result=[regex]::Match(($lines-join"`n"),'RESULT: (\d+) checks, 0 failures')
 if($status -ne 0 -or -not$result.Success -or ($lines-join"`n") -match 'SCRIPT ERROR|ERROR:|FAIL:'){throw "Validation failed: $name; see $logRoot"}
 $total+=[int]$result.Groups[1].Value
 Write-Output "$name passed ($($result.Groups[1].Value))"
}
Write-Output "All $total checks passed. Logs: $logRoot"

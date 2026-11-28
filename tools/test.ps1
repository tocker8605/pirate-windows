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
$tests=@('smoke','combat_reference','enemy_ballistics_tuning','player_beam_limit','special_effects','campaign','presentation_audio','full_audit','pool_reference','random_reference','combat_vfx','entity_store','entity_scale','renewal','regions_turning','stage4_regions','background_assets','stage5_ground','stage_resource_loading','stage5_boss_support','boss_rush_stage5','turret_health_patterns','presentation','native_tick','boss_mecha','boss_arm_y_alignment','boss_offscreen','carrier_reward','cockpit_fireball','weapon_parallel','claw_smoke','supply_boss_v20','enemy_catalog','entity_sprites','weapon_motion','spiral_contact','ascent_depth','projectile_trails','boss_body_patterns','boss_timeout','boss1_rocket_fists','boss2_chest_fan','boss12_refactor_equivalence','boss12_cleanup_contracts','folding_speed_spread','heavy_aimed_fan','boss3_aimed_fan','player_energy','boss4_core_centre','independent_fire','timeline_seconds','boss_shield_score','core_radial','boss3_orb_cross','boss3_orb_stations','rewards_damage','refactor_contracts','structure_extensibility','refactor_equivalence','expansion_equivalence','manual_sync','simulation_contracts','charge_aimed_sequence','stage5_wing_missiles','stage5_body_patterns','stage5_low_health_beams','stage5_autocannon','beam_timing_equivalence','stage5_part_effects','rotating_entity_geometry','stage5_gatling','motion_refactor_equivalence','shared_motion_state','stage5_rush_drops','stage5_chest_beams','beam_visual_effects','beam_visual_equivalence','beam_refactor_contracts','twin_muzzle_symmetry','health_supply','damage_supply','timeline_comments','spawn_motion','player_weapon_effects','power_supply_energy','player_focus','menu_flow','run_flow','mission_banner','score_ranking','clear_screen','end_flow_policies','music_repeat')
if($Render){$tests+=@('render_rop','render_renewal','render_60fps','render_title_earth','render_combat_style','render_vfx_strength','render_catalog_hud','render_station_weapons','render_smoke_overlay','render_ascent_depth','render_fireball_cache','render_boss4_final','render_cloud_copies','render_streak_cache','render_boss4_sweep','render_heavy_fans','render_core_radial','render_boss3_rework','render_rush_background','render_particle_extent','render_twin_muzzles','render_health_supply','render_stage5_ground','render_player_weapons','render_clear_screen')}
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

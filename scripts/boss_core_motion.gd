extends RefCounted
## Detached core: bounded upward launch, transfer to centre, then stationary.
const Catalog = preload("res://scripts/enemy_catalog.gd")
const Clock = preload("res://scripts/timing.gd")
const KIND: int = 133
const PATTERN: int = 2401
const DETACH_HP: float = 200.0
const SPEED: float = 5.0 # Transfer speed in pixels per authored30ms unit.
const LAUNCH_SPEED: float = 5.0/Clock.AUTHORED_TICK_SECONDS
const LAUNCH_DECELERATION: float = 1.0/(9.0*Clock.AUTHORED_TICK_SECONDS*Clock.AUTHORED_TICK_SECONDS)
const SCREEN_SIZE := Vector2(400,480)
const TARGET_CENTRE := SCREEN_SIZE/2
const VERTICAL_MARGIN: float = 8.0
const EPSILON: float = 0.0000001
static func active(e: Dictionary) -> bool:
 return int(e.kind)==KIND and int(e.pattern)==PATTERN
static func target() -> Vector2:
 var definition: Dictionary = Catalog.definition(KIND)
 return TARGET_CENTRE-definition.draw_offset-definition.draw_size/2
static func vertical_bounds() -> Vector2:
 var definition: Dictionary = Catalog.definition(KIND)
 return Vector2(VERTICAL_MARGIN-definition.draw_offset.y,SCREEN_SIZE.y-VERTICAL_MARGIN-definition.draw_offset.y-definition.draw_size.y)
static func detach(e: Dictionary) -> void:
 e.pattern = PATTERN
 var bounds: Vector2 = vertical_bounds()
 e.pos.y = clampf(e.pos.y,bounds.x,bounds.y)
 e.core_launch_origin = e.pos
 # Limit the impulse so the analytic apex stays inside the visible screen.
 # Near the top this naturally shortens/softens the launch rather than clipping it.
 e.core_launch_speed = minf(LAUNCH_SPEED,sqrt(2*LAUNCH_DECELERATION*maxf(0,e.pos.y-bounds.x)))
 e.core_launch_duration = float(e.core_launch_speed)/LAUNCH_DECELERATION
 e.core_launch_elapsed = 0.0
 e.core_phase = "launch" if e.core_launch_duration>EPSILON else "transfer"
 e.velocity = Vector2(0,-float(e.core_launch_speed)*Clock.AUTHORED_TICK_SECONDS) if e.core_phase=="launch" else e.pos.direction_to(target())*SPEED
static func advance(e: Dictionary, units: float) -> void:
 var remaining: float = maxf(0,units)*Clock.AUTHORED_TICK_SECONDS
 var bounds: Vector2 = vertical_bounds()
 if e.get("core_phase","transfer")=="launch":
  var duration: float = e.core_launch_duration
  var elapsed: float = e.core_launch_elapsed
  var step: float = minf(remaining,maxf(0,duration-elapsed))
  elapsed = minf(duration,elapsed+step)
  e.core_launch_elapsed = elapsed
  e.pos.y = clampf(e.core_launch_origin.y-float(e.core_launch_speed)*elapsed+0.5*LAUNCH_DECELERATION*elapsed*elapsed,bounds.x,bounds.y)
  e.velocity = Vector2(0,(-float(e.core_launch_speed)+LAUNCH_DECELERATION*elapsed)*Clock.AUTHORED_TICK_SECONDS)
  remaining = maxf(0,remaining-step)
  if elapsed>=duration-EPSILON: e.core_phase = "transfer"
 if e.get("core_phase","transfer")=="transfer":
  var destination: Vector2 = target()
  e.pos = e.pos.move_toward(destination,SPEED*remaining/Clock.AUTHORED_TICK_SECONDS)
  e.pos.y = clampf(e.pos.y,bounds.x,bounds.y)
  if e.pos==destination: e.core_phase = "settled"
  e.velocity = Vector2.ZERO if e.pos==destination else e.pos.direction_to(destination)*SPEED
 elif e.get("core_phase","")=="settled":
  e.pos = target()
  e.velocity = Vector2.ZERO

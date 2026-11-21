extends RefCounted
## Simulation-owned rigid pose, independent of attack cadence and presentation effects.
const PoseCurve=preload("res://scripts/pose_curve.gd")
const Catalog=preload("res://scripts/enemy_catalog.gd")
static func angle(curve: Dictionary,age: float) -> float:
	return PoseCurve.sample(curve,age)
static func advance(actor: Dictionary,seconds: float) -> void:
	var settings: Dictionary=Catalog.for_actor(actor).get("pose_curve",{})
	if settings.is_empty() or actor.get("hp",0)<=0:return
	actor.pose_age=float(actor.get("pose_age",0))+seconds
	actor.pose_pivot=settings.pivot
	actor.pose_angle=angle(settings,actor.pose_age)
static func angle_at_event(actor: Dictionary,fired_at: float) -> float:
	if fired_at<0 or not actor.has("pose_age"):return float(actor.get("pose_angle",0))
	var settings: Dictionary=Catalog.for_actor(actor).get("pose_curve",{})
	if settings.is_empty():return float(actor.get("pose_angle",0))
	# The scheduler supplies exact within-step times, including multiple catchup shots.
	return angle(settings,float(actor.pose_age)+fired_at-float(actor.get("fire_age",0)))

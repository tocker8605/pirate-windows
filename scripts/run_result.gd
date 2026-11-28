extends RefCounted
## Capture once at run end; later input/menu changes cannot rewrite this result.
const Ranking=preload("res://scripts/score_ranking.gd")
var _record: Dictionary
var _ranking_eligible: bool
var _cleared: bool
var record: Dictionary:
	get: return _record
var ranking_eligible: bool:
	get: return _ranking_eligible
var cleared: bool:
	get: return _cleared
func _init(points: int,settings: RefCounted,mission: int,finished_campaign: bool) -> void:
	_record={"score":clampi(points,0,Ranking.MAX_SCORE),"weapon":settings.weapon,"level":settings.difficulty,"mission":mission}
	if finished_campaign:_record.cleared=true
	_record.make_read_only()
	_ranking_eligible=settings.qualifies_for_ranking()
	_cleared=finished_campaign

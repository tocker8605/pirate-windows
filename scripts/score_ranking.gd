extends RefCounted
const Campaign = preload("res://scripts/campaign_rules.gd")
## Top10 local records. Ties preserve the order in which names were submitted.
const LIMIT: int = 10
const MAX_SCORE: int = 9999999
const NAME_LENGTH: int = 6
const CHARACTERS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
const PATH: String = "user://rankings.json"
var path: String
var entries: Array = []
var initialization_error: Error = OK
func _init(save_path: String = PATH) -> void:
	path = save_path
	_load()
static func score_text(points: int) -> String:
	return str(clampi(points,0,MAX_SCORE)).lpad(7," ")
static func clean_name(value: String) -> String:
	var result: String = ""
	for letter in value.to_upper():
		if letter in CHARACTERS: result += letter
		if result.length()==NAME_LENGTH: break
	return result.rpad(NAME_LENGTH," ")
static func valid_record(value: Variant) -> bool:
	if not value is Dictionary: return false
	for field in ["score","weapon","level","mission"]:
		var number: Variant = value.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or float(number)!=int(number): return false
	return value.get("name") is String and value.name==clean_name(value.name) and value.score>=0 and value.score<=MAX_SCORE and value.weapon>=1 and value.weapon<=3 and value.level>=1 and value.level<=5 and value.mission>=1 and value.mission<=Campaign.stage_count()
static func normalized_record(value: Dictionary) -> Dictionary:
	# JSON numbers reload as floats; the display and live records use integers.
	return {"score":int(value.score),"name":str(value.name),"weapon":int(value.weapon),"level":int(value.level),"mission":int(value.mission)}
func _load() -> void:
	if not FileAccess.file_exists(path):
		for i in range(LIMIT):
			entries.append({"score":(LIMIT-i)*1000,"name":" ".repeat(NAME_LENGTH),"weapon":1,"level":1,"mission":1})
		initialization_error = _save(entries)
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK: return
	var document: Variant = parser.data
	if not document is Dictionary or document.get("schema_version")!=1 or not document.get("entries") is Array: return
	for record in document.entries:
		if valid_record(record):
			var position: int = insertion_index(int(record.score))
			if position>=0:
				entries.insert(position,normalized_record(record))
				if entries.size()>LIMIT: entries.resize(LIMIT)
func insertion_index(points: int) -> int:
	var candidate: int = clampi(points,0,MAX_SCORE)
	for i in range(entries.size()):
		if candidate>int(entries[i].score): return i
	return entries.size() if entries.size()<LIMIT else -1
func submit(record: Dictionary, player_name: String) -> Error:
	var value: Dictionary = record.duplicate()
	value.name = clean_name(player_name)
	if not valid_record(value): return ERR_INVALID_DATA
	value = normalized_record(value)
	var position: int = insertion_index(int(value.score))
	if position<0: return ERR_ALREADY_EXISTS
	var updated: Array = entries.duplicate(true)
	updated.insert(position,value)
	if updated.size()>LIMIT: updated.resize(LIMIT)
	var error: Error = _save(updated)
	if error==OK: entries = updated
	return error
func _save(records: Array) -> Error:
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema_version":1,"entries":records}))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error!=OK: return error
	return DirAccess.rename_absolute(path+".tmp",path)

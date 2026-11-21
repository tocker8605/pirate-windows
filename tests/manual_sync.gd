extends SceneTree
## Protect the standalone manual against catalog and timeline drift without a Python runtime.
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:
	var text: String=FileAccess.get_file_as_string("res://docs/stage-timeline-manual.html")
	var regex=RegEx.new()
	regex.compile('<script id="manual-data" type="application/json">(.*?)</script>')
	var block=regex.search(text)
	if block==null:
		push_error("FAIL: manual snapshot block is missing")
		quit(1)
		return
	var snapshot: Dictionary=JSON.parse_string(block.get_string(1))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json")).entities
	check(snapshot.catalog==catalog,"manual catalog matches source JSON; run python tools/sync_timeline_manual.py to refresh")
	var stages: Dictionary={}
	for name in DirAccess.get_files_at("res://data"):
		if name.length()==12 and name.begins_with("stage") and name.ends_with(".json") and name.substr(5,2).is_valid_int():
			var key: String=str(int(name.substr(5,2)))
			stages[key]=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+name))
	check(snapshot.stages==stages,"manual timeline samples match all stage JSON files, excluding backups")
	for key in catalog:
		check(text.contains("<td>%s</td><td><code>%s</code>"%[key,catalog[key].name]),"manual table includes entity"+key)
	for key in stages:check(text.contains('<option value="%s">'%key),"manual selector includes stage"+key)
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

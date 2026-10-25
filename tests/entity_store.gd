extends SceneTree
const Store = preload("res://scripts/entity_store.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)
func _initialize() -> void:
	var store = Store.new()
	check(store.is_empty() and store.valid(),"empty active store has consistent links and index")
	var first: int = store.append({"number":1})
	var middle: int = store.append({"number":2})
	var last: int = store.append({"number":3})
	check(store.size()==3 and store.lookup(middle).number==2,"stable ID lookup resolves the right entity")
	check(store.remove(middle) and not store.contains(middle) and store.valid(),"middle removal unlinks both neighbors and index")
	var seen: Array = []
	for value in store: seen.append(value.number)
	check(seen==[1,3],"deletion preserves deterministic spawn order")
	check(store.remove(first) and store.valid() and store.at(0).number==3,"head removal preserves the remaining chain")
	check(store.remove(last) and store.is_empty() and store.valid(),"tail removal empties head, tail and index")
	check(not store.remove(last) and store.lookup(last).is_empty(),"stale IDs cannot delete another object")
	var reused: int = store.append({"number":4})
	check(reused>last,"deleted handles are never recycled into a different entity")
	store.clear()
	for i in range(10000): store.append({"number":i})
	check(store.size()==10000 and store.valid(),"ten thousand simultaneous entities exceed legacy limits without missing entries")
	var visited: int = 0
	for value in store:
		visited += 1
		if value.number%2==0: store.remove(value.entity_id)
	check(visited==10000 and store.size()==5000 and store.valid(),"in-place current-entry deletion neither skips nor repeats iteration")
	seen.clear()
	for outer in store:
		for inner in store:
			seen.append([outer.number,inner.number])
			break
		if seen.size()==2: break
	check(seen==[[1,1],[3,1]],"nested iterators keep independent positions")
	var detached: Array = store.snapshot()
	detached[0].number = -1
	check(store.at(0).number==1,"diagnostic snapshots do not alias live state")
	for value in store: store.remove(value.entity_id)
	check(store.is_empty() and store.valid(),"removing every current entry leaves no stranded nodes")
	var old_id: int = store.append({"number":9})
	store.clear()
	var new_id: int = store.append({"number":10})
	check(new_id>old_id and store.lookup(old_id).is_empty(),"clear never revives stale handles")
	store.clear()
	for n in [1000,10000]:
		var begin: int = Time.get_ticks_usec()
		for i in range(n): store.append({"number":i})
		var add_us: int = Time.get_ticks_usec()-begin
		begin = Time.get_ticks_usec()
		for entry in store: store.remove(entry.entity_id)
		print("STORE BENCH: n=%d insert=%dus remove=%dus"%[n,add_us,Time.get_ticks_usec()-begin])
	check(store.valid() and store.is_empty(),"stress runs release all active records")
	print("RESULT: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)

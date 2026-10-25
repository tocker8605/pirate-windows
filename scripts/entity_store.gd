class_name PirateEntityStore
extends RefCounted
## Ordered ID map + linked active list. No capacity, free-slot search, sorting or frame copies.
## Insert/ID lookup/removal: expected O(1). Full update: O(active entities).
## Iteration permits removing the CURRENT entry; clear/replacement during iteration is unsupported.
class Entry:
	extends RefCounted
	var id: int
	var value: Dictionary
	var previous: int = -1
	var next: Entry
var _by_id: Dictionary = {}
var _head: Entry
var _tail: Entry
var _next_id: int = 1

func append(value: Dictionary) -> int:
	var entry := Entry.new()
	entry.id = _next_id
	_next_id += 1
	entry.value = value
	value.entity_id = entry.id
	if _tail!=null:
		entry.previous = _tail.id
		_tail.next = entry
	else: _head = entry
	_tail = entry
	_by_id[entry.id] = entry
	return entry.id
func lookup(id: int) -> Dictionary:
	var entry: Entry = _by_id.get(id)
	return entry.value if entry!=null else {}
func contains(id: int) -> bool: return _by_id.has(id)
func remove(id: int) -> bool:
	var entry: Entry = _by_id.get(id)
	if entry==null: return false
	var previous: Entry = _by_id.get(entry.previous)
	if previous!=null: previous.next = entry.next
	else: _head = entry.next
	if entry.next!=null: entry.next.previous = entry.previous
	else: _tail = previous
	_by_id.erase(id)
	# Keep entry.next intact until an in-flight iterator advances off this entry.
	return true
func size() -> int: return _by_id.size()
func is_empty() -> bool: return _head==null
func clear() -> void:
	# Break long reference chains iteratively, avoiding recursive destruction at high counts.
	var entry: Entry = _head
	while entry!=null:
		var following: Entry = entry.next
		entry.next = null
		entry = following
	_head = null
	_tail = null
	_by_id.clear()
	# IDs are never recycled, so a stale ID cannot address a later spawn.
func replace_all(values: Array) -> void:
	clear()
	for value in values: append(value)
func _iter_init(iterator: Array) -> bool:
	iterator[0] = _head
	return _head!=null
func _iter_next(iterator: Array) -> bool:
	iterator[0] = iterator[0].next
	return iterator[0]!=null
func _iter_get(entry: Variant) -> Dictionary: return entry.value
func all(predicate: Callable) -> bool:
	for value in self:
		if not predicate.call(value): return false
	return true
func any(predicate: Callable) -> bool:
	for value in self:
		if predicate.call(value): return true
	return false
func at(ordinal: int) -> Dictionary:
	# Diagnostic/test convenience only; gameplay uses IDs and direct iteration.
	var entry: Entry = _head
	for i in range(ordinal):
		if entry==null: return {}
		entry = entry.next
	return entry.value if entry!=null and ordinal>=0 else {}
func snapshot() -> Array:
	# Explicit detached snapshot for diagnostics; never called by the game update/render loop.
	var result: Array = []
	for value in self: result.append(value.duplicate(true))
	return result
func valid() -> bool:
	var count: int = 0
	var previous: int = -1
	var entry: Entry = _head
	while entry!=null:
		if entry.previous!=previous or _by_id.get(entry.id)!=entry: return false
		previous = entry.id
		entry = entry.next
		count += 1
		if count>_by_id.size(): return false
	return count==_by_id.size() and ((_tail==null and count==0) or (_tail!=null and _tail.id==previous))
func _notification(what: int) -> void:
	if what==NOTIFICATION_PREDELETE:
		# The script cannot dispatch another method after its reference count reaches zero.
		var entry: Entry = _head
		while entry!=null:
			var following: Entry = entry.next
			entry.next = null
			entry = following
		_head = null
		_tail = null
		_by_id.clear()

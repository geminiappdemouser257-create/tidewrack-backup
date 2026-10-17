extends Node
## Journal — discovered-logs system.

signal entry_added(id: String)
signal journal_changed

var _entries: Array[String] = []


func discover(id: String) -> void:
	var clean_id := id.strip_edges()
	if clean_id.is_empty() or clean_id in _entries:
		return
	_entries.append(clean_id)
	entry_added.emit(clean_id)
	journal_changed.emit()


func entries() -> Array[String]:
	return _entries.duplicate()


func has(id: String) -> bool:
	return id in _entries


func clear() -> void:
	if _entries.is_empty():
		return
	_entries.clear()
	journal_changed.emit()


func to_save_data() -> Array[String]:
	return _entries.duplicate()


func from_save_data(raw_entries: Variant) -> void:
	_entries.clear()
	if typeof(raw_entries) == TYPE_ARRAY:
		for item: Variant in raw_entries:
			if typeof(item) == TYPE_STRING:
				var clean_id: String = (item as String).strip_edges()
				if not clean_id.is_empty() and not (clean_id in _entries):
					_entries.append(clean_id)
	journal_changed.emit()

extends Node
## GameState — global save/load and story flags.

signal state_changed

const SAVE_PATH := "user://save.json"
const SAVE_TMP_PATH := "user://save.json.tmp"
const SAVE_BAK_PATH := "user://save.json.bak"
const DEFAULT_SCENE := "res://scenes/game.tscn"
const SAVE_VERSION := 2

var flags: Dictionary = {}
var current_scene: String = DEFAULT_SCENE


func set_flag(name: String, value: Variant) -> void:
	if name.is_empty():
		return
	flags[name] = value
	state_changed.emit()


func get_flag(name: String, default: Variant = false) -> Variant:
	return flags.get(name, default)


func new_game() -> void:
	flags.clear()
	current_scene = DEFAULT_SCENE
	Journal.clear()
	state_changed.emit()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BAK_PATH)


func save_game() -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"scene": current_scene,
		"flags": flags.duplicate(true),
		"journal": Journal.to_save_data(),
	}
	var file := FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameState: could not open save file for writing.")
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, SAVE_BAK_PATH)
	if DirAccess.rename_absolute(SAVE_TMP_PATH, SAVE_PATH) != OK:
		DirAccess.remove_absolute(SAVE_PATH)
		if DirAccess.rename_absolute(SAVE_TMP_PATH, SAVE_PATH) != OK:
			return false
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var data := _read_save_dict(SAVE_PATH)
	if data.is_empty() and FileAccess.file_exists(SAVE_BAK_PATH):
		data = _read_save_dict(SAVE_BAK_PATH)
	if data.is_empty():
		push_error("GameState: save file is corrupt.")
		return false

	var raw_scene: Variant = data.get("scene", DEFAULT_SCENE)
	var candidate: String = raw_scene if typeof(raw_scene) == TYPE_STRING else DEFAULT_SCENE
	current_scene = candidate if ResourceLoader.exists(candidate) else DEFAULT_SCENE

	var loaded_flags: Variant = data.get("flags", {})
	flags = loaded_flags.duplicate(true) if typeof(loaded_flags) == TYPE_DICTIONARY else {}
	Journal.from_save_data(data.get("journal", []))
	state_changed.emit()
	return true


func delete_save() -> void:
	for p in [SAVE_PATH, SAVE_TMP_PATH, SAVE_BAK_PATH]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _read_save_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

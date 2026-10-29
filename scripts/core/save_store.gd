extends RefCounted
## Small versioned local save file for experimental features.
## Uses Godot's user:// directory, NOT the GitHub project directory.

const SAVE_PATH = "user://paleverse_save_v1.json"
const SCHEMA_VERSION = 1
const ContentStore = preload("res://scripts/core/content_store.gd")


static func new_save() -> Dictionary:
	return {
		"version": SCHEMA_VERSION,
		"settings": {"difficulty": "normal"},
		"roster": {"unlocked": []},
		"campaigns": {},
		"battle_records": {}
	}


static func load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return new_save()
	var loaded: Dictionary = ContentStore.read_dictionary(SAVE_PATH)
	if loaded.is_empty():
		push_warning("Paleverse save was unreadable; using fresh session data.")
		return new_save()
	if int(loaded.get("version", -1)) != SCHEMA_VERSION:
		push_warning("Unrecognized Paleverse save version; leaving the existing file untouched.")
		return new_save()

	# Merge missing top-level keys, but leave future/unknown fields intact.
	var merged: Dictionary = new_save()
	merged.merge(loaded, true)
	if typeof(merged.get("settings")) != TYPE_DICTIONARY:
		merged["settings"] = {"difficulty": "normal"}
	if typeof(merged.get("roster")) != TYPE_DICTIONARY:
		merged["roster"] = {"unlocked": []}
	if typeof(merged.get("battle_records")) != TYPE_DICTIONARY:
		merged["battle_records"] = {}
	if typeof(merged.get("campaigns")) != TYPE_DICTIONARY:
		merged["campaigns"] = {}
	return merged


static func write_save(data: Dictionary) -> bool:
	# Save only the current schema, preserving unrelated keys.
	var copy: Dictionary = data.duplicate(true)
	copy["version"] = SCHEMA_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write Paleverse save: " + SAVE_PATH)
		return false
	file.store_string(JSON.stringify(copy, "\t") + "\n")
	file.close()
	return true


static func set_difficulty(data: Dictionary, difficulty_id: String) -> void:
	var settings: Dictionary = data.get("settings", {})
	settings["difficulty"] = difficulty_id
	data["settings"] = settings


static func record_test_victory(data: Dictionary, chapter_id: String, character_id: String, difficulty_id: String) -> void:
	# This is a prototype battle record, not a final campaign unlock rule.
	var key := "%s|%s|%s" % [chapter_id, character_id, difficulty_id]
	var records: Dictionary = data.get("battle_records", {})
	records[key] = int(records.get(key, 0)) + 1
	data["battle_records"] = records


static func unlock_character(data: Dictionary, character_id: String) -> void:
	# Ready for use when narrative campaign unlock rules are implemented.
	var roster: Dictionary = data.get("roster", {"unlocked": []})
	var unlocked: Array = roster.get("unlocked", [])
	if not unlocked.has(character_id):
		unlocked.append(character_id)
	roster["unlocked"] = unlocked
	data["roster"] = roster

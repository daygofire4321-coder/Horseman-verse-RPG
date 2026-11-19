extends RefCounted
## Versioned local saves. Never overwrite an unreadable or newer save silently.
## The backup is the last known-good save, not an extra campaign slot.

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


static func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _valid_current_save(data: Dictionary) -> bool:
	if int(data.get("version", -1)) != SCHEMA_VERSION:
		return false
	for key in ["settings", "roster", "campaigns", "battle_records"]:
		if data.has(key) and typeof(data[key]) != TYPE_DICTIONARY:
			return false
	return true


static func _merge_save(data: Dictionary) -> Dictionary:
	var merged := new_save()
	merged.merge(data, true)
	for key in ["settings", "roster", "campaigns", "battle_records"]:
		if typeof(merged.get(key)) != TYPE_DICTIONARY:
			merged[key] = new_save()[key]
	return merged


static func load_save() -> Dictionary:
	return load_save_from_path(SAVE_PATH)


static func load_save_from_path(path: String) -> Dictionary:
	var primary := _read_save(path)
	if _valid_current_save(primary):
		return _merge_save(primary)
	var backup := _read_save(path + ".bak")
	if _valid_current_save(backup):
		push_warning("Paleverse primary save could not be read; recovered last known-good backup.")
		return _merge_save(backup)
	if FileAccess.file_exists(path):
		push_warning("Paleverse save is unreadable or has an unsupported version; existing file was left untouched.")
	return new_save()


static func write_save(data: Dictionary) -> bool:
	return write_save_to_path(data, SAVE_PATH)


static func write_save_to_path(data: Dictionary, path: String) -> bool:
	# Reject accidental writes using an invalid in-memory state.
	if not _valid_current_save(data):
		push_error("Refusing to write invalid or unsupported save data.")
		return false
	var backup_path := path + ".bak"
	var temp_path := path + ".tmp"
	var primary_exists := FileAccess.file_exists(path)
	var existing := _read_save(path)
	var valid_primary := _valid_current_save(existing)
	if primary_exists and int(existing.get("version", -1)) > SCHEMA_VERSION:
		push_error("Refusing to downgrade a newer save version.")
		return false
	if primary_exists and not valid_primary:
		# A newer-version save must NEVER be replaced by the empty fallback.
		# An unreadable primary may be replaced only when a valid backup exists.
		if not _valid_current_save(_read_save(backup_path)):
			push_error("Refusing to overwrite unsupported or corrupt save without a valid backup.")
			return false
	# Write and close the next save before changing either existing file.
	var staged := data.duplicate(true)
	staged["version"] = SCHEMA_VERSION
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not create temporary Paleverse save: " + temp_path)
		return false
	file.store_string(JSON.stringify(staged, "\t") + "\n")
	file.flush()
	file.close()
	if not _valid_current_save(_read_save(temp_path)):
		push_error("Staged Paleverse save did not pass validation.")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	var target := ProjectSettings.globalize_path(path)
	var temp := ProjectSettings.globalize_path(temp_path)
	var backup := ProjectSettings.globalize_path(backup_path)
	if valid_primary:
		# Only a good primary is allowed to replace the recovery backup.
		if DirAccess.copy_absolute(target, backup) != OK:
			push_error("Could not back up existing Paleverse save; original left untouched.")
			DirAccess.remove_absolute(temp)
			return false
	if primary_exists and DirAccess.remove_absolute(target) != OK:
		push_error("Could not replace existing Paleverse save.")
		DirAccess.remove_absolute(temp)
		return false
	if DirAccess.rename_absolute(temp, target) != OK:
		push_error("Could not install staged save; attempting recovery from backup.")
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(backup, target)
		return false
	return true


static func set_difficulty(data: Dictionary, difficulty_id: String) -> void:
	var settings: Dictionary = data.get("settings", {})
	settings["difficulty"] = difficulty_id
	data["settings"] = settings


static func record_test_victory(data: Dictionary, chapter_id: String, character_id: String, difficulty_id: String) -> void:
	var key := "%s|%s|%s" % [chapter_id, character_id, difficulty_id]
	var records: Dictionary = data.get("battle_records", {})
	records[key] = int(records.get(key, 0)) + 1
	data["battle_records"] = records


static func unlock_character(data: Dictionary, character_id: String) -> void:
	var roster: Dictionary = data.get("roster", {"unlocked": []})
	var unlocked: Array = roster.get("unlocked", [])
	if not unlocked.has(character_id):
		unlocked.append(character_id)
	roster["unlocked"] = unlocked
	data["roster"] = roster

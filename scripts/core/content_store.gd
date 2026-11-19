extends RefCounted
## Cached author-editable JSON definitions. Consumers receive deep copies so
## mutating a character sheet cannot change the shared catalog by accident.

static var _cache: Dictionary = {}


static func clear_cache(path: String = "") -> void:
	if path == "":
		_cache.clear()
	else:
		_cache.erase(path)


static func read_dictionary(path: String) -> Dictionary:
	if _cache.has(path):
		return (_cache[path] as Dictionary).duplicate(true)
	if not FileAccess.file_exists(path):
		push_error("Paleverse content missing: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open Paleverse content: " + path)
		return {}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		push_error("Invalid JSON in %s at line %d: %s" % [path, parser.get_error_line(), parser.get_error_message()])
		return {}
	var data: Variant = parser.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Expected JSON object in " + path)
		return {}
	_cache[path] = (data as Dictionary).duplicate(true)
	return (data as Dictionary).duplicate(true)


static func load_character(character_id: String) -> Dictionary:
	if not character_id.is_valid_filename():
		push_error("Invalid character ID: " + character_id)
		return {}
	return read_dictionary("res://data/characters/%s.json" % character_id)


static func load_chapter(chapter_id: String) -> Dictionary:
	if not chapter_id.is_valid_filename():
		push_error("Invalid chapter ID: " + chapter_id)
		return {}
	return read_dictionary("res://data/chapters/%s.json" % chapter_id)

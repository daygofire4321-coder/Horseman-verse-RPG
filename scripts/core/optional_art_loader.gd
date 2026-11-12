extends RefCounted
## Reliable optional-art loader for GitHub code + separately installed ZIPs.
## Discovers project-root assets and common Windows Extract All layouts
## such as res://Paleverse_Pack_Name/assets/... without mutating user files.
## Image.load handles freshly copied PNG/WebP files even before Godot imports.

static func resolve(relative_path: String) -> String:
	if relative_path == "" or relative_path.begins_with("/") or relative_path.contains("..") or relative_path.contains("\\"):
		return ""
	var cleaned := relative_path.trim_prefix("res://")
	var base := "res://" + cleaned
	if FileAccess.file_exists(base):
		return base
	# Windows may extract into a directory named after the ZIP.
	for folder in DirAccess.get_directories_at("res://"):
		if folder.begins_with("."):
			continue
		var extra := "res://" + folder + "/" + cleaned
		if FileAccess.file_exists(extra):
			return extra
	return ""


static func texture(relative_path: String) -> Texture2D:
	var path := resolve(relative_path)
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var imported: Texture2D = load(path) as Texture2D
		if imported != null:
			return imported
	# Bypass the import database for newly extracted artwork.
	var raw := Image.new()
	if raw.load(path) == OK:
		return ImageTexture.create_from_image(raw)
	return null


static func available(relative_path: String) -> bool:
	return resolve(relative_path) != ""

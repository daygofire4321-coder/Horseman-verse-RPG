extends "res://scripts/prototype_story_v16.gd"
## Prototype 017 — curated chapter illustrations from the author's 1–6.zip.
##
## Only Parts 1–5 use this optional art layer. Each authored story event
## declares a "curated_image" path. Part Six deliberately retains its
## original Cliffside images because the author supplied no replacements.
## If the separate art ZIP hasn't been extracted, legacy story art works.

const CURATED_STORY_ROOT := "res://assets/love_beyond/curated_chapters/"
const PART_THREE_BEAR_FIGHT := "part_03/02_bear_confrontation.webp"
const OptionalArt = preload("res://scripts/core/optional_art_loader.gd")

var current_curated_image := ""


func _curated_image_for(index: int) -> String:
	if index < 0 or index >= story_events.size():
		return ""
	# Recover the most recent illustration when resuming a saved dialogue
	# checkpoint or when a dialogue line has no explicit image change.
	var i := index
	while i >= 0:
		var event: Dictionary = story_events[i]
		var path := str(event.get("curated_image", ""))
		if path != "":
			return path
		# Campaign chapter boundary: prevent Part Five's picture from
		# bleeding into Part Six, which keeps the author's existing assets.
		if str(event.get("kind", "")) == "title":
			return ""
		i -= 1
	return ""


func _display_curated_image(relative_path: String) -> bool:
	if relative_path == "" or relative_path.begins_with("/") or ".." in relative_path:
		return false
	var image: Texture2D = OptionalArt.texture(CURATED_STORY_ROOT + relative_path)
	if image == null:
		return false
	scene_image.texture = image
	scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	current_curated_image = relative_path
	return true


func _show_event() -> void:
	super._show_event()
	if not story_mode or bear_mode or bear_busy or hunt_mode or alley_mode or interlude_mode or battle_demo:
		return
	if event_index < 0 or event_index >= story_events.size():
		return
	# Keep the original authored "image" field as the missing-art fallback.
	# The most recent curated image remains visible across consecutive lines.
	var current_path: String = _curated_image_for(event_index)
	if current_path == "":
		current_curated_image = ""
		return
	if not _display_curated_image(current_path):
		current_curated_image = ""


func _draw_battle() -> void:
	super._draw_battle()
	if bear_mode and duel != null:
		# The original bear *sprite and battle HUD* stay playable. The
		# second author-supplied Part Three image replaces only the forest
		# backdrop during the fight, in line with folder 3/info.txt.
		_display_curated_image(PART_THREE_BEAR_FIGHT)

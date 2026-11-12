extends "res://scripts/prototype_story_v8.gd"
## Prototype 009 — Seven user-supplied environments with an in-game preview.
## Old pixel backgrounds fall back automatically if the optional pack is absent.
## No new shops, story dialogue or character unlocks are invented here.

const LOCATION_IDS := [
	"thundercloud", "forest_clearing", "bear_forest",
	"cliffside_alley", "forest_camp", "market_street", "alric_smithy"
]


func _area_definition(area_id: String) -> Dictionary:
	_read_pixel_data()
	for candidate in pixel_data.get("areas", []):
		var entry: Dictionary = candidate
		if str(entry.get("id", "")) == area_id:
			return entry
	return {}


func _area_texture(area: Dictionary) -> Texture2D:
	# Read the new optimized WEBP first; continue accepting the earlier PNG
	# pack without requiring the player to uninstall anything.
	for key in ["background", "legacy_background"]:
		var filename := str(area.get(key, ""))
		if filename == "":
			continue
		var path := AREA_ART_ROOT + filename
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null


func _set_area_background(area_id: String) -> void:
	var area := _area_definition(area_id)
	if area.is_empty():
		return
	var texture := _area_texture(area)
	if texture != null:
		scene_image.texture = texture
		scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		return
	# Keep the original story art when the downloadable background ZIP has
	# not yet been extracted. The runner intentionally doesn't install art.
	scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
	var fallback := str(area.get("fallback", "forest_hunt.jpg"))
	if area_id == "thundercloud":
		_background(fallback)
	else:
		_set_story_background(fallback)


func _draw_battle() -> void:
	super._draw_battle()
	# Prototype 005 reused the hunting clearing for the bear. The dedicated
	# darker forest now distinguishes this mandatory boss encounter.
	if bear_mode and duel != null:
		_show_pixel_stage("bear_forest", "asmodeus", "grizzly_bear", "Asmodeus", "Grizzly Bear")


func _draw_interlude() -> void:
	super._draw_interlude()
	# The cave is an environment, not a combat scene: show it behind the
	# normal daily-activity menu while preserving all original actions.
	if interlude_mode:
		_set_area_background("forest_camp")


func _show_menu() -> void:
	super._show_menu()
	if not is_instance_valid(frontend_body) or frontend_body.get_child_count() == 0:
		return
	var content: Node = frontend_body.get_child(0).get_child(0)
	_front_button(content, "VIEW SEVEN NEW LOCATIONS", Callable(self, "_show_location_gallery").bind(0), 45.0)


func _show_location_gallery(index: int = 0) -> void:
	_read_pixel_data()
	_ensure_layers()
	_hide_pixel_stage()
	_clear_frontend()
	frontend.show()
	portraits.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	var current: int = clampi(index, 0, LOCATION_IDS.size() - 1)
	var area: Dictionary = _area_definition(LOCATION_IDS[current])
	_set_area_background(LOCATION_IDS[current])

	var content: VBoxContainer = _front_panel()
	_front_label(content, "LOVE BEYOND — LOCATIONS", 28)
	_front_label(content, str(area.get("label", LOCATION_IDS[current])), 19, Color(0.84, 0.92, 1.0))
	_front_label(content, str(area.get("mood", "")), 15, Color(0.74, 0.81, 0.91))
	var artwork: Texture2D = _area_texture(area)
	if artwork != null:
		var picture := TextureRect.new()
		picture.name = "LocationPreviewImage"
		picture.custom_minimum_size = Vector2(680, 351)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.texture = artwork
		content.add_child(picture)
	else:
		var note := _front_label(content, "BACKGROUND PACK NOT INSTALLED\nExtract the ZIP next to project.godot.", 17, Color(0.98, 0.78, 0.58))
		note.custom_minimum_size.y = 230

	_front_label(content, "%d / %d" % [current + 1, LOCATION_IDS.size()], 14, Color(0.78, 0.84, 0.95))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	if current > 0:
		var previous := _front_button(buttons, "PREVIOUS", Callable(self, "_show_location_gallery").bind(current - 1), 45.0)
		previous.name = "LocationPrevious"
	if current < LOCATION_IDS.size() - 1:
		var next := _front_button(buttons, "NEXT LOCATION", Callable(self, "_show_location_gallery").bind(current + 1), 45.0)
		next.name = "LocationNext"
	var back := _front_button(content, "BACK TO TITLE", _show_menu, 43.0)
	back.name = "LocationBack"

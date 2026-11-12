extends "res://scripts/prototype_story_v17.gd"
## Prototype 018 — user-supplied transparent dialogue portraits plus
## facing battlefield sprites with HP/status panels on their own sides.
## Art is OPTIONAL. If the portrait ZIP is not installed, dialogue runs
## normally and no portrait texture is required.

const DIALOGUE_PORTRAITS_DATA := "res://data/portraits/love_beyond.json"
const OptionalArt = preload("res://scripts/core/optional_art_loader.gd")

var portrait_catalog: Dictionary = {}
var dialogue_portrait_layer: Control = null
var portrait_left: TextureRect = null
var portrait_right: TextureRect = null
var last_portrait_speaker := ""


func _build_ui() -> void:
	super._build_ui()
	# The root scene order is background, darkening shade, then legacy UI.
	# Put the transparent full-height portraits ABOVE the backgrounds but
	# BELOW the existing dialogue box and advance/skip controls.
	dialogue_portrait_layer = Control.new()
	dialogue_portrait_layer.name = "DialoguePortraitLayer"
	dialogue_portrait_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_portrait_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dialogue_portrait_layer)
	move_child(dialogue_portrait_layer, scene_image.get_index() + 2)
	portrait_left = _new_speaking_portrait("LeftSpeakingPortrait", 0.0, 0.39, false)
	portrait_right = _new_speaking_portrait("RightSpeakingPortrait", 0.61, 1.0, true)
	dialogue_portrait_layer.hide()


func _new_speaking_portrait(node_name: String, start_x: float, end_x: float, flip: bool) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = node_name
	visual.anchor_left = start_x
	visual.anchor_right = end_x
	visual.anchor_top = 0.15
	visual.anchor_bottom = 0.96
	visual.offset_left = 0
	visual.offset_right = 0
	visual.offset_top = 0
	visual.offset_bottom = 0
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.flip_h = flip
	dialogue_portrait_layer.add_child(visual)
	visual.hide()
	return visual


func _load_portrait_catalog() -> void:
	if portrait_catalog.is_empty():
		portrait_catalog = ContentStore.read_dictionary(DIALOGUE_PORTRAITS_DATA)


func _portrait_speaker_id(speaker_text: String) -> String:
	_load_portrait_catalog()
	var uppercase := speaker_text.strip_edges().to_upper()
	for id in portrait_catalog.get("characters", {}):
		var data: Dictionary = portrait_catalog.get("characters", {}).get(id, {})
		for alias in data.get("aliases", []):
			if uppercase == str(alias).to_upper():
				return str(id)
	return ""


func _portrait_default(character_id: String) -> String:
	_load_portrait_catalog()
	var data: Dictionary = portrait_catalog.get("characters", {}).get(character_id, {})
	return str(data.get("default", "neutral"))


func _portrait_resource(character_id: String, expression: String) -> String:
	_load_portrait_catalog()
	var definition: Dictionary = portrait_catalog.get("characters", {}).get(character_id, {})
	var images: Dictionary = definition.get("expressions", {})
	var default_name := str(definition.get("default", "neutral"))
	var relative: String = str(images.get(expression, images.get(default_name, "")))
	if relative == "" or relative.begins_with("/") or relative.contains(".."):
		return ""
	return str(portrait_catalog.get("asset_root", "")) + relative


func _portrait_state_at(index: int) -> Dictionary:
	# Rebuild each scene state deterministically. This supports skipping,
	# chapter boundaries and continuing at mid-scene save checkpoints.
	_load_portrait_catalog()
	var left_id := "asmodeus"
	var right_id := "haniel"
	var expressions: Dictionary = {}
	for id in portrait_catalog.get("characters", {}):
		expressions[id] = _portrait_default(str(id))
	var active := ""
	if index < 0 or index >= story_events.size():
		return {"left":left_id, "right":right_id, "expressions":expressions, "active":active}
	for i in range(index + 1):
		var event: Dictionary = story_events[i]
		var kind := str(event.get("kind", ""))
		if kind == "title":
			left_id = "asmodeus"
			right_id = "haniel"
			for id in expressions:
				expressions[id] = _portrait_default(str(id))
		# Optional future scene overrides are supported without new code.
		if event.has("portrait_left"):
			left_id = str(event["portrait_left"])
		if event.has("portrait_right"):
			right_id = str(event["portrait_right"])
		var who := _portrait_speaker_id(str(event.get("speaker", "")))
		if who != "":
			var definition: Dictionary = portrait_catalog.get("characters", {}).get(who, {})
			if str(definition.get("default_side", "left")) == "right":
				right_id = who
			else:
				left_id = who
			var named := str(event.get("portrait_expression", ""))
			if named != "":
				expressions[who] = named
		if i == index:
			active = who if kind == "line" else ""
	return {"left":left_id, "right":right_id, "expressions":expressions, "active":active}


func _set_speaking_visual(rect: TextureRect, id: String, expression: String, speaking: bool) -> void:
	if not is_instance_valid(rect):
		return
	var path := _portrait_resource(id, expression)
	var tex: Texture2D = OptionalArt.texture(path)
	if tex == null:
		rect.texture = null
		rect.hide()
		return
	rect.texture = tex
	rect.show()
	# Active speaker lights up; their companion remains present but muted.
	rect.modulate = Color(1.0, 1.0, 1.0, 0.95) if speaking else Color(0.60, 0.68, 0.81, 0.60)


func _present_speakers(left_id: String, right_id: String, expressions: Dictionary, active_id: String) -> void:
	if not is_instance_valid(dialogue_portrait_layer):
		return
	_set_speaking_visual(portrait_left, left_id, str(expressions.get(left_id, _portrait_default(left_id))), active_id == left_id)
	_set_speaking_visual(portrait_right, right_id, str(expressions.get(right_id, _portrait_default(right_id))), active_id == right_id)
	last_portrait_speaker = active_id
	dialogue_portrait_layer.visible = portrait_left.visible or portrait_right.visible


func _hide_speaking_portraits() -> void:
	if is_instance_valid(dialogue_portrait_layer):
		dialogue_portrait_layer.hide()


func _show_dialogue() -> void:
	super._show_dialogue()
	# The opening tutorial exists outside the six-part story-event stream.
	var actor := _portrait_speaker_id(str(speaker.text))
	var expressions := {"asmodeus":"neutral", "haniel":"neutral"}
	if actor == "asmodeus" and line_index > 0:
		expressions["asmodeus"] = "smile"
	_present_speakers("asmodeus", "haniel", expressions, actor)


func _show_event() -> void:
	super._show_event()
	if not story_mode or bear_mode or bear_busy or hunt_mode or alley_mode or interlude_mode or battle_demo:
		_hide_speaking_portraits()
		return
	if event_index < 0 or event_index >= story_events.size():
		_hide_speaking_portraits()
		return
	var current: Dictionary = story_events[event_index]
	if str(current.get("kind", "")) != "line":
		_hide_speaking_portraits()
		return
	var state: Dictionary = _portrait_state_at(event_index)
	_present_speakers(
		str(state.get("left", "")), str(state.get("right", "")),
		state.get("expressions", {}), str(state.get("active", "")))


func _show_menu() -> void:
	_hide_speaking_portraits()
	super._show_menu()


func _prepare_campaign_screen() -> void:
	_hide_speaking_portraits()
	super._prepare_campaign_screen()


func _draw_interlude() -> void:
	_hide_speaking_portraits()
	super._draw_interlude()


func _party_panel(title_text: String, subtitle: String) -> VBoxContainer:
	_hide_speaking_portraits()
	return super._party_panel(title_text, subtitle)


func _draw_battle() -> void:
	_hide_speaking_portraits()
	super._draw_battle()


func _battle_panel(title_text: String) -> VBoxContainer:
	_hide_speaking_portraits()
	return super._battle_panel(title_text)


func _field_battler_sprite(parent: Control, id: String, index: int, enemy_side: bool, x: float, y: float) -> void:
	_read_pixel_data()
	var image_path := str(pixel_data.get("sprites", {}).get(id, ""))
	var path := AREA_ART_ROOT + image_path
	var frame := PanelContainer.new()
	frame.name = ("EnemyBattler_" if enemy_side else "AllyBattler_") + str(index)
	frame.position = Vector2(x, y)
	frame.custom_minimum_size = Vector2(118, 111)
	frame.size = Vector2(118, 111)
	var is_current := not enemy_side and str(party_battle.current_actor().get("id", "")) == id
	var border := HUD_RED if enemy_side else (HUD_GOLD if is_current else HUD_AQUA)
	frame.add_theme_stylebox_override("panel", _new_hud_box(0.12, border, 12))
	parent.add_child(frame)
	var image := TextureRect.new()
	image.name = "BattlerSprite_" + id
	image.custom_minimum_size = Vector2(108, 105)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Enemies face right, allied sprites face left toward one another.
	image.flip_h = not enemy_side
	if image_path != "" and ResourceLoader.exists(path):
		image.texture = load(path)
	frame.add_child(image)
	if image.texture == null:
		var fallback := Label.new()
		fallback.text = id.replace("_", " ").capitalize()
		fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		frame.add_child(fallback)
	var unit: Dictionary = {}
	var pool: Array = party_battle.enemies if enemy_side else party_battle.allies
	if index < pool.size():
		unit = pool[index]
	if int(unit.get("hp", 1)) <= 0:
		frame.modulate = Color(0.40, 0.40, 0.50, 0.55)


func _field_hp_card(parent: Node, member: Dictionary, index: int, enemy_side: bool) -> void:
	var card := PanelContainer.new()
	card.name = ("EnemyMini_" if enemy_side else "AllyMini_") + str(index)
	card.add_theme_stylebox_override("panel", _new_hud_box(
		0.86, Color(0.69, 0.36, 0.43, 0.76) if enemy_side else Color(0.38, 0.73, 0.78, 0.76), 9))
	card.custom_minimum_size = Vector2(201, 61)
	parent.add_child(card)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	card.add_child(info)
	var name_label := _front_label(info, str(member.get("name", "Enemy")), 12,
		HUD_RED if enemy_side else UI_ICE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compact_hp(info, int(member.get("hp", 0)), int(member.get("max_hp", 1)), enemy_side, 173)
	var status := "%d / %d HP" % [
		int(member.get("hp", 0)), int(member.get("max_hp", 1))]
	if not enemy_side and str(party_battle.current_actor().get("id", "")) == str(member.get("id", "")):
		status += "  ◈ TURN"
	if int(member.get("hp", 0)) <= 0:
		status += "  KO"
	_front_label(info, status, 11, UI_TEXT)


func _battle_roster_row(content: VBoxContainer) -> void:
	# A genuine opposing battlefield instead of tiny sprites embedded
	# inside info cards. Enemies LEFT / allies RIGHT, with side HUDs.
	var stage := Control.new()
	stage.name = "BattlefieldStage"
	stage.custom_minimum_size = Vector2(1040, 240)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(stage)
	var viewport_width := get_viewport_rect().size.x
	var stage_width: float = minf(1150.0, maxf(1040.0, viewport_width - 90.0))

	var left_info := VBoxContainer.new()
	left_info.name = "EnemyWing"
	left_info.position = Vector2(0, 4)
	left_info.size = Vector2(206, 224)
	left_info.add_theme_constant_override("separation", 6)
	stage.add_child(left_info)
	_front_label(left_info, "ENEMIES", 13, HUD_RED)
	for i in range(party_battle.enemies.size()):
		_field_hp_card(left_info, party_battle.enemies[i], i, true)

	var right_info := VBoxContainer.new()
	right_info.name = "AllyWing"
	right_info.position = Vector2(stage_width - 210, 4)
	right_info.size = Vector2(205, 224)
	right_info.add_theme_constant_override("separation", 5)
	stage.add_child(right_info)
	_front_label(right_info, "YOUR PARTY", 13, HUD_AQUA)
	for i in range(party_battle.allies.size()):
		_field_hp_card(right_info, party_battle.allies[i], i, false)

	var battlers := Control.new()
	battlers.name = "FacingBattlers"
	battlers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlers.size = Vector2(stage_width, 240)
	stage.add_child(battlers)
	for i in range(party_battle.enemies.size()):
		var foe: Dictionary = party_battle.enemies[i]
		var enemy_y := 18.0 + float(i) * 62.0
		_field_battler_sprite(battlers, str(foe.get("id", "")), i, true,
			stage_width * 0.245 + float(i % 2) * 18.0, enemy_y)
	for i in range(party_battle.allies.size()):
		var ally: Dictionary = party_battle.allies[i]
		var ally_y := 8.0 + float(i) * 61.0
		_field_battler_sprite(battlers, str(ally.get("id", "")), i, false,
			stage_width * 0.635 + float(i % 2) * 20.0, ally_y)


func _field_target_markers(enemy_side: bool, indices: Array) -> void:
	var battlers: Control = frontend_body.find_child("FacingBattlers", true, false) as Control
	if battlers == null:
		return
	for i in indices:
		var frame_name := ("EnemyBattler_" if enemy_side else "AllyBattler_") + str(i)
		var frame: PanelContainer = battlers.find_child(frame_name, false, false) as PanelContainer
		if frame == null:
			continue
		var marker := Label.new()
		marker.name = "FieldTarget_" + str(i)
		marker.text = "◆"
		marker.position = Vector2(51, -9)
		marker.add_theme_font_size_override("font_size", 25)
		marker.add_theme_color_override("font_color", HUD_GOLD)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(marker)


func _party_battle_pick_target(move_id: String) -> void:
	super._party_battle_pick_target(move_id)
	if party_battle == null or party_battle.finished:
		return
	var heal := false
	for raw in party_battle.current_moves():
		var move: Dictionary = raw
		if str(move.get("id", "")) == move_id:
			heal = str(move.get("kind", "")) == "heal"
			break
	_field_target_markers(not heal, party_battle.targets(move_id))


func _party_battle_food_targets(slot_index: int) -> void:
	super._party_battle_food_targets(slot_index)
	if party_battle != null and not party_battle.finished:
		_field_target_markers(false, party_battle.food_targets(slot_index))

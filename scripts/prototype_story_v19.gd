extends "res://scripts/prototype_story_v18.gd"
## Prototype 019 — Love Beyond Parts 7–9, new supplied images, and
## post-nine homestead daily life. Existing six parts and Cliffside routines
## stay available; no Michael boss fight or invented canonical combat.

const PARTS_7_TO_9_PATH := "res://data/chapters/love_beyond_parts_7_9.json"
const HOME_SCENE_IMAGE := "part_09/06_cave_homestead.webp"
const HOME_SPRITES_ROOT := "res://assets/love_beyond/story_sprites/"

var chapters_7_9_loaded := false


func _load_story_if_needed() -> void:
	super._load_story_if_needed()
	if chapters_7_9_loaded:
		return
	var chapter: Dictionary = ContentStore.read_dictionary(PARTS_7_TO_9_PATH)
	var additional: Array = chapter.get("events", [])
	if additional.is_empty():
		return
	story_events.append_array(additional)
	chapters_7_9_loaded = true


func _show_love_campaign() -> void:
	super._show_love_campaign()
	var part := _completed_story_part()
	if part < 6 or part >= 9:
		return
	var menu: VBoxContainer = frontend_body.find_child("CampaignMenuContent", true, false) as VBoxContainer
	if menu == null:
		return
	var part_names := ["PART SEVEN: MICHAEL", "PART EIGHT: EXPLANATION", "PART NINE: UNDERSTANDING"]
	var destination: String = str(part_names[clampi(part - 6, 0, 2)])
	var next := _front_button(menu, "CONTINUE STORY  •  " + destination,
		_continue_next_chapter, 50.0)
	next.name = "LoveContinuePartSeven"
	for node in menu.get_children():
		if node is Button and node.text == "BACK TO CAMPAIGN SELECT":
			menu.move_child(next, node.get_index())
			break


func _continue_next_chapter() -> void:
	var completed := _completed_story_part()
	if completed < 6 or completed >= 9:
		return
	var destinations := ["PART SEVEN", "PART EIGHT", "PART NINE"]
	var next_part: String = str(destinations[completed - 6])
	_start_story_at_title(next_part)


func _start_story_at_title(next_part: String) -> void:
	_load_story_if_needed()
	var desired_index := -1
	for i in range(story_events.size()):
		var event: Dictionary = story_events[i]
		if str(event.get("kind", "")) == "title" and str(event.get("part", "")) == next_part:
			desired_index = i
			break
	if desired_index < 0:
		return
	story_mode = true
	interlude_mode = false
	bear_mode = false
	hunt_mode = false
	alley_mode = false
	battle_demo = false
	event_index = desired_index
	if is_instance_valid(frontend):
		frontend.hide()
	_show_event()


func _start_part_seven() -> void:
	if _completed_story_part() < 6:
		return
	_start_story_at_title("PART SEVEN")


func _show_love_adventure() -> void:
	super._show_love_adventure()
	if _completed_story_part() < 9:
		return
	var menu: VBoxContainer = frontend_body.find_child("CampaignMenuContent", true, false) as VBoxContainer
	if menu == null:
		return
	var home := _front_button(menu, "CAVE HOMESTEAD  •  GARDEN & WOODWORK",
		_open_homestead_selector, 49.0)
	home.name = "LoveHomestead"
	for node in menu.get_children():
		if node is Button and node.text == "BACK TO LOVE BEYOND":
			menu.move_child(home, node.get_index())
			break


func _is_homestead_day() -> bool:
	return interlude_mode and current_interlude_id.begins_with("homestead_") and _completed_story_part() >= 9


func _open_homestead_selector() -> void:
	if _completed_story_part() < 9:
		return
	var content := _party_panel("THE CAVE HOMESTEAD",
		"After Part Nine  •  Optional daily activities  •  No story advancement")
	_display_curated_image(HOME_SCENE_IMAGE)
	_front_label(content,
		"Joren and Toren are teaching Asmodeus to grow food, while Alric guides Haniel through carpentry. Both can keep learning without rushing the next chapter.",
		16, UI_TEXT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var asmo := _front_button(content, "ASMODEUS  •  GARDENING & HUNTING",
		Callable(self, "_enter_homestead").bind("asmodeus"), 51.0)
	asmo.name = "HomesteadChooseAsmodeus"
	var haniel := _front_button(content, "HANIEL  •  WOODWORKING & REFLECTION",
		Callable(self, "_enter_homestead").bind("haniel"), 51.0)
	haniel.name = "HomesteadChooseHaniel"
	_front_button(content, "BACK TO ADVENTURE", _show_love_adventure, 44.0)


func _enter_homestead(character_id: String) -> void:
	if _completed_story_part() < 9 or not ["asmodeus", "haniel"].has(character_id):
		return
	_load_story_if_needed()
	live_outlaw_active = false
	live_outlaw_resolved = false
	last_activity_text = ""
	_enter_interlude("homestead_" + character_id)


func _save_interlude() -> void:
	if not _is_homestead_day():
		super._save_interlude()
		return
	# Homestead free time is a post-chapter sandbox like Cliffside.
	# It must never overwrite the current manuscript cursor or create a
	# stale checkpoint that could replay the Part Nine ending.
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var love: Dictionary = campaigns.get("love_beyond", {})
	var states: Dictionary = love.get("interludes", {})
	states[current_interlude_id] = interlude_engine.snapshot()
	love["interludes"] = states
	var progress: Dictionary = love.get("progression", {})
	var pov := str(current_profile.get("pov", "asmodeus"))
	var prior: Dictionary = progress.get(pov, {})
	prior.merge(interlude_engine.progression(), true)
	progress[pov] = prior
	love["progression"] = progress
	campaigns["love_beyond"] = love
	save_data["campaigns"] = campaigns
	_inventory_persist()


func _homestead_companion(parent: VBoxContainer, character_id: String, label_text: String) -> void:
	var unit := HBoxContainer.new()
	unit.add_theme_constant_override("separation", 11)
	parent.add_child(unit)
	var picture := TextureRect.new()
	picture.custom_minimum_size = Vector2(58, 84)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := HOME_SPRITES_ROOT + ("joren_wounded.webp" if character_id == "joren" else "toren.webp")
	picture.texture = OptionalArt.texture(path)
	unit.add_child(picture)
	var caption := _front_label(unit, label_text, 14, UI_ICE)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _draw_interlude() -> void:
	super._draw_interlude()
	if not _is_homestead_day():
		return
	_display_curated_image(HOME_SCENE_IMAGE)
	var scroll: ScrollContainer = frontend_body.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	if content == null:
		return
	_front_label(content,
		"Garden sessions: %d   •   Woodworking lessons: %d" % [
			int(interlude_engine.state.get("gardening_sessions", 0)),
			int(interlude_engine.state.get("woodwork_sessions", 0))],
		16, HUD_GOLD)
	_front_label(content, "VISITING HELPERS", 15, HUD_AQUA)
	_homestead_companion(content, "joren", "Joren — learning to make amends, one lesson at a time")
	_homestead_companion(content, "toren", "Toren — an enthusiastic young farming helper")
	var hunt: Button = scroll.find_child("Daily_Hunt", true, false) as Button
	if hunt != null and str(current_profile.get("pov", "")) == "haniel":
		hunt.disabled = true
		hunt.text = "HUNT  •  Not part of Haniel's woodworking day"
		hunt.tooltip_text = "Try Asmodeus's routine to hunt."
	var switch_pov := "haniel" if str(current_profile.get("pov", "")) == "asmodeus" else "asmodeus"
	var switch := _front_button(content, "PLAY %s'S HOMESTEAD DAY" % switch_pov.to_upper(),
		Callable(self, "_enter_homestead").bind(switch_pov), 44.0)
	switch.name = "HomesteadSwitchPOV"


func _take_interlude_action(id: String) -> void:
	if _is_homestead_day() and ["garden", "woodwork", "reflect"].has(id):
		if interlude_engine == null or not interlude_engine.can_spend_action():
			return
		var pov := str(current_profile.get("pov", ""))
		if id == "garden" and pov != "asmodeus":
			return
		if id in ["woodwork", "reflect"] and pov != "haniel":
			return
		interlude_engine.spend(id)
		match id:
			"garden":
				interlude_engine.state["gardening_sessions"] = int(interlude_engine.state.get("gardening_sessions", 0)) + 1
				last_activity_text = "With Joren and Toren's guidance, Asmodeus practices planting and tending a small patch of earth."
			"woodwork":
				interlude_engine.state["woodwork_sessions"] = int(interlude_engine.state.get("woodwork_sessions", 0)) + 1
				last_activity_text = "Haniel studies Alric's tools and practices careful cuts and joints. Patience makes the work steadier."
			"reflect":
				interlude_engine.state["reflections"] = int(interlude_engine.state.get("reflections", 0)) + 1
				last_activity_text = "Haniel thinks of her brothers, Alric's words, and the kind of family people choose to make."
		_save_interlude()
		_draw_interlude()
		return
	super._take_interlude_action(id)


func _bedtime_question() -> void:
	if not _is_homestead_day():
		super._bedtime_question()
		return
	var content := _party_panel("EVENING AT THE CAVE HOMESTEAD",
		"The next authored chapter will arrive later. Ordinary life continues.")
	_front_label(content,
		"An ordinary tomorrow refreshes your three activities. Gardening and woodworking progress is kept, and the story remains at Part Nine.",
		16, UI_TEXT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next := _front_button(content, "AN ORDINARY DAY  •  Stay at the homestead", _ordinary_tomorrow, 51.0)
	next.name = "HomesteadOrdinaryTomorrow"
	_front_button(content, "NOT YET  •  Back to activities", _draw_interlude, 45.0)


func _exciting_tomorrow() -> void:
	if _is_homestead_day():
		_bedtime_question()
		return
	super._exciting_tomorrow()


func _finish_story() -> void:
	# The previous Prototype 004 ending hard-coded Part Six. Replace it
	# only once the new full chapter sequence has reached its real end.
	if not chapters_7_9_loaded or _completed_story_part() < 9:
		super._finish_story()
		return
	if is_instance_valid(frontend):
		frontend.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	_hide_speaking_portraits()
	_display_curated_image(HOME_SCENE_IMAGE)
	_clear_buttons()
	heading.text = "PART NINE COMPLETE"
	subheading.text = "A LOVE STRONGER THAN HEAVEN OR HELL"
	speaker.text = "A QUIETER TOMORROW"
	message.text = "Alric has offered his understanding. Joren and Toren are helping build a home. Gardening and woodworking are now available during ordinary days."
	_button("Visit the homestead", _open_homestead_selector)
	_button("Return to campaign", _show_love_campaign)

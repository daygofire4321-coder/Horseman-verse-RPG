extends "res://scripts/prototype_story.gd"
## Prototype 004 — Parts 1–6, optional free-time days, hunting and the Cliffside alley.
## Original scripts/scenes are preserved for rollback.

const InterludeEngine = preload("res://scripts/core/interlude_engine.gd")
const AlleyWaveEngine = preload("res://scripts/core/alley_wave_engine.gd")
const NEXT_PARTS_PATH := "res://data/chapters/love_beyond_parts_4_6.json"
const INTERLUDE_DATA_PATH := "res://data/interludes/love_beyond.json"
const LATER_ART_ROOT := "res://assets/love_beyond/story_002/"

var extended_loaded := false
var interlude_mode := false
var hunt_mode := false
var alley_mode := false
var alley_ready := false
var current_interlude_id := ""
var current_profile: Dictionary = {}
var interlude_engine = null
var wave_engine = null
var hunt_enemy_name := ""
var last_activity_text := ""
var interlude_profiles: Dictionary = {}


func _load_story_if_needed() -> void:
	if extended_loaded:
		return
	super._load_story_if_needed()
	var next_data: Dictionary = ContentStore.read_dictionary(NEXT_PARTS_PATH)
	var next_events: Array = next_data.get("events", [])
	if next_events.is_empty():
		return
	story_events.append_array(next_events)
	interlude_profiles = ContentStore.read_dictionary(INTERLUDE_DATA_PATH)
	extended_loaded = true


func _show_menu() -> void:
	interlude_mode = false
	hunt_mode = false
	alley_mode = false
	super._show_menu()
	if not is_instance_valid(frontend_body):
		return
	var boxes: Array = frontend_body.get_children()
	if boxes.is_empty():
		return
	var panel: Node = boxes[0]
	if panel.get_child_count() == 0:
		return
	var content: Node = panel.get_child(0)
	_front_label(content, "Prototype 004  •  Six story parts + ordinary-day interludes", 15, Color(0.64, 0.83, 0.98))
	if _has_resumable_interlude():
		_front_button(content, "CONTINUE SAVED ADVENTURE", _resume_adventure, 47.0)


func _show_about() -> void:
	_ensure_layers()
	_clear_frontend()
	frontend.show()
	var content := _front_panel()
	_front_label(content, "PROTOTYPE 004", 31)
	_front_label(content, "Love Beyond — The First Six Parts", 20)
	_front_label(content, "Daily interludes, optional repeatable hunting,\nXP/levels, and a two-wave Cliffside alley battle.", 16)
	_front_label(content, "Sleeping never forces story progression.\nChoose an ordinary day or an exciting day every evening.", 16)
	_front_button(content, "BACK TO TITLE", _show_menu)


func _start_dialogue() -> void:
	interlude_mode = false
	hunt_mode = false
	alley_mode = false
	super._start_dialogue()


func _set_story_background(file_name: String) -> void:
	var later: String = LATER_ART_ROOT + file_name
	if ResourceLoader.exists(later):
		scene_image.texture = load(later)
	elif file_name.begins_with("cliffside"):
		# Until the optimized Cliffside art is installed, avoid a stormy sky fallback.
		super._set_story_background("forest_hunt.jpg")
	else:
		super._set_story_background(file_name)


func _show_event() -> void:
	_load_story_if_needed()
	if event_index >= story_events.size():
		_finish_story()
		return
	var event: Dictionary = story_events[event_index]
	match str(event.get("kind", "line")):
		"checkpoint":
			_record_part(int(event.get("part", 3)))
			event_index += 1
			_show_event()
		"interlude":
			_enter_interlude(str(event.get("id", "")))
		"alley_wave":
			_start_alley_wave(int(event.get("wave", 1)), str(event.get("image", "")))
		_:
			super._show_event()


func _record_part(part: int) -> void:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	lb["opening_parts_completed"] = maxi(part, int(lb.get("opening_parts_completed", 0)))
	lb["last_story_event"] = "end_part_%d" % part
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns
	SaveStore.write_save(save_data)


func _profile(id: String) -> Dictionary:
	for candidate in interlude_profiles.get("stages", []):
		var item: Dictionary = candidate
		if str(item.get("id", "")) == id:
			return item
	return {}


func _has_resumable_interlude() -> bool:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var checkpoint: Dictionary = lb.get("interlude_checkpoint", {})
	return not checkpoint.is_empty() and str(checkpoint.get("id", "")) != ""


func _resume_adventure() -> void:
	_load_story_if_needed()
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var checkpoint: Dictionary = lb.get("interlude_checkpoint", {})
	if checkpoint.is_empty():
		_start_dialogue()
		return
	story_mode = true
	event_index = clampi(int(checkpoint.get("event_index", 0)), 0, story_events.size() - 1)
	frontend.hide()
	_show_event()


func _enter_interlude(id: String) -> void:
	current_profile = _profile(id)
	if current_profile.is_empty():
		_clear_buttons()
		speaker.text = "INTERLUDE CONTENT MISSING"
		message.text = "The daily-life configuration could not be read."
		_button("Continue story", _advance_event)
		return
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var states: Dictionary = lb.get("interludes", {})
	var progress: Dictionary = lb.get("progression", {})
	current_interlude_id = id
	interlude_engine = InterludeEngine.new()
	interlude_engine.begin(current_profile, states.get(id, {}), progress.get(str(current_profile.get("pov", "asmodeus")), {}))
	interlude_mode = true
	hunt_mode = false
	alley_mode = false
	_save_interlude()
	_draw_interlude()


func _save_interlude() -> void:
	if interlude_engine == null:
		return
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var states: Dictionary = lb.get("interludes", {})
	states[current_interlude_id] = interlude_engine.snapshot()
	lb["interludes"] = states
	var progress: Dictionary = lb.get("progression", {})
	progress[str(current_profile.get("pov", "asmodeus"))] = interlude_engine.progression()
	lb["progression"] = progress
	if bool(interlude_engine.state.get("complete", false)):
		lb.erase("interlude_checkpoint")
	else:
		lb["interlude_checkpoint"] = {"id":current_interlude_id, "event_index":event_index}
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns
	SaveStore.write_save(save_data)


func _draw_interlude() -> void:
	_ensure_layers()
	_clear_frontend()
	frontend.show()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	portraits.hide()
	_set_story_background(str(current_profile.get("scene", "campfire.jpg")))
	var content: VBoxContainer = _front_panel()
	var progress: Dictionary = interlude_engine.state
	_front_label(content, "A DAY IN THE LIFE OF " + str(current_profile.get("pov", "asmodeus")).to_upper(), 25)
	_front_label(content, str(current_profile.get("name", "Interlude")) + "  •  " + str(current_profile.get("location", "Forest Camp")), 18)
	_front_label(content, "DAY %d  |  %d / 3 LIMITED ACTIVITIES  |  HP %d/%d  |  LV %d  |  EXP %d  |  SUPPLIES %d" % [
		int(progress.get("day", 1)), int(progress.get("actions_left", 3)), int(progress.get("hp", 65)),
		int(progress.get("max_hp", 100)), int(progress.get("level", 1)),
		int(progress.get("xp", 0)), int(progress.get("supplies", 0))], 15, Color(0.83, 0.88, 0.95))
	if last_activity_text != "":
		var desc := _front_label(content, last_activity_text, 15, Color(0.88, 0.84, 0.74))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "HUNT  •  Repeatable  •  No daily action cost", _start_hunt, 46.0).disabled = not interlude_engine.may_hunt()
	for action in current_profile.get("actions", []):
		var name: String = str(action.get("label", "Activity"))
		var details: String = str(action.get("description", ""))
		var id: String = str(action.get("id", ""))
		_front_button(content, name + "  •  " + details, Callable(self, "_take_interlude_action").bind(id), 46.0).disabled = not interlude_engine.can_spend_action()
	_front_button(content, "GO TO BED / END THE DAY", _bedtime_question, 48.0)
	_front_button(content, "SAVE AND RETURN TO TITLE", _show_menu, 41.0)


func _take_interlude_action(id: String) -> void:
	last_activity_text = interlude_engine.spend(id)
	_save_interlude()
	_draw_interlude()


func _bedtime_question() -> void:
	_clear_frontend()
	var content := _front_panel()
	_front_label(content, "EVENING SETTLES OVER THE CAMP", 27)
	_front_label(content, "Will tomorrow be an ordinary day, or an exciting one?", 21)
	_front_label(content, "An ordinary day gives you fresh daily actions and keeps the story right here.", 16, Color(0.78, 0.85, 0.94))
	_front_button(content, "AN ORDINARY DAY  •  Rest and keep living here", _ordinary_tomorrow, 62.0)
	_front_button(content, "AN EXCITING DAY  •  Continue the story", _exciting_tomorrow, 62.0)
	_front_button(content, "NOT YET  •  Return to today's activities", _draw_interlude, 47.0)


func _ordinary_tomorrow() -> void:
	interlude_engine.ordinary_day()
	last_activity_text = "Another ordinary morning dawns. There is no rush to follow the next story event."
	_save_interlude()
	_draw_interlude()


func _exciting_tomorrow() -> void:
	interlude_engine.exciting_day()
	last_activity_text = ""
	_save_interlude()
	interlude_mode = false
	frontend.hide()
	event_index += 1
	_show_event()


func _start_hunt() -> void:
	if interlude_engine == null or not interlude_engine.may_hunt():
		last_activity_text = "You need to rest before hunting again."
		_draw_interlude()
		return
	var pool: Array = interlude_engine.hunt_pool()
	if pool.is_empty():
		last_activity_text = "There are no available hunting encounters."
		_draw_interlude()
		return
	var target_id: String = str(pool[randi_range(0, pool.size() - 1)])
	var animal: Dictionary = ContentStore.load_character(target_id)
	var hero: Dictionary = ContentStore.load_character(str(current_profile.get("pov", "asmodeus")))
	if hero.is_empty() or animal.is_empty():
		last_activity_text = "Could not load the hunting opponent."
		_draw_interlude()
		return
	var state: Dictionary = interlude_engine.state
	hero["max_hp"] = int(state.get("max_hp", 100))
	var moves: Array = hero.get("moves", [])
	for index in range(moves.size()):
		var move: Dictionary = moves[index]
		if str(move.get("kind", "")) == "damage":
			move["power"] = int(move.get("power", 0)) + 3 * (int(state.get("level", 1)) - 1)
			moves[index] = move
	hero["moves"] = moves
	hunt_enemy_name = str(animal.get("name", "Wildlife"))
	duel = DuelEngine.new()
	duel.setup(hero, animal, selected_profile)
	duel.player_hp = mini(duel.player_max_hp, int(state.get("hp", 65)))
	hunt_mode = true
	frontend.hide()
	_set_story_background("forest_hunt.jpg")
	_ensure_boss_hud()
	_draw_hunt()


func _draw_battle() -> void:
	if hunt_mode:
		_draw_hunt()
	else:
		super._draw_battle()


func _update_boss_hud() -> void:
	if hunt_mode and duel != null and is_instance_valid(boss_hud):
		bear_bar.max_value = duel.enemy_max_hp
		bear_bar.value = duel.enemy_hp
		hero_bar.max_value = duel.player_max_hp
		hero_bar.value = duel.player_hp
		bear_hp_label.text = "%s  %d / %d HP" % [hunt_enemy_name.to_upper(), duel.enemy_hp, duel.enemy_max_hp]
		hero_hp_label.text = "ASMODEUS  %d / %d HP" % [duel.player_hp, duel.player_max_hp]
	else:
		super._update_boss_hud()


func _draw_hunt() -> void:
	_clear_buttons()
	_set_hp_visible(false)
	portraits.hide()
	boss_hud.show()
	_update_boss_hud()
	heading.text = "HUNTING GROUNDS"
	subheading.text = "REPEATABLE ENCOUNTER  •  %s" % str(selected_profile.get("name", "Normal")).to_upper()
	speaker.text = "ASMODEUS VS " + hunt_enemy_name.to_upper()
	message.text = "Hunting builds EXP without spending a daily activity. HP carries over between hunts."
	for move in duel.player_moves():
		_button(str(move.get("name", "Attack")), Callable(self, "_hunt_turn").bind(str(move.get("id", ""))))


func _hunt_turn(id: String) -> void:
	if not hunt_mode:
		return
	var outcome: Dictionary = duel.take_turn(id)
	interlude_engine.state["hp"] = maxi(0, int(outcome.get("player_hp", 1)))
	if bool(outcome.get("finished", false)):
		hunt_mode = false
		boss_hud.hide()
		if bool(outcome.get("victory", false)):
			var award: int = int(duel.enemy.get("exp_reward", 10))
			last_activity_text = "Defeated %s. %s" % [hunt_enemy_name, interlude_engine.earn_hunt_exp(award)]
		else:
			interlude_engine.state["hp"] = 1
			last_activity_text = "%s overwhelmed Asmodeus. No EXP gained. He retreats to camp at 1 HP." % hunt_enemy_name
		_save_interlude()
		_draw_interlude()
	else:
		message.text = str(outcome.get("message", ""))
		_draw_hunt()


func _start_alley_wave(number: int, background_name: String) -> void:
	alley_mode = true
	alley_ready = false
	hunt_mode = false
	wave_engine = AlleyWaveEngine.new()
	wave_engine.setup(number, selected_profile)
	if is_instance_valid(frontend):
		frontend.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	_set_story_background(background_name)
	_draw_alley()


func _draw_alley() -> void:
	_clear_buttons()
	_set_hp_visible(false)
	portraits.hide()
	var wave_number: int = int(wave_engine.wave)
	heading.text = "PART SIX  /  CLIFFSIDE ALLEY"
	subheading.text = "WAVE %d OF 2  •  STORY ENCOUNTER" % wave_number
	speaker.text = "HANIEL + ALRIC" if wave_number == 1 else "ASMODEUS + ALRIC"
	message.text = "%s: %d HP  |  ALRIC: %d HP\n%s\n\nAlric assists automatically each turn. Everyone survives the authored story." % [
		"Haniel" if wave_number == 1 else "Asmodeus",
		int(wave_engine.player_hp), int(wave_engine.alric_hp), wave_engine.enemy_summary()]
	for move in wave_engine.player_moves():
		_button(str(move.get("name", "Attack")), Callable(self, "_alley_turn").bind(str(move.get("id", ""))))


func _alley_turn(move_id: String) -> void:
	if not alley_mode or alley_ready:
		return
	var outcome: Dictionary = wave_engine.take_turn(move_id)
	if bool(outcome.get("finished", false)):
		alley_ready = true
		_clear_buttons()
		heading.text = "WAVE %d COMPLETE" % int(wave_engine.wave)
		speaker.text = "THE FIGHT CONTINUES"
		message.text = str(outcome.get("message", "")) + "\n\nThe canonical events continue, regardless of the battle result."
		_button("Continue the scene", _finish_alley_wave)
	else:
		_draw_alley()
		# Show up-to-date battle state, keeping the log legible.
		message.text += "\n\n" + str(outcome.get("message", ""))


func _finish_alley_wave() -> void:
	alley_mode = false
	alley_ready = false
	_advance_event()


func _finish_story() -> void:
	_record_part(6)
	if is_instance_valid(frontend):
		frontend.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	_set_story_background("cliffside_alley.jpg")
	_clear_buttons()
	heading.text = "PART SIX COMPLETE"
	subheading.text = "A LOVE STRONGER THAN HEAVEN OR HELL"
	speaker.text = "TO BE CONTINUED"
	message.text = "Haniel has met Alric and Joren in Cliffside. The next part will begin when its story is ready."
	_button("Return to title", _show_menu)
	_button("Replay the opening", _start_dialogue)

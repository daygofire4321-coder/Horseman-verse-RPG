extends SceneTree
## Run locally:
## godot --headless --path . --script res://tests/smoke_test.gd
## WARNING: This uses in-memory save data; it never overwrites the player's save.

const ContentStore = preload("res://scripts/core/content_store.gd")
const DuelEngine = preload("res://scripts/core/duel_engine.gd")
const SaveStore = preload("res://scripts/core/save_store.gd")


var failures: Array[String] = []


func _initialize() -> void:
	# Defer until SceneTree.root has entered the tree before instantiating UI.
	call_deferred("_run_tests")


func _expect(condition: bool, message: String = "Smoke test expectation failed") -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run_tests() -> void:
	# Loading the PackedScene forces Godot to parse the experimental UI script.
	var modular_scene: Resource = load("res://scenes/prototype_modular.tscn")
	_expect(modular_scene is PackedScene, "Modular scene must load successfully")
	if modular_scene is PackedScene:
		var view: Node = (modular_scene as PackedScene).instantiate()
		root.add_child(view)
		_expect(view.is_inside_tree(), "Modular prototype should instantiate")
		view.queue_free()

	# Prototype 002 is an independent scene. Verify its menu, navigation,
	# both skill VFX paths and turn unlock after the animations finish.
	var v2_resource: Resource = load("res://scenes/prototype_v2.tscn")
	_expect(v2_resource is PackedScene, "Prototype 002 scene must load")
	if v2_resource is PackedScene:
		var v2: Node = (v2_resource as PackedScene).instantiate()
		root.add_child(v2)
		_expect(v2.is_inside_tree(), "Prototype 002 must instantiate")
		_expect(v2.get("frontend") != null, "Main menu must be created")
		v2.call("_start_dialogue")
		v2.call("_choose_fighter")
		v2.call("_show_difficulty_picker", "Haniel", "Asmodeus")
		v2.call("_start_battle", "Haniel", "Asmodeus")
		v2.call("_turn", "divine_arrow")
		await create_timer(1.15).timeout
		_expect(not bool(v2.get("busy_animating")), "Divine Arrow VFX should release input")
		v2.call("_start_battle", "Asmodeus", "Haniel")
		v2.call("_turn", "black_ice")
		await create_timer(1.15).timeout
		_expect(not bool(v2.get("busy_animating")), "Black Ice VFX should release input")
		v2.queue_free()

	# Story arc: prologue -> cave -> gathering -> bear -> authored rescue.
	var story_resource: Resource = load("res://scenes/prototype_story.tscn")
	_expect(story_resource is PackedScene, "Story opening scene should load")
	if story_resource is PackedScene:
		var story: Node = (story_resource as PackedScene).instantiate()
		root.add_child(story)
		_expect(story.is_inside_tree(), "Story scene must instantiate")
		story.call("_start_dialogue")
		story.call("_result", false)
		story.call("_begin_story_events")
		var events: Array = story.get("story_events")
		_expect(events.size() >= 65, "Story arc should contain all three parts")
		var found_gather := false
		var found_bear := false
		for step in range(120):
			var at: int = int(story.get("event_index"))
			if at >= events.size():
				break
			var event: Dictionary = events[at]
			var kind := str(event.get("kind", "line"))
			if kind == "gather":
				found_gather = true
				story.call("_collect_branch")
				story.call("_collect_branch")
				story.call("_collect_branch")
				_expect(int(story.get("gathering_count")) == 3, "Branch collection should finish")
				story.call("_advance_event")
			elif kind == "battle":
				found_bear = true
				for hit in range(5):
					if not bool(story.get("bear_mode")):
						break
					story.call("_bear_turn", "black_ice")
					await create_timer(0.82).timeout
				_expect(not bool(story.get("bear_mode")), "Bear battle should trigger rescue at 50% HP")
			else:
				story.call("_advance_event")
		_expect(found_gather, "Story should include the branch gathering interaction")
		_expect(found_bear, "Story should include the bear battle")
		_expect(int(story.get("event_index")) >= events.size(), "Story should reach the end")
		story.queue_free()

	# The alternate rescue branch must also work: Asmodeus collapses first.
	var loss_resource: Resource = load("res://scenes/prototype_story.tscn")
	if loss_resource is PackedScene:
		var losing_story: Node = (loss_resource as PackedScene).instantiate()
		root.add_child(losing_story)
		losing_story.call("_begin_story_events")
		var sequence: Array = losing_story.get("story_events")
		for step in range(100):
			var at: int = int(losing_story.get("event_index"))
			if at >= sequence.size():
				break
			var event: Dictionary = sequence[at]
			var kind := str(event.get("kind", "line"))
			if kind == "battle":
				var bear_duel: RefCounted = losing_story.get("duel")
				bear_duel.set("player_hp", 1)
				losing_story.call("_bear_turn", "attack")
				await create_timer(0.82).timeout
				_expect(not bool(losing_story.get("bear_mode")), "Asmodeus loss should also trigger rescue")
				_expect(int(losing_story.get("event_index")) == at + 1, "Loss should enter the immediate rescue event")
				break
			elif kind == "gather":
				for branch in range(3):
					losing_story.call("_collect_branch")
				losing_story.call("_advance_event")
			else:
				losing_story.call("_advance_event")
		losing_story.queue_free()


	# Prototype 004: player must be able to spend unlimited ordinary days
	# between script beats, and choose exactly when the next part starts.
	var v4_resource: Resource = load("res://scenes/prototype_story_v4.tscn")
	_expect(v4_resource is PackedScene, "Six-part scene must import")
	if v4_resource is PackedScene:
		var arc: Node = (v4_resource as PackedScene).instantiate()
		root.add_child(arc)
		arc.call("_load_story_if_needed")
		var chain: Array = arc.get("story_events")
		_expect(chain.size() > 145, "Six-part story should include all authored scenes")
		arc.call("_begin_story_events")
		var interludes_seen := 0
		var alley_waves_seen := 0
		for step in range(260):
			var index: int = int(arc.get("event_index"))
			if index >= chain.size():
				break
			var beat: Dictionary = chain[index]
			match str(beat.get("kind", "line")):
				"gather":
					for branch in range(3):
						arc.call("_collect_branch")
					arc.call("_advance_event")
				"battle":
					for turn in range(5):
						if not bool(arc.get("bear_mode")):
							break
						arc.call("_bear_turn", "black_ice")
						await create_timer(0.82).timeout
					_expect(not bool(arc.get("bear_mode")), "Bear rescue still works in six-part mode")
				"interlude":
					interludes_seen += 1
					var daily = arc.get("interlude_engine")
					_expect(daily != null, "Interlude engine created")
					if daily != null:
						var day_before: int = int(daily.state.get("day", 1))
						arc.call("_ordinary_tomorrow")
						arc.call("_ordinary_tomorrow")
						arc.call("_ordinary_tomorrow")
						_expect(int(daily.state["day"]) == day_before + 3, "Three ordinary days advance time")
						_expect(int(arc.get("event_index")) == index, "Ordinary days never advance authored scenes")
						arc.call("_take_interlude_action", "rest")
						arc.call("_take_interlude_action", "explore")
						arc.call("_take_interlude_action", "care" if interludes_seen == 1 else "camp")
						_expect(int(daily.state["actions_left"]) == 0, "All three daily actions can be spent")
						arc.call("_show_menu")
						arc.call("_resume_adventure")
						_expect(int(arc.get("event_index")) == index, "Saved adventure resumes the same interlude")
						var resumed = arc.get("interlude_engine")
						_expect(int(resumed.state["actions_left"]) == 0, "Daily actions survive saving and resuming")
						arc.call("_start_hunt")
						var hunt = arc.get("duel")
						_expect(int(arc.get("interlude_engine").state["actions_left"]) == 0, "Hunting works after all daily actions are spent")
						if bool(arc.get("hunt_mode")):
							hunt.enemy_hp = 1
							arc.call("_hunt_turn", "attack")
						_expect(not bool(arc.get("hunt_mode")), "Completed hunt returns to camp")
						_expect(int(arc.get("interlude_engine").state["level"]) > 1 or int(arc.get("interlude_engine").state["xp"]) > 0, "Successful hunt grants experience")
						arc.call("_exciting_tomorrow")
						_expect(int(arc.get("event_index")) > index, "Exciting day advances to next chapter")
				"alley_wave":
					alley_waves_seen += 1
					var wave = arc.get("wave_engine")
					_expect(int(wave.wave) == alley_waves_seen, "Alley waves appear in order")
					for strike in range(16):
						if bool(arc.get("alley_ready")):
							break
						arc.call("_alley_turn", "divine_arrow" if alley_waves_seen == 1 else "black_ice")
					_expect(bool(arc.get("alley_ready")), "Alley wave resolves into canonical outcome")
					arc.call("_finish_alley_wave")
				_:
					arc.call("_advance_event")
		_expect(interludes_seen == 2, "Two optional daily interludes should occur")
		_expect(alley_waves_seen == 2, "Two Cliffside combat waves should occur")
		_expect(int(arc.get("event_index")) >= chain.size(), "Story should finish Part Six")
		arc.queue_free()


	# Losing the alley fight should still enter the authored cutscene.
	const AllyWaves = preload("res://scripts/core/alley_wave_engine.gd")
	var scripted_loss = AllyWaves.new()
	scripted_loss.setup(2, {"enemy_hp_multiplier":1.0,"enemy_damage_multiplier":1.0})
	scripted_loss.player_hp = 1
	scripted_loss.alric_hp = 0
	var loss_result: Dictionary = scripted_loss.take_turn("attack")
	_expect(bool(loss_result.get("finished", false)), "Alley loss should finish rather than soft-lock")
	_expect(not bool(loss_result.get("won", true)), "Alley loss should report its outcome")


	# Prototype 005: optional pixel art, instant boar preview and area routing.
	# The CI runner does not install the downloadable binary image pack: fallbacks
	# must still instantiate, play and navigate without crashing.
	var v5_resource: Resource = load("res://scenes/prototype_story_v5.tscn")
	_expect(v5_resource is PackedScene, "Pixel battle scene must import")
	if v5_resource is PackedScene:
		var pixel_view: Node = (v5_resource as PackedScene).instantiate()
		root.add_child(pixel_view)
		_expect(pixel_view.is_inside_tree(), "Pixel battle scene should instantiate")
		pixel_view.call("_start_battle_preview")
		_expect(bool(pixel_view.get("battle_demo")), "Pixel preview should start")
		_expect(str(pixel_view.get("stage_area")) == "forest_clearing", "Boar preview uses forest clearing")
		var demo_duel: RefCounted = pixel_view.get("duel")
		var original_enemy_hp: int = int(demo_duel.get("enemy_hp"))
		pixel_view.call("_preview_turn", "black_ice")
		_expect(int(demo_duel.get("enemy_hp")) < original_enemy_hp, "Pixel preview turn should damage wild boar")
		pixel_view.call("_exit_preview")
		_expect(not bool(pixel_view.get("battle_demo")), "Pixel preview should cleanly exit")
		pixel_view.call("_start_battle", "Haniel", "Asmodeus")
		_expect(str(pixel_view.get("stage_area")) == "thundercloud", "Opening duel uses storm sky")
		pixel_view.set("save_data", SaveStore.new_save())
		pixel_view.call("_load_story_if_needed")
		pixel_view.call("_enter_interlude", "after_part_four")
		pixel_view.call("_start_hunt")
		_expect(str(pixel_view.get("stage_area")) == "forest_clearing", "Repeatable hunts use forest")
		pixel_view.call("_start_alley_wave", 1, "cliffside_alley.jpg")
		_expect(str(pixel_view.get("stage_area")) == "cliffside_alley", "Alley waves use Cliffside")
		pixel_view.call("_start_bear_battle", {"image":"bear_boss.jpg"})
		_expect(str(pixel_view.get("stage_area")) == "forest_clearing", "Bear encounter uses forest")
		pixel_view.queue_free()


	# Prototype 006: the new sprite roster renders and the multi-unit alley
	# formation works with graceful placeholders when the art ZIP is absent.
	var v6_resource: Resource = load("res://scenes/prototype_story_v6.tscn")
	_expect(v6_resource is PackedScene, "User sprite scene must import")
	if v6_resource is PackedScene:
		var cast_view: Node = (v6_resource as PackedScene).instantiate()
		root.add_child(cast_view)
		cast_view.call("_show_sprite_gallery", 0)
		var cast_map: Dictionary = cast_view.get("pixel_data")
		var images: Dictionary = cast_map.get("sprites", {})
		for sprite_id in ["asmodeus", "haniel", "alric", "joren", "bandit_thug", "grizzly_bear", "wild_boar"]:
			_expect(images.has(sprite_id), "User asset ID must be mapped: " + sprite_id)
		cast_view.call("_start_alley_wave", 1, "cliffside_alley.jpg")
		_expect(str(cast_view.get("stage_area")) == "cliffside_alley", "Sprite alley uses correct area")
		_expect(cast_view.get("ally_sprite") != null, "Alric has a visible battle slot")
		_expect(cast_view.get("extra_thug_sprite") != null, "Second thug has a battle slot")
		cast_view.call("_start_alley_wave", 2, "cliffside_alley_2.jpg")
		_expect(cast_view.get("joren_boss_sprite") != null, "Joren has a boss slot in wave 2")
		cast_view.queue_free()


	# Prototype 007: accessible daily actions and battle sprite presentation.
	var v7_resource: Resource = load("res://scenes/prototype_story_v7.tscn")
	_expect(v7_resource is PackedScene, "Prototype 007 scene must load")
	if v7_resource is PackedScene:
		var fixed_view: Node = (v7_resource as PackedScene).instantiate()
		root.add_child(fixed_view)
		# Regression from the player's Day 7 screenshot: saved interlude had
		# 3/3 actions yet the previous "complete" flag disabled ALL buttons.
		# Reentering that interlude must unlock actions without losing progress.
		var completed_save: Dictionary = SaveStore.new_save()
		completed_save["campaigns"] = {"love_beyond": {
			"interludes": {"after_part_four": {
				"day": 7, "actions_left": 3, "complete": true,
				"hp": 100, "max_hp": 100, "xp": 12, "level": 1, "supplies": 1
			}},
			"progression": {"asmodeus": {
				"hp": 100, "max_hp": 100, "xp": 12, "level": 1, "supplies": 1
			}}
		}}
		fixed_view.set("save_data", completed_save)
		fixed_view.call("_load_story_if_needed")
		fixed_view.call("_enter_interlude", "after_part_four")
		var free_time = fixed_view.get("interlude_engine")
		_expect(int(free_time.state["actions_left"]) == 3, "Restored Day 7 offers 3 activities")
		_expect(int(free_time.state["day"]) == 7, "Fix must preserve the player's day")
		_expect(int(free_time.state["xp"]) == 12 and int(free_time.state["supplies"]) == 1, "Fix keeps earned EXP and supplies")
		_expect(not bool(free_time.state["complete"]), "Entering a saved completed interlude clears old lockout")
		_expect(free_time.can_spend_action() and free_time.may_hunt(), "Saved completed interlude re-enables daily actions and hunting")
		var daily_scroll: ScrollContainer = fixed_view.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
		_expect(daily_scroll != null, "Daily activity panel scrolls on small displays")
		for item in ["rest", "care", "explore"]:
			var daily_button: Button = fixed_view.find_child("Daily_action_" + item, true, false) as Button
			_expect(daily_button != null, "Daily option is visible: " + item)
			if daily_button != null:
				_expect(not daily_button.disabled, "Daily option must be clickable: " + item)
				daily_button.pressed.emit()
		_expect(int(free_time.state["actions_left"]) == 0, "Three actions work through UI signals")
		var exhausted: Button = fixed_view.find_child("Daily_action_rest", true, false) as Button
		_expect(exhausted != null and exhausted.disabled, "Spent actions are disabled with guidance")
		var refresh: Button = fixed_view.find_child("Daily_NewOrdinaryDay", true, false) as Button
		_expect(refresh != null, "Exhausted day offers a quick ordinary-day refresh")
		var index_before: int = int(fixed_view.get("event_index"))
		if refresh != null:
			refresh.pressed.emit()
		_expect(int(free_time.state["actions_left"]) == 3, "Ordinary day refreshes all three actions")
		_expect(int(fixed_view.get("event_index")) == index_before, "Ordinary day never advances story")
		# A formerly completed interlude must also recover by sleeping normally.
		free_time.state["complete"] = true
		free_time.ordinary_day()
		_expect(not bool(free_time.state["complete"]), "Ordinary day clears a stale completed flag")
		_expect(free_time.can_spend_action() and free_time.may_hunt(), "Ordinary morning restores Hunt, Rest, Care and Explore")
		fixed_view.call("_save_interlude")
		fixed_view.call("_draw_interlude")
		fixed_view.call("_show_menu")
		fixed_view.call("_resume_adventure")
		var resumed_time = fixed_view.get("interlude_engine")
		_expect(int(resumed_time.state["actions_left"]) == 3, "Refreshed activities persist after save/resume")
		fixed_view.call("_start_battle", "Asmodeus", "Haniel")
		var player_picture: TextureRect = fixed_view.get("actor_sprite") as TextureRect
		var enemy_picture: TextureRect = fixed_view.get("enemy_sprite") as TextureRect
		var picture_layer: Control = fixed_view.get("pixel_layer") as Control
		var battle_ui: Node = fixed_view.get("action_row").get_parent().get_parent().get_parent().get_parent()
		_expect(player_picture != null and player_picture.flip_h, "Asmodeus mirrored on player side")
		_expect(picture_layer.get_index() < battle_ui.get_index(), "Battle sprites render BEHIND move controls")
		_expect(player_picture.anchor_top > 0.40, "Player sprite lowered on stage")
		_expect(enemy_picture.anchor_bottom <= 0.72, "Enemy feet leave HUD clear")
		fixed_view.call("_draw_battle")
		_expect(picture_layer.get_index() < battle_ui.get_index(), "UI stays above sprites on redraw")
		var battle_gap: Control = fixed_view.get("stage_spacer") as Control
		_expect(battle_gap != null and battle_gap.visible, "Battlefield reserves vertical room above move buttons")
		fixed_view.call("_hide_pixel_stage")
		_expect(not battle_gap.visible, "Returning to story hides battlefield spacer")
		fixed_view.call("_start_battle", "Haniel", "Asmodeus")
		_expect(not enemy_picture.flip_h, "Asmodeus faces inward from enemy side")
		fixed_view.queue_free()


	# Prototype 008: one-click narration skips must stop at ALL gameplay.
	var v8_resource: Resource = load("res://scenes/prototype_story_v8.tscn")
	_expect(v8_resource is PackedScene, "Dialogue skip scene must load")
	if v8_resource is PackedScene:
		var skipper: Node = (v8_resource as PackedScene).instantiate()
		root.add_child(skipper)
		skipper.set("save_data", SaveStore.new_save())
		skipper.call("_start_dialogue")
		var intro_lines: Array = skipper.get("chapter_data").get("dialogue", [])
		_expect(skipper.find_child("SkipDialogueButton", true, false) != null, "Prologue has a skip-dialogue option")
		skipper.call("_skip_intro_dialogue")
		_expect(int(skipper.get("line_index")) == intro_lines.size() - 1, "Intro skip lands on choose fighter")
		_expect(skipper.find_child("SkipDialogueButton", true, false) == null, "Intro skip does not bypass fighter selection")
		skipper.call("_begin_story_events")
		_expect(skipper.find_child("SkipDialogueButton", true, false) != null, "Story line has a skip-dialogue option")
		skipper.call("_skip_story_dialogue")
		var chain: Array = skipper.get("story_events")
		var beat: Dictionary = chain[int(skipper.get("event_index"))]
		_expect(str(beat.get("kind", "")) == "gather", "Skip Part One and dialogue in Part Two, stopping at branch gathering")
		_expect(str(skipper.get("part_label")) == "PART TWO", "Skipped part headers update correctly")
		var before_gather := int(skipper.get("event_index"))
		skipper.call("_skip_story_dialogue")
		_expect(int(skipper.get("event_index")) == before_gather, "Skip must not advance a gathering activity")
		for twig in range(3):
			skipper.call("_collect_branch")
		skipper.call("_advance_event")
		skipper.call("_skip_story_dialogue")
		_expect(bool(skipper.get("bear_mode")), "Skip stops at required grizzly battle")
		beat = chain[int(skipper.get("event_index"))]
		_expect(str(beat.get("kind", "")) == "battle", "Bear fight is never skipped")
		var before_bear := int(skipper.get("event_index"))
		skipper.call("_skip_story_dialogue")
		_expect(int(skipper.get("event_index")) == before_bear, "Skip button cannot bypass active battle")
		skipper.queue_free()

		var chapter_skip: Node = (v8_resource as PackedScene).instantiate()
		root.add_child(chapter_skip)
		chapter_skip.set("save_data", SaveStore.new_save())
		chapter_skip.call("_load_story_if_needed")
		var authored: Array = chapter_skip.get("story_events")
		var part_four := -1
		for j in range(authored.size()):
			if str(authored[j].get("kind", "")) == "title" and str(authored[j].get("part", "")) == "PART FOUR":
				part_four = j
				break
		_expect(part_four >= 0, "Part Four title exists for skip tests")
		if part_four >= 0:
			chapter_skip.set("story_mode", true)
			chapter_skip.set("event_index", part_four)
			chapter_skip.call("_show_event")
			chapter_skip.call("_skip_story_dialogue")
			_expect(bool(chapter_skip.get("interlude_mode")), "Skip stops at Part Four free-time decisions")
			_expect(str(chapter_skip.get("current_interlude_id")) == "after_part_four", "First free-time stage preserved")
			var day_index := int(chapter_skip.get("event_index"))
			chapter_skip.call("_skip_story_dialogue")
			_expect(int(chapter_skip.get("event_index")) == day_index, "Cannot skip free-time choices")
			chapter_skip.call("_exciting_tomorrow")
			_expect(str(authored[int(chapter_skip.get("event_index"))].get("kind", "")) == "title", "Exciting day continues authored Part Five")
			chapter_skip.call("_skip_story_dialogue")
			_expect(bool(chapter_skip.get("interlude_mode")), "Skip stops at second free-time stage")
			chapter_skip.call("_exciting_tomorrow")
			chapter_skip.call("_skip_story_dialogue")
			_expect(bool(chapter_skip.get("alley_mode")), "Skip stops at Part Six alley wave one")
			_expect(int(chapter_skip.get("wave_engine").wave) == 1, "Skipping dialogue does not skip combat waves")
		chapter_skip.queue_free()


	# Prototype 009: the new environment pack is optional on CI. When a
	# background is absent, story/battle logic must still run normally.
	var v9_resource: Resource = load("res://scenes/prototype_story_v9.tscn")
	_expect(v9_resource is PackedScene, "Environment scene must load")
	if v9_resource is PackedScene:
		var environments: Node = (v9_resource as PackedScene).instantiate()
		root.add_child(environments)
		environments.set("save_data", SaveStore.new_save())
		environments.call("_read_pixel_data")
		var background_config: Dictionary = environments.get("pixel_data")
		var area_ids: Array = []
		for definition in background_config.get("areas", []):
			area_ids.append(str(definition.get("id", "")))
			_expect(str(definition.get("background", "")).ends_with(".webp"), "Location maps to optimized WebP")
		for mandatory in ["thundercloud", "forest_clearing", "bear_forest", "cliffside_alley", "forest_camp", "market_street", "alric_smithy"]:
			_expect(area_ids.has(mandatory), "Background ID is mapped: " + mandatory)
		var routes: Dictionary = background_config.get("routes", {})
		_expect(str(routes.get("bear", "")) == "bear_forest", "The bear has its own forest")
		_expect(str(routes.get("market", "")) == "market_street", "Market background reserved for future shop")
		_expect(str(routes.get("smithy", "")) == "alric_smithy", "Alric's workshop background reserved")

		environments.call("_show_location_gallery", 0)
		_expect(environments.find_child("LocationNext", true, false) != null, "Location gallery has next button")
		environments.call("_show_location_gallery", 6)
		_expect(environments.find_child("LocationPrevious", true, false) != null, "Location gallery has previous button")
		_expect(environments.find_child("LocationBack", true, false) != null, "Location gallery can return to title")
		environments.call("_show_menu")
		environments.call("_start_battle", "Asmodeus", "Haniel")
		_expect(str(environments.get("stage_area")) == "thundercloud", "Opening duel uses supplied storm background route")
		environments.call("_start_battle_preview")
		_expect(str(environments.get("stage_area")) == "forest_clearing", "Boar uses daylight forest")
		environments.call("_exit_preview")
		environments.call("_start_bear_battle", {"image":"bear_boss.jpg"})
		_expect(str(environments.get("stage_area")) == "bear_forest", "Bear boss uses dark forest, not hunting clearing")
		environments.call("_show_menu")
		environments.call("_load_story_if_needed")
		environments.call("_enter_interlude", "after_part_four")
		_expect(bool(environments.get("interlude_mode")), "Camp routines remain available with environment art")
		_expect(int(environments.get("interlude_engine").state.get("actions_left", 0)) == 3, "Camp background does not consume daily actions")
		environments.queue_free()


	# Prototype 010: story-locked 3-slot party, original moves and save safety.
	const PartySystem = preload("res://scripts/core/party_engine.gd")
	var party_config: Dictionary = ContentStore.read_dictionary("res://data/party/love_beyond.json")
	var sample_save: Dictionary = SaveStore.new_save()
	sample_save["campaigns"] = {"love_beyond": {
		"opening_parts_completed": 4,
		"interludes": {"after_part_four": {"day": 7, "actions_left": 2}},
		"progression": {"asmodeus": {"level": 3, "xp": 11, "hp": 77, "max_hp": 116, "supplies": 4}}
	}}
	var party = PartySystem.new()
	party.begin(sample_save, party_config)
	_expect(party.active.size() == 3, "Party has exactly three active slots")
	_expect(party.active[0] == "asmodeus" and party.active[1] == "haniel" and party.active[2] == "", "Initial party has two protagonists and an empty slot")
	_expect(not party.is_unlocked("alric"), "Alric cannot join before Part Six")
	_expect(not party.assign(2, "alric"), "Locked characters cannot enter a party")
	_expect(party.assign(0, "haniel"), "Moving an active member into another slot succeeds")
	_expect(party.active[0] == "haniel" and party.active[1] == "asmodeus", "An existing ally is swapped, never duplicated")
	_expect(party.assign(1, ""), "An active character can move into reserves")
	_expect(not party.assign(0, ""), "Party management cannot remove the last remaining ally")
	var asmo_sheet: Dictionary = party.sheet("asmodeus", sample_save)
	_expect(int(asmo_sheet.get("level", 0)) == 3 and int(asmo_sheet.get("hp", 0)) == 77, "Character sheet uses persisted level and HP")
	_expect(int(asmo_sheet.get("max_hp", 0)) == 116 and int(asmo_sheet.get("xp", 0)) == 11, "Character sheet retains HP and EXP progression")
	_expect(asmo_sheet.get("moves", []).size() == 4, "Every member has four displayed move slots")
	_expect(str(asmo_sheet.get("moves", [])[1].get("id", "")) == "black_ice", "Character moves come from the original battle data")
	_expect(asmo_sheet.get("moves", [])[3].is_empty(), "Unlearned move slot stays empty rather than inventing skills")
	_expect(int(asmo_sheet.get("item_slots", 0)) == 3, "Every sheet reserves three item slots")

	party.write_to(sample_save)
	var saved_lb: Dictionary = sample_save.get("campaigns", {}).get("love_beyond", {})
	_expect(int(saved_lb.get("interludes", {}).get("after_part_four", {}).get("day", 0)) == 7, "Party changes preserve free-time checkpoints")
	_expect(int(saved_lb.get("progression", {}).get("asmodeus", {}).get("xp", 0)) == 11, "Party changes preserve gained EXP")
	var reopened_party = PartySystem.new()
	reopened_party.begin(sample_save, party_config)
	_expect(reopened_party.active == party.active, "Party slots survive save and reload")

	saved_lb["opening_parts_completed"] = 6
	sample_save["campaigns"]["love_beyond"] = saved_lb
	reopened_party.begin(sample_save, party_config)
	_expect(reopened_party.is_unlocked("alric"), "Part Six completion unlocks Alric for optional party use")
	_expect(reopened_party.assign(2, "alric"), "Three-character party can include unlocked Alric")
	_expect(reopened_party.member_count() <= 3 and reopened_party.active.count("alric") == 1, "Party may not exceed three members or duplicate allies")
	var alric_sheet: Dictionary = reopened_party.sheet("alric", sample_save)
	_expect(str(alric_sheet.get("ability", {}).get("name", "")) == "Friends and Family", "Alric has reserved Smithy discount passive")
	_expect(not bool(alric_sheet.get("ability", {}).get("implemented", true)), "Planned shop discount is not falsely active")

	var v10_resource: Resource = load("res://scenes/prototype_story_v10.tscn")
	_expect(v10_resource is PackedScene, "Party management scene must load")
	if v10_resource is PackedScene:
		var party_view: Node = (v10_resource as PackedScene).instantiate()
		root.add_child(party_view)
		party_view.set("party_disable_disk_writes", true)
		party_view.set("save_data", SaveStore.new_save())
		party_view.call("_show_party_menu", false)
		_expect(party_view.find_child("PartySlot_2", true, false) != null, "Empty third slot is visible in party menu")
		var locked_button: Button = party_view.find_child("PartyMember_alric", true, false) as Button
		_expect(locked_button != null and locked_button.disabled, "Locked Alric appears but is not selectable")
		party_view.call("_edit_party_slot", 2)
		var locked_choice: Button = party_view.find_child("PartyPick_alric", true, false) as Button
		_expect(locked_choice != null and locked_choice.disabled, "Story gate applies to party selection UI")
		party_view.call("_show_character_sheet", "asmodeus")
		_expect(party_view.find_child("PartyCharacterSprite", true, false) != null, "Character sheet has sprite display")
		party_view.set("save_data", sample_save)
		party_view.call("_show_party_menu", false)
		var available_alric: Button = party_view.find_child("PartyMember_alric", true, false) as Button
		_expect(available_alric != null and not available_alric.disabled, "Old completed save unlocks Alric in menu")
		party_view.call("_assign_party_member", 2, "alric")
		var updated_party = party_view.get("party_engine")
		_expect(updated_party.active[2] == "alric", "UI assignment changes active third slot")
		_expect(party_view.get("save_data").get("campaigns", {}).get("love_beyond", {}).get("party", {}).get("active", [])[2] == "alric", "UI change is saved in campaign data")
		party_view.call("_load_story_if_needed")
		party_view.call("_enter_interlude", "after_part_four")
		_expect(bool(party_view.get("interlude_mode")), "Test can open an authored daily interlude after loading chapter data")
		party_view.call("_show_party_menu", true)
		party_view.call("_close_party_menu")
		_expect(bool(party_view.get("interlude_mode")), "Returning from party management preserves ordinary-day mode")
		_expect(party_view.find_child("DailyActivitiesScroll", true, false) != null, "Party screen returns to functional daily routines")
		party_view.queue_free()

	var chapter: Dictionary = ContentStore.load_chapter("love_beyond_prototype_001")
	var haniel: Dictionary = ContentStore.load_character("haniel")
	var asmodeus: Dictionary = ContentStore.load_character("asmodeus")
	var difficulties: Dictionary = ContentStore.read_dictionary("res://data/difficulties.json")

	_expect(chapter.get("dialogue", []).size() >= 2, "Missing chapter dialogue")
	_expect(chapter.get("fighters", []).has("haniel"), "Haniel missing from chapter")
	_expect(chapter.get("fighters", []).has("asmodeus"), "Asmodeus missing from chapter")
	_expect(haniel.get("id", "") == "haniel")
	_expect(asmodeus.get("id", "") == "asmodeus")
	_expect(difficulties.get("profiles", []).size() == 4, "Expected four difficulties")

	var duel = DuelEngine.new()
	duel.setup(haniel, asmodeus)
	_expect(duel.player_moves().size() == 3)
	var outcome: Dictionary = duel.take_turn("divine_arrow")
	_expect(outcome["enemy_hp"] == 77, "Arrow should deal 23")
	_expect(outcome["player_hp"] == 83, "Normal enemy attack should deal 17")

	duel.setup(asmodeus, haniel)
	outcome = duel.take_turn("ice_guard")
	_expect(outcome["player_hp"] == 94, "Guard should reduce damage to 6")

	var hard: Dictionary = {"enemy_hp_multiplier": 1.3, "enemy_damage_multiplier": 1.25}
	duel.setup(haniel, asmodeus, hard)
	_expect(duel.enemy_max_hp == 130, "Hard HP scaling")
	outcome = duel.take_turn("attack")
	_expect(outcome["enemy_hp"] == 115)
	_expect(outcome["player_hp"] == 79, "Hard enemy attack scaling")

	var story: Dictionary = {"enemy_hp_multiplier": 0.8, "enemy_damage_multiplier": 0.7}
	duel.setup(haniel, asmodeus, story)
	_expect(duel.enemy_max_hp == 80, "Story HP scaling")
	outcome = duel.take_turn("attack")
	_expect(outcome["player_hp"] == 88, "Story enemy damage scaling")

	duel.setup(haniel, asmodeus)
	var victory := false
	for round_index in range(10):
		outcome = duel.take_turn("divine_arrow")
		if outcome["finished"]:
			victory = bool(outcome["victory"])
			break
	_expect(victory, "Haniel should be able to win")

	duel.setup(asmodeus, haniel)
	victory = false
	for round_index in range(10):
		outcome = duel.take_turn("black_ice")
		if outcome["finished"]:
			victory = bool(outcome["victory"])
			break
	_expect(victory, "Asmodeus should be able to win")

	var save_data: Dictionary = SaveStore.new_save()
	SaveStore.set_difficulty(save_data, "hard")
	_expect(save_data["settings"]["difficulty"] == "hard")
	SaveStore.record_test_victory(save_data, "love_beyond_prototype_001", "haniel", "hard")
	SaveStore.record_test_victory(save_data, "love_beyond_prototype_001", "haniel", "hard")
	_expect(save_data["battle_records"]["love_beyond_prototype_001|haniel|hard"] == 2)
	SaveStore.unlock_character(save_data, "haniel")
	SaveStore.unlock_character(save_data, "haniel")
	_expect(save_data["roster"]["unlocked"].size() == 1)

	if failures.is_empty():
		print("Paleverse smoke tests passed: content, duel, difficulty scaling, save model, both fighters.")
		quit(0)
	else:
		printerr("Paleverse smoke test failures: " + str(failures))
		quit(1)

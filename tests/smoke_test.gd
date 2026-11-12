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
		_expect(party_view.find_child("TitleMenuScroll", true, false) != null, "Title menu scrolls to show the new party button at 720p")
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


	# Prototype 011: Training points are independent of EXP/levels, persist
	# across days, unlock moves, and never bypass story milestones.
	const MoveTraining = preload("res://scripts/core/training_engine.gd")
	var training_config: Dictionary = ContentStore.read_dictionary("res://data/training/love_beyond.json")
	var t_save: Dictionary = SaveStore.new_save()
	t_save["campaigns"] = {"love_beyond": {
		"opening_parts_completed": 4,
		"progression": {"asmodeus": {"level": 4, "xp": 17, "hp": 88, "max_hp": 124}}
	}}
	var trainer = MoveTraining.new()
	trainer.begin(training_config, t_save)
	_expect(trainer.can_train("asmodeus", 4), "Asmodeus can train during Part Four free time")
	_expect(not trainer.can_train("haniel", 4), "Haniel's future techniques are story-gated")
	_expect(not trainer.can_train("alric", 4), "Alric's training is unavailable before recruitment")
	var first_session: Dictionary = trainer.session("asmodeus", 4)
	_expect(bool(first_session.get("ok", false)) and not bool(first_session.get("learned", true)), "First practice earns points without instantly learning")
	_expect(int(first_session.get("points", -1)) == 10, "Training bar starts at 10 of 30 points")
	_expect(int(trainer.next_move("asmodeus", 4).get("progress", 0)) == 10, "Move bar reflects earned practice points")
	trainer.write_to(t_save)
	var saved_training: Dictionary = t_save.get("campaigns", {}).get("love_beyond", {}).get("training", {})
	_expect(int(saved_training.get("asmodeus", {}).get("points", 0)) == 10, "Training points persist in campaign save")
	_expect(int(t_save.get("campaigns", {}).get("love_beyond", {}).get("progression", {}).get("asmodeus", {}).get("xp", 0)) == 17, "Training does not spend or grant EXP")
	var reopened_trainer = MoveTraining.new()
	reopened_trainer.begin(training_config, t_save)
	_expect(int(reopened_trainer.next_move("asmodeus", 4).get("progress", 0)) == 10, "Training bar resumes after reload")
	reopened_trainer.session("asmodeus", 4)
	var unlock: Dictionary = reopened_trainer.session("asmodeus", 4)
	_expect(bool(unlock.get("learned", false)), "Third training session unlocks Black Ice Lance")
	_expect(reopened_trainer.learned("asmodeus").has("black_ice_lance"), "Learned move ID stored exactly once")
	var before_locked: Dictionary = reopened_trainer.state.duplicate(true)
	var denied_training: Dictionary = reopened_trainer.session("asmodeus", 4)
	_expect(not bool(denied_training.get("ok", true)), "Second technique is locked until Part Six")
	_expect(reopened_trainer.state == before_locked, "Unavailable techniques never alter training points")
	reopened_trainer.write_to(t_save)
	var known_sheet: Dictionary = party.sheet("asmodeus", t_save)
	_expect(str(known_sheet.get("moves", [])[3].get("id", "")) == "black_ice_lance", "Fourth equipped slot shows learned technique")
	_expect(int(known_sheet.get("level", 0)) == 4, "Training unlocks moves without raising character level")
	var unlocked_second: Dictionary = reopened_trainer.session("asmodeus", 6)
	_expect(bool(unlocked_second.get("ok", false)) and not bool(unlocked_second.get("learned", true)), "Part Six enables advanced training without instant unlock")
	_expect(int(reopened_trainer.next_move("asmodeus", 6).get("progress", 0)) == 10, "Progress rolls into next technique safely")
	_expect(not reopened_trainer.session("haniel", 4).get("ok", false), "Haniel technique is still gated before Part Six")
	_expect(bool(reopened_trainer.session("haniel", 6).get("ok", false)), "Later routine can train Haniel's own path")

	var v11_resource: Resource = load("res://scenes/prototype_story_v11.tscn")
	_expect(v11_resource is PackedScene, "Move-training scene must import")
	if v11_resource is PackedScene:
		var training_view: Node = (v11_resource as PackedScene).instantiate()
		root.add_child(training_view)
		var fresh_training_save: Dictionary = SaveStore.new_save()
		fresh_training_save["campaigns"] = {"love_beyond": {"opening_parts_completed": 4}}
		training_view.set("save_data", fresh_training_save)
		training_view.call("_load_story_if_needed")
		training_view.call("_enter_interlude", "after_part_four")
		var daily_train: Button = training_view.find_child("Daily_action_train", true, false) as Button
		_expect(daily_train != null and not daily_train.disabled, "Train is a clickable ordinary-day option")
		var interlude = training_view.get("interlude_engine")
		var initial_actions: int = int(interlude.state.get("actions_left", 0))
		var initial_index: int = int(training_view.get("event_index"))
		if daily_train != null:
			daily_train.pressed.emit()
		_expect(training_view.find_child("TrainMoveBar", true, false) != null, "Training menu displays a move progress bar")
		var cancel_train: Button = training_view.find_child("TrainCancel", true, false) as Button
		_expect(cancel_train != null, "Players can decline to spend an activity on training")
		if cancel_train != null:
			cancel_train.pressed.emit()
		_expect(int(interlude.state.get("actions_left", -1)) == initial_actions, "Canceling training never spends an action")
		for practice in range(3):
			training_view.call("_open_training_menu")
			var train_confirm: Button = training_view.find_child("TrainConfirm", true, false) as Button
			_expect(train_confirm != null and not train_confirm.disabled, "Practice is selectable until current move bar fills")
			if train_confirm != null:
				train_confirm.pressed.emit()
		_expect(int(interlude.state.get("actions_left", -1)) == 0, "Three training sessions spend exactly three daily actions")
		_expect(int(training_view.get("event_index")) == initial_index, "Training never advances the authored story")
		_expect(int(interlude.state.get("xp", -1)) == 0 and int(interlude.state.get("level", -1)) == 1, "Practice never adds combat EXP or levels")
		var recorded_training: Dictionary = training_view.get("save_data").get("campaigns", {}).get("love_beyond", {}).get("training", {}).get("asmodeus", {})
		_expect(recorded_training.get("learned", []).has("black_ice_lance"), "UI training records learned move in existing save schema")
		training_view.call("_show_party_menu", true)
		training_view.call("_show_character_sheet", "asmodeus")
		_expect(training_view.find_child("CharacterTrainingHeader", true, false) != null, "Character sheet displays training section")
		_expect(training_view.find_child("CharacterTrainingBar", true, false) != null, "Character sheet shows next move bar")
		training_view.call("_close_party_menu")
		_expect(bool(training_view.get("interlude_mode")), "Character sheet returns to the same free-time day")
		training_view.call("_ordinary_tomorrow")
		_expect(int(interlude.state.get("actions_left", 0)) == 3, "New ordinary day restores training opportunities")
		training_view.call("_open_training_menu")
		var locked_train: Button = training_view.find_child("TrainConfirm", true, false) as Button
		_expect(locked_train != null and locked_train.disabled, "Future technique cannot be trained before its part unlock")
		training_view.call("_train_current_character")
		_expect(int(interlude.state.get("actions_left", 0)) == 3, "Blocked training never spends an action")
		# Old free-time state and unlocked skills survive a change of interlude.
		training_view.call("_enter_interlude", "after_part_five")
		_expect(training_view.get("save_data").get("campaigns", {}).get("love_beyond", {}).get("training", {}).get("asmodeus", {}).get("learned", []).has("black_ice_lance"), "Move unlock is global across separate interludes")
		training_view.queue_free()


	# Prototype 012: independent 3-person combat, target selection, trained
	# techniques, passives, speed turns and turn-cost bench substitution.
	const TeamCombat = preload("res://scripts/core/party_battle_engine.gd")
	var battle_save: Dictionary = SaveStore.new_save()
	battle_save["campaigns"] = {"love_beyond": {
		"opening_parts_completed": 6,
		"party": {"active":["asmodeus", "haniel", "alric"]},
		"training": {"asmodeus": {"learned":["black_ice_lance"], "points":0}},
		"progression": {"asmodeus": {"level": 3, "xp": 14, "hp": 112, "max_hp": 116}}
	}}
	var combat_party = PartySystem.new()
	combat_party.begin(battle_save, party_config)
	var battle_sheets: Dictionary = {}
	for id in combat_party.unlocked:
		battle_sheets[id] = combat_party.sheet(id, battle_save)
	var team = TeamCombat.new()
	team.setup(["asmodeus", "haniel", "alric"], [], battle_sheets, ["wild_boar", "gray_wolf"])
	_expect(team.allies.size() == 3 and team.enemies.size() == 2, "Optional battle allows three party members versus two opponents")
	_expect(str(team.current_actor().get("id", "")) == "haniel", "Speed determines starting ally turn")
	_expect(team.targets("heal").size() == 3, "Healing targets a living team member")
	_expect(team.targets("divine_arrow").size() == 2, "Damage moves target enemies, not allies")
	var untouched_enemy: int = int(team.enemies[0].get("hp", 0))
	var failed_target: Dictionary = team.use_move("divine_arrow", 7)
	_expect(not bool(failed_target.get("ok", true)), "Invalid target cannot resolve a move")
	_expect(int(team.enemies[0].get("hp", 0)) == untouched_enemy and str(team.current_actor().get("id", "")) == "haniel", "Bad targets do not cost turns or damage enemies")
	team.allies[0]["hp"] = 45
	var healer: Dictionary = team.use_move("heal", 0)
	_expect(bool(healer.get("ok", false)) and int(team.allies[0]["hp"]) == 68, "Haniel can choose Asmodeus to heal; Angelic Grace adds 3 HP")
	_expect(str(team.current_actor().get("id", "")) == "asmodeus", "Next fastest party member receives a turn")
	_expect(team.current_moves().any(func(m): return str(m.get("id", "")) == "black_ice_lance"), "Learned Black Ice Lance appears as a real attack")
	var ice: Dictionary = team.use_move("black_ice_lance", 1)
	_expect(bool(ice.get("ok", false)) and int(team.enemies[1]["hp"]) == 35, "Level 3 Black Ice Lance deals 27 power +1 ATK scaling +2 ice affinity to chosen wolf")
	_expect(str(team.current_actor().get("id", "")) == "alric", "Third teammate acts before enemy phase")
	var hammer: Dictionary = team.use_move("hammer", 0)
	_expect(bool(hammer.get("ok", false)), "Alric can use his original Hammer move")
	_expect(int(team.round_number) == 2, "Enemies act only after living party members finish their turns")
	_expect(int(team.allies[0]["hp"]) < 68, "Enemies retaliate and damage the party")
	_expect(int(battle_save["campaigns"]["love_beyond"]["progression"]["asmodeus"]["xp"]) == 14, "Practice combat never modifies persistent EXP")

	var solo = TeamCombat.new()
	solo.setup(["asmodeus"], [], battle_sheets, ["wild_boar"])
	var solo_before: int = int(solo.allies[0]["hp"])
	_expect(solo.use_move("ice_guard").get("ok", false), "Guard action succeeds without target selection")
	_expect(int(solo.allies[0]["hp"]) == solo_before - 5, "Guard halves incoming boar damage after Level 3 Defense reduction")
	_expect(not bool(solo.allies[0].get("guard", true)), "Guard ends at the enemy phase")
	var replay = TeamCombat.new()
	replay.setup(["asmodeus"], [], battle_sheets, ["wild_boar"])
	var attack_ok: Dictionary = replay.use_move("black_ice_lance", 0)
	_expect(bool(attack_ok.get("ok", false)) and int(replay.enemies[0]["hp"]) == 20, "Trained move is usable with character stat and affinity bonuses")

	var bench = TeamCombat.new()
	bench.setup(["asmodeus", "haniel"], ["alric"], battle_sheets, ["wild_boar"])
	_expect(str(bench.current_actor().get("id", "")) == "haniel", "Haniel starts faster than Asmodeus")
	var switch_res: Dictionary = bench.switch_with_reserve("alric")
	_expect(bool(switch_res.get("ok", false)), "Unselected Alric can switch in as a reserve after Part Six")
	_expect(bench.allies.size() == 2 and bench.reserves.size() == 1, "Switch preserves the three-character party limit")
	_expect(bench.allies[1]["id"] == "alric" and bench.reserves[0]["id"] == "haniel", "Switch exchanges the current fighter and reserve")
	_expect(bench.round_number == 1 and str(bench.current_actor().get("id", "")) == "asmodeus", "Switch uses Haniel's turn rather than granting a free action")
	var rejected_switch: Dictionary = bench.switch_with_reserve("unknown")
	_expect(not bool(rejected_switch.get("ok", true)) and str(bench.current_actor().get("id", "")) == "asmodeus", "Invalid switch does not consume another turn")

	var v12_scene: Resource = load("res://scenes/prototype_story_v12.tscn")
	_expect(v12_scene is PackedScene, "Three-member battle scene imports")
	if v12_scene is PackedScene:
		var combat_view: Node = (v12_scene as PackedScene).instantiate()
		root.add_child(combat_view)
		combat_view.set("save_data", battle_save.duplicate(true))
		combat_view.call("_party_battle_start", "forest_clearing")
		_expect(bool(combat_view.get("party_battle_active")), "Party battle UI starts without story progression")
		var shown_team = combat_view.get("party_battle")
		_expect(shown_team.allies.size() == 3, "UI uses saved active three-member lineup")
		var move_button: Button = combat_view.find_child("PartyMove_heal", true, false) as Button
		_expect(move_button != null, "Haniel's heal is selectable in practice")
		if move_button != null:
			move_button.pressed.emit()
		_expect(combat_view.find_child("PartyTarget_Ally_0", true, false) != null, "Heal opens target selection for another ally")
		combat_view.call("_party_battle_use", "heal", 0)
		_expect(str(shown_team.current_actor().get("id", "")) == "asmodeus", "UI advances after valid heal")
		var ice_button: Button = combat_view.find_child("PartyMove_black_ice_lance", true, false) as Button
		_expect(ice_button != null, "Unlocked trained move appears on real battle button")
		if ice_button != null:
			ice_button.pressed.emit()
		_expect(combat_view.find_child("PartyTarget_Enemy_1", true, false) != null, "Player can target second enemy")
		var original_wolf: int = int(shown_team.enemies[1]["hp"])
		combat_view.call("_party_battle_use", "black_ice_lance", 1)
		_expect(int(shown_team.enemies[1]["hp"]) < original_wolf, "UI Black Ice Lance hits chosen target")
		combat_view.call("_show_menu")
		_expect(not bool(combat_view.get("party_battle_active")), "Leaving practice cleanly restores the title")
		_expect(combat_view.get("save_data") == battle_save, "Non-canon battle leaves saved EXP, training and HP untouched")
		combat_view.set("save_data", battle_save.duplicate(true))
		var mutable_campaign: Dictionary = combat_view.get("save_data").get("campaigns", {}).get("love_beyond", {})
		mutable_campaign["party"] = {"active":["asmodeus", "haniel", ""]}
		combat_view.get("save_data")["campaigns"]["love_beyond"] = mutable_campaign
		combat_view.call("_party_battle_start", "cliffside_alley")
		_expect(str(combat_view.get("party_battle_area")) == "cliffside_alley", "Cliffside practice uses the correct background")
		var swap_available = combat_view.get("party_battle")
		_expect(swap_available.reserves.size() == 1, "Alric is a reserve if left out of active lineup")
		combat_view.call("_party_battle_switch_menu")
		var swap_button: Button = combat_view.find_child("PartySwitch_alric", true, false) as Button
		_expect(swap_button != null, "Party switch menu exposes unlocked reserve member")
		if swap_button != null:
			swap_button.pressed.emit()
		_expect(swap_available.allies[1]["id"] == "alric", "UI switch consumes current actor's turn and substitutes Alric")
		combat_view.queue_free()


	# Prototype 013: persistent backpack, three-slot equipment, one-use food,
	# real sheet/combat bonuses and safe in-memory battle item use.
	const InventorySystem = preload("res://scripts/core/inventory_engine.gd")
	var item_catalog: Dictionary = ContentStore.read_dictionary("res://data/items/love_beyond.json")
	var inventory_save: Dictionary = SaveStore.new_save()
	inventory_save["campaigns"] = {"love_beyond": {
		"opening_parts_completed": 4,
		"interludes": {"after_part_four": {"day": 8, "actions_left": 2}},
		"progression": {"asmodeus": {"level": 1, "xp": 12, "hp": 60, "max_hp": 100, "supplies": 2}}
	}}
	var inventory_party = PartySystem.new()
	inventory_party.begin(inventory_save, party_config)
	var starter = InventorySystem.new()
	starter.begin(inventory_save, item_catalog)
	_expect(starter.just_granted, "Legacy save is offered starter gear once")
	_expect(starter.backpack_count("travel_rations") == 3, "Starter backpack contains stackable rations")
	_expect(starter.slots_for("asmodeus").size() == 3, "Every character receives exactly 3 slots")
	_expect(not starter.equip("alric", 0, "leather_bracers", inventory_party.unlocked), "Cannot equip characters not yet recruited")
	_expect(not starter.equip("haniel", 0, "black_ice_focus", inventory_party.unlocked), "Character-locked equipment cannot be misused")
	_expect(starter.equip("asmodeus", 0, "black_ice_focus", inventory_party.unlocked), "Asmodeus can equip his appropriate black ice focus")
	_expect(starter.backpack_count("black_ice_focus") == 0, "Equipping removes one instance from shared backpack")
	_expect(not starter.equip("asmodeus", 0, "iron_charm", inventory_party.unlocked), "Occupied slot must first be cleared")
	_expect(starter.equip("asmodeus", 1, "iron_charm", inventory_party.unlocked), "Equipment may occupy a second shared slot")
	_expect(starter.equip("asmodeus", 2, "travel_rations", inventory_party.unlocked), "Food may occupy third item slot")
	_expect(not starter.equip("asmodeus", 3, "herbal_bread", inventory_party.unlocked), "Fourth item slot is invalid")
	_expect(starter.slots_for("asmodeus")[2] == "travel_rations", "Food is in the shared third item slot")
	_expect(int(starter.bonuses_for("asmodeus").get("attack", 0)) == 4, "Black ice focus provides +4 ATK")
	_expect(int(starter.bonuses_for("asmodeus").get("damage_reduction", 0)) == 2, "Iron charm grants its special ward effect")
	var invalid_food: Dictionary = starter.consume("asmodeus", 1, 60, 100, inventory_party.unlocked)
	_expect(not bool(invalid_food.get("ok", true)), "Equipment cannot be eaten")
	var full_food: Dictionary = starter.consume("asmodeus", 2, 100, 100, inventory_party.unlocked)
	_expect(not bool(full_food.get("ok", true)) and starter.slots_for("asmodeus")[2] == "travel_rations", "Food is never wasted at full HP")
	var eaten: Dictionary = starter.consume("asmodeus", 2, 60, 100, inventory_party.unlocked)
	_expect(bool(eaten.get("ok", false)) and int(eaten.get("hp", 0)) == 80, "Single serving heals 20 HP")
	_expect(starter.slots_for("asmodeus")[2] == "" and starter.backpack_count("travel_rations") == 2, "Consumed food disappears instead of returning to backpack")
	_expect(not starter.consume("asmodeus", 2, 50, 100, inventory_party.unlocked).get("ok", true), "Empty slot cannot create a free meal")
	_expect(starter.unequip("asmodeus", 1, inventory_party.unlocked), "Can return enchanted accessory to backpack")
	_expect(starter.backpack_count("iron_charm") == 1, "Unequipping restores exactly one unit to shared backpack")
	_expect(starter.equip("asmodeus", 1, "iron_charm", inventory_party.unlocked), "Re-equipping returns ward without duplication")
	var before_reopen: Dictionary = starter.state.duplicate(true)
	starter.write_to(inventory_save)
	var reopened_inventory = InventorySystem.new()
	reopened_inventory.begin(inventory_save, item_catalog)
	_expect(not reopened_inventory.just_granted, "Reloading cannot mint a second starter kit")
	_expect(reopened_inventory.state == before_reopen, "Inventory slot layout, consumed food and backpack counts survive save/reload")
	var asmo_equipped: Dictionary = inventory_party.sheet("asmodeus", inventory_save)
	_expect(int(asmo_equipped.get("attack", 0)) == 26, "Equipped focus changes displayed ATK for practice")
	_expect(int(asmo_equipped.get("defense", 0)) == 27, "Equipped charm raises DEF")
	_expect(int(asmo_equipped.get("damage_reduction", 0)) == 2, "Equipped charm passive is propagated to combat sheets")
	_expect(int(inventory_save["campaigns"]["love_beyond"]["progression"]["asmodeus"]["xp"]) == 12, "Gear changes preserve XP and levels")
	_expect(int(inventory_save["campaigns"]["love_beyond"]["interludes"]["after_part_four"]["day"]) == 8, "Inventory writes preserve existing camp checkpoints")
	_expect(int(reopened_inventory.bonuses_for("asmodeus").get("damage_reduction", 0)) == 2, "Ward persists after reload")
	var armored_sheets: Dictionary = {"asmodeus":asmo_equipped}
	var ward_fight = TeamCombat.new()
	ward_fight.setup(["asmodeus"], [], armored_sheets, ["wild_boar"])
	_expect(bool(ward_fight.use_move("ice_guard").get("ok", false)), "Armored Asmodeus can still guard")
	_expect(int(ward_fight.allies[0]["hp"]) == 56, "Iron Charm reduces enemy damage before guard halves it")
	var plain_save: Dictionary = inventory_save.duplicate(true)
	plain_save["campaigns"]["love_beyond"].erase("inventory")
	var plain_sheet: Dictionary = inventory_party.sheet("asmodeus", plain_save)
	var unarmored = TeamCombat.new()
	unarmored.setup(["asmodeus"], [], {"asmodeus":plain_sheet}, ["wild_boar"])
	unarmored.use_move("ice_guard")
	_expect(int(unarmored.allies[0]["hp"]) == 55, "Guard takes more damage without equipment and ward")
	_expect(ward_fight.allies[0]["hp"] > unarmored.allies[0]["hp"], "Equipment special effect changes combat damage")

	# The game scene exposes functional inventory from title, sheets and camp.
	var v13_resource: Resource = load("res://scenes/prototype_story_v13.tscn")
	_expect(v13_resource is PackedScene, "Inventory scene must load")
	if v13_resource is PackedScene:
		var inventory_view: Node = (v13_resource as PackedScene).instantiate()
		root.add_child(inventory_view)
		inventory_view.set("party_disable_disk_writes", true)
		var ui_save: Dictionary = SaveStore.new_save()
		ui_save["campaigns"] = {"love_beyond": {
			"opening_parts_completed": 4,
			"progression": {"asmodeus": {"level":1, "xp":9, "hp":60, "max_hp":100, "supplies":2}}
		}}
		inventory_view.set("save_data", ui_save)
		var inventory_title: ScrollContainer = inventory_view.find_child("TitleMenuScroll", true, false) as ScrollContainer
		_expect(inventory_title != null, "Inventory can be opened from scrollable title menu")
		inventory_view.call("_open_inventory")
		_expect(inventory_view.find_child("InventorySlot_0", true, false) != null, "Three item slots visible")
		_expect(inventory_view.find_child("InventorySlot_2", true, false) != null, "Third item slot visible")
		_expect(inventory_view.get("save_data").get("campaigns", {}).get("love_beyond", {}).has("inventory"), "Starter kit is immediately saved as additive data")
		inventory_view.call("_inventory_slot_actions", 0)
		var focus_button: Button = inventory_view.find_child("InventoryEquip_black_ice_focus", true, false) as Button
		_expect(focus_button != null, "Empty slot lists compatible equipment")
		if focus_button != null:
			focus_button.pressed.emit()
		_expect(inventory_view.get("save_data").get("campaigns", {}).get("love_beyond", {}).get("inventory", {}).get("slots", {}).get("asmodeus", [])[0] == "black_ice_focus", "Equip button saves item into character slot")
		inventory_view.call("_inventory_slot_actions", 1)
		var ration_button: Button = inventory_view.find_child("InventoryEquip_travel_rations", true, false) as Button
		_expect(ration_button != null, "Shared backpack offers a consumable for equipping")
		if ration_button != null:
			ration_button.pressed.emit()
		inventory_view.call("_inventory_slot_actions", 1)
		var eat_button: Button = inventory_view.find_child("InventoryConsume", true, false) as Button
		_expect(eat_button != null, "Prepared food has a one-use action")
		if eat_button != null:
			eat_button.pressed.emit()
		_expect(int(inventory_view.get("save_data")["campaigns"]["love_beyond"]["progression"]["asmodeus"]["hp"]) == 80, "Eating food from menu heals saved HP")
		_expect(inventory_view.get("save_data")["campaigns"]["love_beyond"]["inventory"]["slots"]["asmodeus"][1] == "", "Food vanishes from item slot after use")
		inventory_view.call("_show_party_menu", false)
		inventory_view.call("_show_character_sheet", "asmodeus")
		_expect(inventory_view.find_child("CharacterManageItems", true, false) != null, "Character sheet links to equipment menu")
		inventory_view.call("_load_story_if_needed")
		inventory_view.call("_enter_interlude", "after_part_four")
		var day_before: int = int(inventory_view.get("interlude_engine").state.get("actions_left", 0))
		inventory_view.call("_open_inventory", "asmodeus", "daily")
		inventory_view.call("_inventory_slot_actions", 2)
		var bread_button: Button = inventory_view.find_child("InventoryEquip_herbal_bread", true, false) as Button
		_expect(bread_button != null, "Second food type can be equipped in the camp")
		if bread_button != null:
			bread_button.pressed.emit()
		inventory_view.get("interlude_engine").state["hp"] = 38
		inventory_view.call("_inventory_consume", 2)
		_expect(int(inventory_view.get("interlude_engine").state.get("hp", 0)) == 53, "Using food during daily life heals the current interlude, not stale HP")
		_expect(int(inventory_view.get("interlude_engine").state.get("actions_left", 0)) == day_before, "Managing or eating food costs no daily activity")
		_expect(int(inventory_view.get("save_data")["campaigns"]["love_beyond"]["interludes"]["after_part_four"]["hp"]) == 53, "Food healing persists in interlude checkpoint")
		inventory_view.call("_inventory_close")
		_expect(inventory_view.find_child("DailyActivitiesScroll", true, false) != null, "Inventory returns to active camp menu")
		_expect(int(inventory_view.get("save_data")["campaigns"]["love_beyond"]["progression"]["asmodeus"]["xp"]) == 9, "Eating food preserves character XP")

		# Practice battle takes a snapshot; food use in it never consumes
		# the permanently equipped copy or modifies story HP.
		inventory_view.call("_open_inventory", "asmodeus", "daily")
		inventory_view.call("_inventory_slot_actions", 2)
		var more_rations: Button = inventory_view.find_child("InventoryEquip_travel_rations", true, false) as Button
		if more_rations != null:
			more_rations.pressed.emit()
		var pre_practice_save: Dictionary = inventory_view.get("save_data").duplicate(true)
		inventory_view.call("_party_battle_start", "forest_clearing")
		var mock_battle = inventory_view.get("party_battle")
		_expect(str(mock_battle.current_actor().get("id", "")) == "haniel", "Haniel starts before Asmodeus with food")
		inventory_view.call("_party_battle_use", "heal", 0)
		_expect(str(mock_battle.current_actor().get("id", "")) == "asmodeus", "Second ally can use food")
		var use_food_button: Button = inventory_view.find_child("PartyUseFood", true, false) as Button
		_expect(use_food_button != null and not use_food_button.disabled, "Food appears as a battle action when wounded")
		if use_food_button != null:
			use_food_button.pressed.emit()
		var combat_food_slot: Button = inventory_view.find_child("BattleFoodSlot_2", true, false) as Button
		_expect(combat_food_slot != null, "Battle food screen lists actual equipped slot")
		if combat_food_slot != null:
			combat_food_slot.pressed.emit()
		var combat_food_target: Button = inventory_view.find_child("BattleFoodTarget_0", true, false) as Button
		_expect(combat_food_target != null, "Player can select wounded ally for a meal")
		if combat_food_target != null:
			combat_food_target.pressed.emit()
		_expect(mock_battle.allies[0]["items"][2].is_empty(), "Battle food disappears from temporary combat slot")
		_expect(inventory_view.get("save_data") == pre_practice_save, "Practice battle never consumes persistent inventory or changes HP")
		inventory_view.queue_free()


	# Prototype 014: story-gated Cliffside economy & repeatable outlaw events.
	const GoldEconomy = preload("res://scripts/core/economy_engine.gd")
	var market_data: Dictionary = ContentStore.read_dictionary("res://data/shops/cliffside_market.json")
	var outlaw_book: Dictionary = ContentStore.read_dictionary("res://data/encounters/cliffside_outlaws.json")
	_expect(outlaw_book.get("scenarios", {}).get("asmodeus", []).size() >= 4, "Asmodeus has four repeatable Explore scenarios")
	_expect(outlaw_book.get("scenarios", {}).get("haniel", []).size() >= 4, "Haniel has four distinct Patrol scenarios")
	_expect(str(outlaw_book.get("scenarios", {}).get("haniel", [])[0].get("id", "")) != str(outlaw_book.get("scenarios", {}).get("asmodeus", [])[0].get("id", "")), "Haniel has different narrative encounters")
	var defined_enemies: Array = []
	for role in ["asmodeus", "haniel"]:
		for scenario in outlaw_book.get("scenarios", {}).get(role, []):
			_expect(int(scenario.get("gold_min", 0)) > 0 and int(scenario.get("gold_max", 0)) >= int(scenario.get("gold_min", 0)), "Outlaw gold payout is a valid earned range")
			_expect(int(scenario.get("exp", 0)) > 0, "Victory awards real EXP")
			for raw in scenario.get("enemies", []):
				var id := str(raw)
				if not defined_enemies.has(id):
					defined_enemies.append(id)
					_expect(not ContentStore.load_character(id).is_empty(), "Outlaw enemy is present in character JSON: " + id)
	var early_wallet: Dictionary = SaveStore.new_save()
	var early_economy = GoldEconomy.new()
	var early_items = InventorySystem.new()
	early_items.begin(early_wallet, item_catalog)
	early_economy.begin(early_wallet, market_data, item_catalog)
	_expect(not early_economy.market_unlocked(), "Market cannot open before Part Six")
	var blocked_buy: Dictionary = early_economy.buy("grocer", "travel_rations", early_items)
	_expect(not bool(blocked_buy.get("ok", false)), "Early save cannot buy from market even when called directly")
	_expect(early_economy.wallet() == 0, "Gold starts at zero")
	var rich_save: Dictionary = SaveStore.new_save()
	rich_save["campaigns"] = {"love_beyond": {"opening_parts_completed": 6, "progression":{"asmodeus":{"xp":7}}}}
	var merchant_inventory = InventorySystem.new()
	merchant_inventory.begin(rich_save, item_catalog)
	var market_engine = GoldEconomy.new()
	market_engine.begin(rich_save, market_data, item_catalog)
	_expect(market_engine.market_unlocked(), "Part Six unlocks marketplace")
	_expect(market_engine.award_outlaw_gold(33) == 33 and market_engine.wallet() == 33, "Victorious outlaw encounter adds earned gold")
	_expect(not market_engine.buy("outfitter", "iron_charm", merchant_inventory).get("ok", false), "Cannot buy an unaffordable accessory")
	_expect(market_engine.wallet() == 33, "Failed purchases never spend gold")
	var before_qty: int = merchant_inventory.backpack_count("herbal_bread")
	var bought_food: Dictionary = market_engine.buy("grocer", "herbal_bread", merchant_inventory)
	_expect(bool(bought_food.get("ok", false)), "Merchant sells listed food")
	_expect(market_engine.wallet() == 21 and merchant_inventory.backpack_count("herbal_bread") == before_qty + 1, "Purchase transfers item and gold exactly once")
	_expect(not market_engine.buy("grocer", "hammer_grip", merchant_inventory).get("ok", false), "Alric-only smithy gear cannot be bought at general market")
	var sale: Dictionary = market_engine.sell("herbal_bread", merchant_inventory)
	_expect(bool(sale.get("ok", false)) and market_engine.wallet() == 27, "Selling one bread refunds half the item value")
	_expect(merchant_inventory.backpack_count("herbal_bread") == before_qty, "Selling removes exactly one backpack item")
	_expect(not market_engine.sell("not_an_item", merchant_inventory).get("ok", false), "Invalid items cannot be sold for counterfeit gold")
	market_engine.write_to(rich_save)
	merchant_inventory.write_to(rich_save)
	_expect(int(rich_save["campaigns"]["love_beyond"]["progression"]["asmodeus"]["xp"]) == 7, "Buying and selling never changes EXP")
	var market_reloaded = GoldEconomy.new()
	market_reloaded.begin(rich_save, market_data, item_catalog)
	_expect(market_reloaded.wallet() == 27, "Wallet saves and reloads without a reset")
	_expect(int(market_reloaded.state.get("outlaw_victories", 0)) == 1, "Outlaw victories save with the wallet")

	var scene14: Resource = load("res://scenes/prototype_story_v14.tscn")
	_expect(scene14 is PackedScene, "Cliffside free-time scene imports")
	if scene14 is PackedScene:
		var town_view: Node = (scene14 as PackedScene).instantiate()
		root.add_child(town_view)
		town_view.set("party_disable_disk_writes", true)
		var town_save: Dictionary = SaveStore.new_save()
		town_save["campaigns"] = {"love_beyond": {
			"opening_parts_completed": 6, "last_story_event":"end_part_6",
			"progression": {
				"asmodeus":{"level":1, "xp":0, "hp":100, "max_hp":100},
				"haniel":{"level":1, "xp":0, "hp":100, "max_hp":100}
			},
			"party":{"active":["asmodeus","haniel",""]}
		}}
		town_view.set("save_data", town_save)
		town_view.call("_show_menu")
		_expect(town_view.find_child("CliffsideFreeTime", true, false) != null, "Post-six save exposes Cliffside free-time hub")
		_expect(town_view.find_child("OpenCliffsideMarket", true, false) != null, "Post-six save exposes market from title")
		town_view.call("_cliffside_day_selector")
		_expect(town_view.find_child("ChooseCliffsideHaniel", true, false) != null, "Free-time hub offers Haniel POV")
		town_view.call("_enter_cliffside_day", "haniel")
		_expect(bool(town_view.get("interlude_mode")), "Haniel has her own playable day")
		_expect(str(town_view.get("current_interlude_id")) == "cliffside_haniel", "Haniel's independent day state is selected")
		_expect(town_view.find_child("Daily_action_patrol", true, false) != null, "Haniel has Patrol as her Explore equivalent")
		_expect(town_view.find_child("Daily_VisitMarket", true, false) != null, "Daily town screen includes market without an action cost")
		var story_cursor_before: int = int(town_view.get("event_index"))
		town_view.call("_bedtime_question")
		_expect(town_view.find_child("CliffsideOrdinaryTomorrow", true, false) != null, "After Part Six there is an ordinary-day option")
		_expect(town_view.find_child("Daily_VisitMarket", true, false) == null, "Bedtime question is its own screen")
		town_view.call("_ordinary_tomorrow")
		_expect(int(town_view.get("event_index")) == story_cursor_before, "Ordinary day cannot advance after current story finale")
		_expect(not town_view.get("save_data")["campaigns"]["love_beyond"].has("interlude_checkpoint"), "Post-six free time does not invent a story resume checkpoint")
		# Force one available Haniel encounter for a deterministic earned-reward test.
		town_view.call("_outlaw_load")
		town_view.get("outlaw_data")["scenarios"]["haniel"] = [outlaw_book["scenarios"]["haniel"][0]]
		var start_actions: int = int(town_view.get("interlude_engine").state["actions_left"])
		town_view.call("_take_interlude_action", "patrol")
		_expect(bool(town_view.get("live_outlaw_active")), "Patrol starts a real daily bandit fight")
		_expect(int(town_view.get("interlude_engine").state["actions_left"]) == start_actions - 1, "Patrol consumes exactly one daily activity")
		var live_team = town_view.get("party_battle")
		_expect(live_team.enemies.size() == 1 and str(live_team.enemies[0]["id"]) == "bandit_thug", "Haniel's first scenario uses one thug")
		_expect(str(live_team.current_actor()["id"]) == "haniel", "Haniel leads her own patrol")
		town_view.call("_party_battle_use", "divine_arrow", 0)
		_expect(bool(town_view.get("live_outlaw_active")), "Encounter remains live until enemy is defeated")
		town_view.call("_party_battle_use", "black_ice", 0)
		_expect(not bool(town_view.get("live_outlaw_active")), "Victory resolves the daily encounter and returns to town")
		var earned_money: int = int(town_view.get("save_data")["campaigns"]["love_beyond"].get("economy", {}).get("gold", -1))
		_expect(earned_money >= 8 and earned_money <= 15, "Victory pays one bounded outlaw-gold reward")
		_expect(int(town_view.get("save_data")["campaigns"]["love_beyond"]["progression"]["haniel"]["xp"]) == 12, "Patrol victory earns Haniel EXP")
		_expect(town_view.find_child("Daily_action_patrol", true, false) != null, "After a fight, player returns to Haniel's daily routine")
		_expect(not town_view.get("save_data")["campaigns"]["love_beyond"].has("interlude_checkpoint"), "Resolving a patrol never changes the story cursor checkpoint")
		var money_once := earned_money
		town_view.call("_finish_outlaw_encounter", false)
		_expect(int(town_view.get("save_data")["campaigns"]["love_beyond"]["economy"]["gold"]) == money_once, "Completed encounter reward cannot be claimed twice")
		town_view.call("_open_market", "daily")
		_expect(town_view.find_child("MarketMerchant_grocer", true, false) != null, "Live market screen lists provisioner")
		town_view.call("_market_buy_menu", "grocer")
		_expect(town_view.find_child("MarketBuy_herbal_bread", true, false) != null, "Market lists priced food items")
		town_view.call("_market_close")
		_expect(town_view.find_child("Daily_action_patrol", true, false) != null, "Leaving market returns to same daily routine")
		town_view.call("_enter_cliffside_day", "asmodeus")
		_expect(town_view.find_child("Daily_action_explore", true, false) != null, "Asmodeus has Explore in his post-six free time")
		_expect(town_view.find_child("Daily_SwitchPOV", true, false) != null, "Player can switch free-time POV without forcing narrative")
		_expect(town_view.get("save_data")["campaigns"]["love_beyond"]["interludes"].has("cliffside_haniel"), "Haniel day progress survives switching back to Asmodeus")
		town_view.get("outlaw_data")["scenarios"]["asmodeus"] = [outlaw_book["scenarios"]["asmodeus"][0]]
		var gold_before_retreat: int = int(town_view.get("save_data")["campaigns"]["love_beyond"]["economy"]["gold"])
		var asmo_actions: int = int(town_view.get("interlude_engine").state["actions_left"])
		town_view.call("_take_interlude_action", "explore")
		_expect(town_view.get("party_battle").enemies.size() == 2, "Asmodeus Explore scenario can pit team against two outlaws")
		_expect(int(town_view.get("interlude_engine").state["actions_left"]) == asmo_actions - 1, "Explore encounter spends one action")
		town_view.call("_retreat_outlaw")
		_expect(not bool(town_view.get("live_outlaw_active")), "Retreat exits real encounter")
		_expect(int(town_view.get("save_data")["campaigns"]["love_beyond"]["economy"]["gold"]) == gold_before_retreat, "Retreat earns no gold")
		_expect(int(town_view.get("save_data")["campaigns"]["love_beyond"]["progression"]["asmodeus"]["xp"]) == 0, "Retreat gives no EXP")
		_expect(int(town_view.get("event_index")) == story_cursor_before, "Neither POV can advance authored story events")
		# In a *real* encounter, eaten food is permanently removed from the
		# save even on retreat, unlike the isolated practice battle.
		town_view.call("_party_load")
		town_view.call("_inventory_load")
		var real_inv = town_view.get("inventory_engine")
		var real_party = town_view.get("party_engine")
		_expect(real_inv.equip("asmodeus", 0, "travel_rations", real_party.unlocked), "Real encounter test can equip food")
		real_inv.write_to(town_view.get("save_data"))
		town_view.get("interlude_engine").state["hp"] = 55
		town_view.call("_save_interlude")
		town_view.call("_take_interlude_action", "explore")
		var daily_team = town_view.get("party_battle")
		_expect(daily_team != null and str(daily_team.current_actor().get("id", "")) == "haniel", "Daily battle begins with the faster ally")
		town_view.call("_party_battle_use", "heal", 0)
		_expect(str(daily_team.current_actor().get("id", "")) == "asmodeus", "Asmodeus can now use the readied meal")
		_expect(daily_team.food_targets(0).has(0), "Actual daily battle has a wounded food target")
		town_view.call("_party_battle_use_food", 0, 0)
		var eaten_slots: Array = town_view.get("save_data")["campaigns"]["love_beyond"]["inventory"]["slots"]["asmodeus"]
		_expect(str(eaten_slots[0]) == "", "Eating food in real daily battle clears saved item slot immediately")
		_expect(int(town_view.get("save_data")["campaigns"]["love_beyond"]["inventory"]["backpack"]["travel_rations"]) == 2, "Real encounter food was not returned or duplicated")
		var gold_after_food: int = int(town_view.get("save_data")["campaigns"]["love_beyond"]["economy"]["gold"])
		town_view.call("_retreat_outlaw")
		_expect(int(town_view.get("save_data")["campaigns"]["love_beyond"]["economy"]["gold"]) == gold_after_food, "Retreat after eating never pays additional gold")
		_expect(int(town_view.get("event_index")) == story_cursor_before, "Using food and retreating never changes story position")

		town_view.queue_free()


	# Prototype 015 — real top-level campaign selector, reusable hierarchy,
	# disabled Blades placeholder, title theme and old Love Beyond features.
	var campaign_register: Dictionary = ContentStore.read_dictionary("res://data/campaigns/registry.json")
	var known_campaigns: Array = campaign_register.get("campaigns", [])
	_expect(known_campaigns.size() == 2, "Campaign registry starts with two properly named campaigns")
	_expect(str(known_campaigns[0].get("title", "")) == "Love Beyond Heaven or Hell", "Love Beyond campaign title matches the requested label")
	_expect(str(known_campaigns[1].get("title", "")) == "Blades of Courage and Ferocity", "Blades has its own campaign entry")
	_expect(str(known_campaigns[1].get("status", "")) == "coming_soon", "Blades is coming soon rather than playable")
	var campaign_scene: Resource = load("res://scenes/prototype_story_v15.tscn")
	_expect(campaign_scene is PackedScene, "Polished campaign selector scene imports")
	if campaign_scene is PackedScene:
		var hub: Node = (campaign_scene as PackedScene).instantiate()
		root.add_child(hub)
		hub.set("party_disable_disk_writes", true)
		var empty_campaign_save: Dictionary = SaveStore.new_save()
		hub.set("save_data", empty_campaign_save)
		hub.call("_show_menu")
		var entry_love: Button = hub.find_child("CampaignChoice_love_beyond", true, false) as Button
		var entry_blades: Button = hub.find_child("CampaignChoice_blades", true, false) as Button
		_expect(entry_love != null and not entry_love.disabled, "Love Beyond campaign can be opened")
		_expect(entry_blades != null and entry_blades.disabled, "Blades choice is visibly present but not clickable")
		_expect(hub.find_child("CampaignMenuScroll", true, false) != null, "Campaign selector handles smaller displays with scrolling")
		_expect(hub.find_child("TitleMenuScroll", true, false) == null, "Legacy 14-button menu no longer clutters the title")
		_expect(hub.find_child("OpenCliffsideMarket", true, false) == null, "Market entry isn't dumped onto the title screen")
		_expect(entry_love.get_theme_stylebox("normal") is StyleBoxFlat, "Campaign buttons have themed backgrounds and trim")
		var before_blades: Dictionary = hub.get("save_data").duplicate(true)
		hub.call("_open_campaign", "blades")
		_expect(str(hub.get("selected_campaign")) == "", "Blades cannot be selected through code or UI")
		_expect(hub.get("save_data") == before_blades, "Coming Soon campaign never creates or changes any save")
		_expect(hub.find_child("CampaignChoice_blades", true, false) != null, "Denied Blades selection leaves campaign menu visible")
		if entry_love != null:
			entry_love.pressed.emit()
		_expect(str(hub.get("selected_campaign")) == "love_beyond", "Playable campaign enters Love Beyond")
		var love_begin: Button = hub.find_child("LoveBegin", true, false) as Button
		var love_continue: Button = hub.find_child("LoveContinue", true, false) as Button
		_expect(love_begin != null, "Story is reachable inside Love Beyond")
		_expect(love_continue != null and love_continue.disabled, "No Continue action when no save checkpoint exists")
		_expect(hub.find_child("LoveAdventure", true, false) != null, "Love Beyond includes an Adventure submenu")
		_expect(hub.find_child("LoveExtras", true, false) != null, "Love Beyond includes an Extras submenu")
		hub.call("_show_love_adventure")
		_expect(hub.find_child("LoveParty", true, false) != null, "Party menu remains reachable")
		_expect(hub.find_child("LoveInventory", true, false) != null, "Shared backpack remains reachable")
		var locked_cliffside: Button = hub.find_child("LoveCliffside", true, false) as Button
		var locked_market: Button = hub.find_child("LoveMarket", true, false) as Button
		_expect(locked_cliffside != null and locked_cliffside.disabled, "Cliffside free time is locked before Part Six")
		_expect(locked_market != null and locked_market.disabled, "Market is locked before Part Six")
		hub.call("_open_party_from_love")
		_expect(hub.find_child("PartySlot_0", true, false) != null, "Existing party editing UI opens from campaign adventure")
		hub.call("_close_party_menu")
		_expect(hub.find_child("LoveParty", true, false) != null, "Back from party returns to Love Beyond Adventure, not the title")
		hub.call("_open_inventory_from_love")
		_expect(hub.find_child("InventorySlot_2", true, false) != null, "Existing 3-slot item system opens from campaign adventure")
		hub.call("_inventory_close")
		_expect(hub.find_child("LoveInventory", true, false) != null, "Back from inventory returns to Adventure")
		hub.call("_show_love_extras")
		_expect(hub.find_child("LoveBattlePractice", true, false) != null, "Full party combat practice stays under Extras")
		_expect(hub.find_child("LoveQuickDuel", true, false) != null, "Original tutorial duel stays under Extras")
		_expect(hub.find_child("LoveLocationGallery", true, false) != null, "Area gallery stays under Extras")
		_expect(hub.find_child("LoveSpriteGallery", true, false) != null, "Sprite gallery stays under Extras")
		var mature_campaign_save: Dictionary = SaveStore.new_save()
		mature_campaign_save["campaigns"] = {"love_beyond": {"opening_parts_completed":6,
			"interlude_checkpoint":{"id":"after_part_five", "event_index":30}}}
		hub.set("save_data", mature_campaign_save)
		hub.call("_show_love_campaign")
		love_continue = hub.find_child("LoveContinue", true, false) as Button
		_expect(love_continue != null and not love_continue.disabled, "Existing resumable save enables Continue inside Love Beyond")
		hub.call("_show_love_adventure")
		locked_market = hub.find_child("LoveMarket", true, false) as Button
		locked_cliffside = hub.find_child("LoveCliffside", true, false) as Button
		_expect(locked_market != null and not locked_market.disabled, "Market appears in adventure after Part Six")
		_expect(locked_cliffside != null and not locked_cliffside.disabled, "Cliffside free time appears after Part Six")
		hub.call("_open_market", "love_adventure")
		_expect(hub.find_child("MarketMerchant_grocer", true, false) != null, "General market still works behind new campaign menu")
		hub.call("_market_close")
		_expect(hub.find_child("LoveMarket", true, false) != null, "Back from market returns to Love Beyond adventure")
		hub.call("_show_menu")
		_expect(hub.find_child("CampaignChoice_blades", true, false) != null, "Back to title returns to campaign selection")
		_expect(not hub.get("save_data").get("campaigns", {}).has("blades"), "No empty Blades save slot is ever initialized")
		hub.queue_free()


	# Prototype 016 — battle layout inspired by the supplied JRPG reference,
	# compact sided HP, working command tabs, targeting, and title bar cleanup.
	var jrpg_scene: Resource = load("res://scenes/prototype_story_v16.tscn")
	_expect(jrpg_scene is PackedScene, "JRPG combat UI scene imports")
	if jrpg_scene is PackedScene:
		var jrpg: Node = (jrpg_scene as PackedScene).instantiate()
		root.add_child(jrpg)
		jrpg.set("party_disable_disk_writes", true)
		var jrpg_save: Dictionary = SaveStore.new_save()
		jrpg_save["campaigns"] = {"love_beyond": {
			"opening_parts_completed":6,
			"party":{"active":["asmodeus","haniel","alric"]},
			"training":{"asmodeus":{"learned":["black_ice_lance"],"points":0}},
			"inventory":{"starter_granted":true,
				"backpack":{"travel_rations":2},
				"slots":{"haniel":["herbal_bread","",""],"asmodeus":["","",""],"alric":["","",""]}}
		}}
		jrpg.set("save_data", jrpg_save)
		jrpg.call("_show_menu")
		var old_panel: Control = jrpg.call("_legacy_dialogue_frame")
		_expect(old_panel != null and not old_panel.visible, "Empty legacy dialogue panel is hidden on campaign select")
		_expect(jrpg.find_child("CampaignChoice_love_beyond", true, false) != null, "Campaign art menu remains interactive")
		jrpg.call("_start_dialogue")
		_expect(old_panel != null and old_panel.visible, "Legacy dialogue frame reappears when beginning the story")
		jrpg.call("_show_menu")
		_expect(old_panel != null and not old_panel.visible, "Returning to campaign select hides black dialogue bar again")

		var before_practice: Dictionary = jrpg.get("save_data").duplicate(true)
		jrpg.call("_party_battle_start", "forest_clearing")
		var live_ui = jrpg.get("party_battle")
		_expect(live_ui != null and live_ui.allies.size() == 3, "JRPG battle uses three saved party members")
		var enemy_wing: VBoxContainer = jrpg.find_child("EnemyWing", true, false) as VBoxContainer
		var ally_wing: VBoxContainer = jrpg.find_child("AllyWing", true, false) as VBoxContainer
		_expect(enemy_wing != null and ally_wing != null, "Compact HP wings appear on respective sides of the field")
		var mini_enemy_hp: ProgressBar = jrpg.find_child("EnemyHpMini", true, false) as ProgressBar
		_expect(mini_enemy_hp != null and mini_enemy_hp.custom_minimum_size.x <= 160, "Ordinary enemy bars are compact, not giant boss bars")
		_expect(jrpg.find_child("BattlePartyStatus", true, false) != null, "Lower JRPG status strip shows the player party")
		_expect(jrpg.find_child("CombatCommandDock", true, false) != null, "Command dock anchors battle action controls")
		_expect(jrpg.find_child("CombatTab_attack", true, false) != null, "Battle includes Attack category")
		_expect(jrpg.find_child("CombatTab_skills", true, false) != null, "Battle includes Skills category")
		_expect(jrpg.find_child("CombatTab_items", true, false) != null, "Battle includes Items category")
		_expect(jrpg.find_child("CombatTab_guard", true, false) != null, "Battle includes Guard category")
		_expect(jrpg.find_child("CombatTab_switch", true, false) != null, "Battle includes Switch category")
		var no_reserve: Button = jrpg.find_child("CombatTab_switch", true, false) as Button
		_expect(no_reserve != null and no_reserve.disabled, "Switch category disables with no reserve")
		var current_before_tabs: String = str(live_ui.current_actor().get("id", ""))
		jrpg.call("_set_combat_tab", "attack")
		_expect(jrpg.find_child("CombatAction_Attack_attack", true, false) != null, "Attack tab shows basic action")
		jrpg.call("_set_combat_tab", "items")
		var food_action: Button = jrpg.find_child("CombatAction_Item_0", true, false) as Button
		_expect(food_action != null and food_action.disabled, "Food is visible but disabled while nobody is wounded")
		_expect(str(live_ui.current_actor().get("id", "")) == current_before_tabs, "Changing tabs costs no turns")
		jrpg.call("_set_combat_tab", "skills")
		_expect(jrpg.find_child("CombatAction_Skill_divine_arrow", true, false) != null, "Skills lists Haniel's Divine Arrow")
		jrpg.call("_party_battle_pick_target", "divine_arrow")
		_expect(jrpg.find_child("CombatTargetChoices", true, false) != null, "Target mode has its own compact action area")
		_expect(jrpg.find_child("TargetReticle_1", true, false) != null, "Enemy targeting shows a diamond reticle")
		_expect(jrpg.find_child("PartyTarget_Enemy_1", true, false) != null, "Player may select the second enemy")
		jrpg.call("_party_battle_use", "divine_arrow", 1)
		_expect(str(live_ui.current_actor().get("id", "")) == "asmodeus", "Using a skill advances to the next fighter")
		_expect(jrpg.find_child("CombatAction_Skill_black_ice_lance", true, false) != null, "Learned Black Ice Lance appears under Skills")
		jrpg.call("_set_combat_tab", "guard")
		_expect(jrpg.find_child("CombatAction_Guard_ice_guard", true, false) != null, "Asmodeus's Ice Guard appears under Guard")
		jrpg.call("_set_combat_tab", "attack")
		jrpg.call("_party_battle_pick_target", "attack")
		jrpg.call("_party_battle_use", "attack", 0)
		_expect(jrpg.get("save_data") == before_practice, "All JRPG practice tabs and moves preserve save isolation")
		jrpg.call("_show_menu")
		_expect(jrpg.find_child("CampaignChoice_blades", true, false) != null, "Exiting practice returns to campaign hub")
		_expect(old_panel != null and not old_panel.visible, "No black title bar after practice battle")
		jrpg.queue_free()


	# Prototype 017 — author-curated story illustrations for Parts 1–5.
	# Part Six has no supplied artwork and must retain its original images.
	var first_parts: Dictionary = ContentStore.read_dictionary("res://data/chapters/love_beyond_opening_story.json")
	var later_parts: Dictionary = ContentStore.read_dictionary("res://data/chapters/love_beyond_parts_4_6.json")
	var first_events: Array = first_parts.get("events", [])
	var later_events: Array = later_parts.get("events", [])
	var curated_paths: Array[String] = []
	var curated_count := 0
	for section in [first_events, later_events]:
		for raw_event in section:
			var art_event: Dictionary = raw_event
			var art_path := str(art_event.get("curated_image", ""))
			if art_path == "":
				continue
			curated_count += 1
			if not curated_paths.has(art_path):
				curated_paths.append(art_path)
			_expect(art_path.begins_with("part_0"), "Curated chapter path is relative to art pack")
			_expect(art_path.ends_with(".webp"), "Curated chapter images are optimized WebP")
			_expect(not art_path.contains(".."), "Curated chapter art paths cannot escape their folder")
	_expect(curated_paths.size() == 22, "Exactly 22 supplied images from Parts One through Five are mapped")
	_expect(curated_count >= 22, "Every supplied chapter image is attached to a story moment")
	_expect(str(first_events[0].get("curated_image", "")) == "part_01/01_cave_truce.webp", "Chapter One begins with the new cave truce picture")
	_expect(str(first_events[21].get("curated_image", "")) == "part_02/01_gather_branches.webp", "Chapter Two uses the forest branch gathering art")
	_expect(str(first_events[60].get("curated_image", "")) == "part_03/02_bear_confrontation.webp", "Author's second bear image marks boss fight")
	_expect(str(first_events[65].get("curated_image", "")) == "part_03/03_haniel_rescue.webp", "Author's third bear image follows fight for Haniel's rescue")
	_expect(str(first_events[71].get("curated_image", "")) == "part_03/04_bear_aftermath.webp", "Author's fourth bear image covers the aftermath")
	_expect(str(later_events[1].get("curated_image", "")) == "part_04/01_cave_care.webp", "Chapter Four starts in the recovery cave")
	_expect(str(later_events[23].get("curated_image", "")) == "part_05/01_hiderack.webp", "Chapter Five opens at the hide-drying rack")
	for part_six_index in range(40, later_events.size()):
		_expect(not later_events[part_six_index].has("curated_image"), "Part Six event %d retains its original artwork" % part_six_index)
	_expect(str(later_events[40].get("image", "")) == "cliffside_street.jpg", "Part Six title keeps existing Cliffside street art")
	_expect(str(later_events[52].get("image", "")) == "cliffside_alley.jpg", "Part Six alley remains unchanged")
	_expect(str(later_events[66].get("image", "")) == "cliffside_alley.jpg", "Part Six first story fight is untouched")
	_expect(str(later_events[73].get("image", "")) == "cliffside_alley_2.jpg", "Part Six second story fight is untouched")
	var illustrated_scene: Resource = load("res://scenes/prototype_story_v17.tscn")
	_expect(illustrated_scene is PackedScene, "Curated chapter scene must load")
	if illustrated_scene is PackedScene:
		var curated_view: Node = (illustrated_scene as PackedScene).instantiate()
		root.add_child(curated_view)
		curated_view.set("party_disable_disk_writes", true)
		curated_view.call("_load_story_if_needed")
		_expect(curated_view.get("story_events").size() == first_events.size() + later_events.size(), "All chapters including the unchanged Part Six still load")
		_expect(str(curated_view.call("_curated_image_for", 0)) == "part_01/01_cave_truce.webp", "Curated art resolver finds Part One title image")
		_expect(str(curated_view.call("_curated_image_for", 6)) == "part_01/05_haniel_closeup.webp", "Illustration is retained between dialogue lines")
		_expect(str(curated_view.call("_curated_image_for", 53)) == "part_03/02_bear_confrontation.webp", "Story changes to the author-supplied bear confrontation")
		_expect(str(curated_view.call("_curated_image_for", first_events.size() + 23)) == "part_05/01_hiderack.webp", "Merged Part Five image resolves correctly after Part Four interlude")
		_expect(str(curated_view.call("_curated_image_for", first_events.size() + 40)) == "", "Part Six title resets curated imagery to original art")
		_expect(str(curated_view.call("_curated_image_for", first_events.size() + 61)) == "", "Part Six never accidentally inherits an image from Part Five")
		curated_view.queue_free()


	# Prototype 018: named user portraits, scene-accurate speaker aliases,
	# resumable expression state and on-field opposing battlers.
	var portrait_catalog: Dictionary = ContentStore.read_dictionary("res://data/portraits/love_beyond.json")
	var portrait_characters: Dictionary = portrait_catalog.get("characters", {})
	_expect(portrait_characters.size() == 4, "Portrait registry contains the four provided characters")
	for portrait_id in ["asmodeus", "haniel", "alric", "joren"]:
		var definition: Dictionary = portrait_characters.get(portrait_id, {})
		_expect(definition.get("expressions", {}).size() == 4, "Exactly four user-named expressions available for " + portrait_id)
	_expect(portrait_characters.get("joren", {}).get("expressions", {}).has("villainsmirk"), "Joren's distinctive expression name remains untouched")
	_expect(portrait_characters.get("joren", {}).get("default", "") == "sheepish", "Joren uses his supplied sheepish image when a neutral portrait isn't present")
	_expect(portrait_characters.get("haniel", {}).get("aliases", []).has("HANIEL [SIGNING]"), "Signing is recognized as Haniel")
	var story_with_portraits: Dictionary = ContentStore.read_dictionary("res://data/chapters/love_beyond_opening_story.json")
	var story_with_portraits_later: Dictionary = ContentStore.read_dictionary("res://data/chapters/love_beyond_parts_4_6.json")
	_expect(str(story_with_portraits.get("events", [])[2].get("portrait_expression", "")) == "smile", "Cave dialogue selects Asmodeus's smile")
	_expect(str(story_with_portraits_later.get("events", [])[48].get("portrait_expression", "")) == "villainsmirk", "Joren starts with his assigned sly portrait")
	_expect(str(story_with_portraits_later.get("events", [])[59].get("portrait_expression", "")) == "angry", "Alric's alley dialogue selects his angry portrait")

	var portrait_scene: Resource = load("res://scenes/prototype_story_v18.tscn")
	_expect(portrait_scene is PackedScene, "Prototype 018 portrait/facing combat scene imports")
	if portrait_scene is PackedScene:
		var portrait_view: Node = (portrait_scene as PackedScene).instantiate()
		root.add_child(portrait_view)
		portrait_view.set("party_disable_disk_writes", true)
		_expect(portrait_view.find_child("DialoguePortraitLayer", true, false) != null, "Portraits have a separate dialogue overlay")
		_expect(portrait_view.find_child("LeftSpeakingPortrait", true, false) != null, "Left speaker has an independent transparent picture")
		_expect(portrait_view.find_child("RightSpeakingPortrait", true, false) != null, "Right speaker has an independent transparent picture")
		_expect(portrait_view.call("_portrait_speaker_id", "HANIEL [SIGNING]") == "haniel", "Signing lines brighten Haniel, not narrator")
		_expect(portrait_view.call("_portrait_speaker_id", "BLOND YOUTH") == "joren", "Youth alias displays Joren without changing authored name")
		_expect(portrait_view.call("_portrait_speaker_id", "GANG LEADER") == "", "Unprovided thug portrait is not invented")
		_expect(str(portrait_view.call("_portrait_resource", "joren", "villainsmirk")).ends_with("joren/villainsmirk.webp"), "Portrait lookup references optimized pack by expression")
		_expect(str(portrait_view.call("_portrait_resource", "haniel", "unknown")).ends_with("haniel/neutral.webp"), "Missing expression gracefully uses supplied default")
		portrait_view.call("_load_story_if_needed")
		var first_count: int = story_with_portraits.get("events", []).size()
		var smile_state: Dictionary = portrait_view.call("_portrait_state_at", 2)
		_expect(smile_state.get("active") == "asmodeus" and smile_state.get("expressions", {}).get("asmodeus") == "smile", "Resumable Part One cave scene highlights the right speaker and expression")
		var signed_state: Dictionary = portrait_view.call("_portrait_state_at", first_count + 4)
		_expect(signed_state.get("active") == "haniel", "A signed Part Four line activates Haniel's portrait")
		var youth_state: Dictionary = portrait_view.call("_portrait_state_at", first_count + 48)
		_expect(youth_state.get("right") == "joren" and youth_state.get("expressions", {}).get("joren") == "villainsmirk", "Part Six shows Joren only after his introduction")
		var alric_state: Dictionary = portrait_view.call("_portrait_state_at", first_count + 59)
		_expect(alric_state.get("left") == "alric" and alric_state.get("right") == "haniel", "Alric appears opposite Haniel when intervening in the alley")
		var early_six: Dictionary = portrait_view.call("_portrait_state_at", first_count + 40)
		_expect(early_six.get("left") == "asmodeus" and early_six.get("right") == "haniel", "Part Six resets the on-screen cast without changing chapter art")
		portrait_view.call("_show_menu")
		var overlay: Control = portrait_view.find_child("DialoguePortraitLayer", true, false) as Control
		_expect(overlay != null and not overlay.visible, "Portraits don't cover the title/campaign selector")
		# The early prototype's big face cards must not overlap our newer
		# full-height speaking portraits during the intro.
		var old_face_row: HBoxContainer = portrait_view.get("portraits") as HBoxContainer
		portrait_view.call("_start_dialogue")
		_expect(old_face_row != null and not old_face_row.visible,
			"Old face boxes are hidden when the opening dialogue starts")
		_expect(str(portrait_view.get("last_portrait_speaker")) == "asmodeus",
			"The opening Asmodeus line still selects his new transparent portrait")
		portrait_view.call("_advance_dialogue")
		_expect(old_face_row != null and not old_face_row.visible,
			"Legacy portrait boxes remain hidden when the speaker changes")
		_expect(str(portrait_view.get("last_portrait_speaker")) == "haniel",
			"Haniel's next line still selects her new transparent portrait")
		portrait_view.call("_choose_fighter")
		_expect(old_face_row != null and not old_face_row.visible,
			"Fighter selection does not expose the duplicate legacy face row")
		portrait_view.get("frontend").hide()
		portrait_view.call("_start_battle", "Asmodeus", "Haniel")
		_expect(old_face_row != null and old_face_row.visible,
			"The opening duel still has its functional HP cards and visual effect anchors")
		portrait_view.call("_show_menu")
		portrait_view.set("story_mode", true)
		portrait_view.set("event_index", 2)
		portrait_view.call("_show_event")
		_expect(str(portrait_view.get("last_portrait_speaker")) == "asmodeus", "Dialogue renderer identifies active Asmodeus on line 2")
		portrait_view.call("_show_menu")
		_expect(not overlay.visible, "Returning to menu hides speaking characters safely")

		var portrait_test_save: Dictionary = SaveStore.new_save()
		portrait_test_save["campaigns"] = {"love_beyond": {
			"opening_parts_completed":6,
			"party":{"active":["asmodeus","haniel","alric"]},
			"training":{"asmodeus":{"learned":["black_ice_lance"],"points":0}}
		}}
		portrait_view.set("save_data", portrait_test_save)
		var before_practice: Dictionary = portrait_test_save.duplicate(true)
		portrait_view.call("_party_battle_start", "forest_clearing")
		_expect(portrait_view.find_child("BattlefieldStage", true, false) != null, "Battle scene now has a dedicated opposing-sprites stage")
		_expect(portrait_view.find_child("FacingBattlers", true, false) != null, "Battler sprite layer exists above environment")
		var enemy_battler: PanelContainer = portrait_view.find_child("EnemyBattler_0", true, false) as PanelContainer
		var ally_battler: PanelContainer = portrait_view.find_child("AllyBattler_0", true, false) as PanelContainer
		_expect(enemy_battler != null and ally_battler != null, "Enemy and ally have distinct on-field sprite frames")
		if enemy_battler != null and ally_battler != null:
			_expect(enemy_battler.position.x < ally_battler.position.x, "Enemies are on the left and allies face them from the right")
			_expect(enemy_battler.find_child("BattlerSprite_", true, false) == null, "Battler identities use named actual sprite IDs")
			var enemy_image: TextureRect = enemy_battler.find_child("BattlerSprite_wild_boar", true, false) as TextureRect
			var ally_image: TextureRect = ally_battler.find_child("BattlerSprite_asmodeus", true, false) as TextureRect
			_expect(enemy_image != null and not enemy_image.flip_h, "Enemies face the party")
			_expect(ally_image != null and ally_image.flip_h, "Allied sprites face toward opponents")
		_expect(portrait_view.find_child("EnemyWing", true, false) != null, "Enemy HP information stays on enemy's side")
		_expect(portrait_view.find_child("AllyWing", true, false) != null, "Ally HP information stays on party's side")
		_expect(portrait_view.find_child("EnemyHpMini", true, false) != null, "Nonboss enemy bars remain small")
		_expect(portrait_view.find_child("BattlePartyStatus", true, false) != null, "Three-party bottom HP strip remains")
		_expect(portrait_view.find_child("CombatCommandDock", true, false) != null, "Attack/skill/item JRPG commands remain functional")
		portrait_view.call("_party_battle_pick_target", "divine_arrow")
		_expect(portrait_view.find_child("FieldTarget_0", true, false) != null, "Enemy sprites are marked with a visual target diamond")
		_expect(portrait_view.find_child("PartyTarget_Enemy_1", true, false) != null, "Player still has two legal enemy target buttons")
		portrait_view.call("_party_battle_use", "divine_arrow", 1)
		_expect(portrait_view.get("save_data") == before_practice, "New sprite arrangement doesn't change combat saves")
		portrait_view.queue_free()


	# Art installation hotfix: verify nested ZIP discovery, raw-file loading
	# before import, and an in-game status screen rather than a silent fallback.
	const ArtLoader = preload("res://scripts/core/optional_art_loader.gd")
	_expect(ArtLoader.resolve("assets/love_beyond/dialogue_portraits/unknown/nope.webp") == "",
		"Absent optional artwork has an explicit empty-path result")
	_expect(ArtLoader.resolve("../outside.png") == "",
		"Optional art loader blocks parent directory traversal")
	_expect(ArtLoader.texture("assets/love_beyond/dialogue_portraits/unknown/nope.webp") == null,
		"Unavailable optional textures fail safely without stopping gameplay")
	var installed_example := ArtLoader.resolve("assets/love_beyond/pixel_battles/haniel.png")
	_expect(installed_example != "", "Optional loader discovers an existing repo image at its canonical path")
	_expect(ArtLoader.texture("assets/love_beyond/pixel_battles/haniel.png") != null,
		"Optional loader can actually decode real PNG images")
	# Emulate the Windows ZIP extraction mistake: new WebP files land in
	# a one-level subfolder AFTER Godot has imported the project.
	var raw_test_root := "res://Paleverse_Test_Extracted_Art/assets/love_beyond/"
	var fake_chapter := raw_test_root + "curated_chapters/part_01/01_cave_truce.webp"
	var fake_portrait := raw_test_root + "dialogue_portraits/haniel/neutral.webp"
	var raw_image := Image.create(18, 22, false, Image.FORMAT_RGBA8)
	raw_image.fill(Color(0.85, 0.30, 0.57, 0.90))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
		raw_test_root + "curated_chapters/part_01"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
		raw_test_root + "dialogue_portraits/haniel"))
	_expect(raw_image.save_webp(fake_chapter) == OK, "Test fixture can produce real WebP chapter image")
	_expect(raw_image.save_webp(fake_portrait) == OK, "Test fixture can produce real transparent WebP speaker image")
	_expect(ArtLoader.resolve("assets/love_beyond/curated_chapters/part_01/01_cave_truce.webp") != "",
		"Nested Windows Extract All chapter asset is discovered")
	_expect(ArtLoader.texture("assets/love_beyond/curated_chapters/part_01/01_cave_truce.webp") != null,
		"New unimported WebP chapter image is decoded correctly")
	_expect(ArtLoader.texture("assets/love_beyond/dialogue_portraits/haniel/neutral.webp") != null,
		"New unimported WebP portrait image is decoded correctly")
	var hotfix_resource: Resource = load("res://scenes/prototype_story_v18.tscn")
	if hotfix_resource is PackedScene:
		var repaired_view: Node = (hotfix_resource as PackedScene).instantiate()
		root.add_child(repaired_view)
		repaired_view.set("party_disable_disk_writes", true)
		repaired_view.call("_show_love_extras")
		_expect(repaired_view.find_child("LoveArtCheck", true, false) != null,
			"Story & portrait Art Check is accessible under Love Beyond Extras")
		repaired_view.call("_show_art_check")
		_expect(repaired_view.find_child("CampaignPageTitle", true, false) != null,
			"Art Check displays an instructional panel")
		var art_stats: Dictionary = repaired_view.call("_art_counts")
		_expect(int(art_stats.get("chapters_total", 0)) == 22,
			"Art Check knows all 22 optional curated backgrounds")
		_expect(int(art_stats.get("portraits_total", 0)) == 16,
			"Art Check knows all 16 speaking portraits")
		_expect(int(art_stats.get("chapters_found", 0)) >= 1 and
			int(art_stats.get("portraits_found", 0)) >= 1,
			"Art Check counts actual WebP assets discovered in the extracted folder")
		_expect(repaired_view.find_child("ArtCheckChapterPreview", true, false) != null,
			"Art Check renders a real chapter image preview")
		_expect(repaired_view.find_child("ArtCheckPortraitPreview", true, false) != null,
			"Art Check renders a real portrait image preview")
		_expect(repaired_view.call("_display_curated_image", "part_01/01_cave_truce.webp"),
			"Live chapter renderer displays freshly copied WebP art")
		repaired_view.call("_present_speakers", "asmodeus", "haniel",
			{"asmodeus":"neutral", "haniel":"neutral"}, "haniel")
		var loaded_speaker: TextureRect = repaired_view.find_child("RightSpeakingPortrait", true, false) as TextureRect
		_expect(loaded_speaker != null and loaded_speaker.texture != null and loaded_speaker.visible,
			"Speaking portrait is visibly rendered from the freshly extracted image")
		repaired_view.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fake_chapter))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fake_portrait))

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

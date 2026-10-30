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
						_expect(int(daily.state["level"]) > 1 or int(daily.state["xp"]) > 0, "Successful hunt grants experience")
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

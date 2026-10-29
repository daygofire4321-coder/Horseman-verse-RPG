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

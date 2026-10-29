extends SceneTree
## Manual headless smoke test: godot --headless --path . --script res://tests/smoke_test.gd

const ContentStore = preload("res://scripts/core/content_store.gd")
const DuelEngine = preload("res://scripts/core/duel_engine.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var chapter: Dictionary = ContentStore.load_chapter("love_beyond_prototype_001")
	var haniel: Dictionary = ContentStore.load_character("haniel")
	var asmodeus: Dictionary = ContentStore.load_character("asmodeus")
	assert(chapter.get("dialogue", []).size() >= 2, "Chapter dialogue must load")
	assert(haniel.get("id", "") == "haniel")
	assert(asmodeus.get("id", "") == "asmodeus")

	var duel = DuelEngine.new()
	duel.setup(haniel, asmodeus)
	assert(duel.player_moves().size() == 3)
	var outcome: Dictionary = duel.take_turn("divine_arrow")
	assert(outcome["enemy_hp"] == 77)
	assert(outcome["player_hp"] == 83)

	duel.setup(asmodeus, haniel)
	outcome = duel.take_turn("ice_guard")
	assert(outcome["player_hp"] == 94, "Guard should reduce the next hit")

	duel.setup(haniel, asmodeus)
	var victory := false
	for round_index in range(10):
		outcome = duel.take_turn("divine_arrow")
		if outcome["finished"]:
			victory = bool(outcome["victory"])
			break
	assert(victory, "Haniel should be able to win")

	duel.setup(asmodeus, haniel)
	victory = false
	for round_index in range(10):
		outcome = duel.take_turn("black_ice")
		if outcome["finished"]:
			victory = bool(outcome["victory"])
			break
	assert(victory, "Asmodeus should be able to win")

	print("Paleverse smoke tests passed: content, abilities, AI, and both playable sides.")
	quit(0)

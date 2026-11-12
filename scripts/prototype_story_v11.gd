extends "res://scripts/prototype_story_v10.gd"
## Prototype 011 — Daily Train action, move-training bars and persistent unlocks.
## Training is separate from hunting EXP and never advances the story.

const TrainingEngine = preload("res://scripts/core/training_engine.gd")
const TRAINING_PATH := "res://data/training/love_beyond.json"

var training_config: Dictionary = {}
var training_engine = null


func _training_load() -> void:
	if training_config.is_empty():
		training_config = ContentStore.read_dictionary(TRAINING_PATH)
	if training_engine == null:
		training_engine = TrainingEngine.new()
	training_engine.begin(training_config, save_data)


func _completed_story_part() -> int:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	return maxi(0, int(lb.get("opening_parts_completed", 0)))


func _take_interlude_action(id: String) -> void:
	if id == "train":
		_open_training_menu()
	else:
		super._take_interlude_action(id)


func _open_training_menu() -> void:
	if not interlude_mode or interlude_engine == null:
		return
	_training_load()
	var pov: String = str(current_profile.get("pov", "asmodeus"))
	var move: Dictionary = training_engine.next_move(pov, _completed_story_part())
	_set_area_background("forest_camp")
	var content := _party_panel("TRAIN — " + pov.to_upper(), "Practice uses one ordinary-day activity, never battle EXP.")
	var actions_left := int(interlude_engine.state.get("actions_left", 0))
	_front_label(content, "DAY %d    •    %d / %d ACTIONS REMAINING" % [
		int(interlude_engine.state.get("day", 1)),
		actions_left, int(current_profile.get("day_actions", 3))], 17)

	if move.is_empty():
		_front_label(content, "All currently designed techniques are learned. More training paths arrive with later chapters.", 17)
	else:
		_front_label(content, "NEXT TECHNIQUE: " + str(move.get("name", "")), 21)
		var explanation := _front_label(content, str(move.get("description", "")), 15, Color(0.83, 0.89, 0.96))
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var required := maxi(1, int(move.get("points_required", 30)))
		var points := clampi(int(move.get("progress", 0)), 0, required)
		var title_text := "MOVE BAR    %d / %d" % [points, required]
		_front_label(content, title_text, 17)
		var meter := ProgressBar.new()
		meter.name = "TrainMoveBar"
		meter.custom_minimum_size = Vector2(620, 28)
		meter.min_value = 0
		meter.max_value = required
		meter.value = points
		meter.show_percentage = false
		content.add_child(meter)
		if bool(move.get("locked", false)):
			_front_label(content, "LOCKED — This technique is available after Part %d." % int(move.get("unlock_after_part", 0)), 16, Color(0.99, 0.78, 0.60))
		else:
			_front_label(content, "Training gives +%d points. Filling the bar learns the move." % int(training_config.get("points_per_session", 10)), 15)
	var practice := _front_button(content, "TRAIN NOW  •  Spend 1 daily action", _train_current_character, 53.0)
	practice.name = "TrainConfirm"
	practice.disabled = not interlude_engine.can_spend_action() or not training_engine.can_train(pov, _completed_story_part())
	var back := _front_button(content, "BACK TO DAILY ROUTINE", _draw_interlude, 46.0)
	back.name = "TrainCancel"


func _train_current_character() -> void:
	if not interlude_mode or interlude_engine == null:
		return
	var pov: String = str(current_profile.get("pov", "asmodeus"))
	_training_load()
	if not interlude_engine.can_spend_action() or not training_engine.can_train(pov, _completed_story_part()):
		last_activity_text = "You cannot practice that technique right now."
		_draw_interlude()
		return
	# Validate all gates before either state object is mutated, so blocked
	# training never spends an action or earns points.
	interlude_engine.spend("train")
	var result: Dictionary = training_engine.session(pov, _completed_story_part())
	if not bool(result.get("ok", false)):
		last_activity_text = str(result.get("message", "Training unavailable."))
	else:
		last_activity_text = str(result.get("message", "Practice complete."))
	training_engine.write_to(save_data)
	# Saves both the training bar and daily-action count in one save operation.
	_save_interlude()
	_draw_interlude()


func _show_character_sheet(id: String) -> void:
	super._show_character_sheet(id)
	if party_engine == null or not party_engine.is_unlocked(id):
		return
	_training_load()
	var scroll := frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	if content == null:
		return
	# Replace the old note now that training is implemented.
	for child in content.get_children():
		if child is Label and child.text.begins_with("TRAINING / ITEMS COMING NEXT"):
			child.text = "Three item slots are reserved for the coming inventory and shop systems."
	var target := training_engine.next_move(id, _completed_story_part())
	var known: Array = training_engine.learned(id)
	var train_title := _front_label(content, "MOVE TRAINING", 19)
	train_title.name = "CharacterTrainingHeader"
	if not known.is_empty():
		var names: Array[String] = []
		for unlocked_move in training_engine.known_move_definitions(id):
			names.append(str(unlocked_move.get("name", "")))
		_front_label(content, "LEARNED: " + ", ".join(names), 15, Color(0.73, 0.94, 0.76))
	if target.is_empty():
		_front_label(content, "All currently available techniques are learned.", 15)
	else:
		var amount := maxi(1, int(target.get("points_required", 30)))
		_front_label(content, str(target.get("name", "")) + "    %d / %d" % [int(target.get("progress", 0)), amount], 16)
		var training_bar := ProgressBar.new()
		training_bar.name = "CharacterTrainingBar"
		training_bar.max_value = amount
		training_bar.value = clampi(int(target.get("progress", 0)), 0, amount)
		training_bar.show_percentage = false
		training_bar.custom_minimum_size = Vector2(640, 22)
		content.add_child(training_bar)
		if bool(target.get("locked", false)):
			_front_label(content, "Training unlocks after Part %d." % int(target.get("unlock_after_part", 0)), 14, Color(0.97, 0.80, 0.61))
		else:
			_front_label(content, "Practice this move through the Train daily activity when this character is available.", 14)
	# Put the whole training section immediately above BACK TO PARTY.
	var back_button: Node = null
	for child in content.get_children():
		if child is Button and child.text == "BACK TO PARTY":
			back_button = child
			break
	if back_button != null:
		var new_section: Array = []
		for child in content.get_children():
			if child.get_index() >= train_title.get_index():
				new_section.append(child)
		for child in new_section:
			content.move_child(child, back_button.get_index())

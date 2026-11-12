extends "res://scripts/prototype_story_v7.gd"
## Prototype 008 — Skip text, never skip interactive story beats.
## The author's dialogue remains in the chapter data and is not modified.

const SKIPPABLE_KINDS := ["title", "line", "checkpoint"]


func _show_dialogue() -> void:
	super._show_dialogue()
	# The prologue is separate from the six-part story event stream. Skip its
	# narration, but still require choosing a fighter and playing the duel.
	var entries: Array = chapter_data.get("dialogue", [])
	if line_index + 1 < entries.size():
		_add_skip_button("SKIP INTRO DIALOGUE", _skip_intro_dialogue)


func _skip_intro_dialogue() -> void:
	var entries: Array = chapter_data.get("dialogue", [])
	if entries.is_empty():
		return
	line_index = entries.size() - 1
	_show_dialogue()


func _show_event() -> void:
	super._show_event()
	if not story_mode or bear_mode or bear_busy or hunt_mode or alley_mode or interlude_mode or battle_demo:
		return
	if event_index < 0 or event_index >= story_events.size():
		return
	var event: Dictionary = story_events[event_index]
	if str(event.get("kind", "line")) in ["line", "title"]:
		_add_skip_button("SKIP DIALOGUE  •  Next gameplay", _skip_story_dialogue)


func _add_skip_button(label_text: String, callback: Callable) -> void:
	if not is_instance_valid(action_row):
		return
	for node in action_row.get_children():
		if node.name == "SkipDialogueButton":
			return
	_button(label_text, callback)
	var button: Button = action_row.get_child(action_row.get_child_count() - 1) as Button
	button.name = "SkipDialogueButton"
	button.tooltip_text = "Skip dialogue only. Battles, gathering, daily choices and other gameplay cannot be skipped."


func _skip_story_dialogue() -> void:
	# Never bypass combat, exploration, the day planner, or a story choice.
	if not story_mode or bear_mode or bear_busy or hunt_mode or alley_mode or interlude_mode or battle_demo:
		return
	_load_story_if_needed()
	if event_index < 0 or event_index >= story_events.size():
		return
	var here: Dictionary = story_events[event_index]
	if not str(here.get("kind", "line")) in ["line", "title"]:
		return

	var target: int = event_index + 1
	while target < story_events.size():
		var beat: Dictionary = story_events[target]
		var kind := str(beat.get("kind", "line"))
		if not kind in SKIPPABLE_KINDS:
			break
		if kind == "title":
			# These labels must still be accurate after skipping across parts.
			part_label = str(beat.get("part", part_label))
			current_part = str(beat.get("title", current_part))
		elif kind == "checkpoint":
			# Preserve authored chapter completion bookkeeping.
			_record_part(int(beat.get("part", 3)))
		target += 1
	event_index = target
	_show_event()

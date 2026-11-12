extends "res://scripts/prototype_story_v6.gd"
## Prototype 007: Daily-life UX fix + grounded, correctly layered battle sprites.
## Story scripts, save progression, hunt EXP and canonical battle outcomes remain untouched.


func _ensure_pixel_layer() -> void:
	super._ensure_pixel_layer()
	# Prototype 006 added the battlers as the last root child, above the dialogue
	# panel. Rendering them beneath the main UI protects every combat button.
	var main_ui: Node = action_row.get_parent().get_parent().get_parent().get_parent()
	if main_ui.get_parent() == self and pixel_layer.get_parent() == self:
		move_child(pixel_layer, main_ui.get_index())


func _show_pixel_stage(area_id: String, actor_id: String, target_id: String, player_name: String, enemy_name: String) -> void:
	super._show_pixel_stage(area_id, actor_id, target_id, player_name, enemy_name)
	# Put feet near the battlefield's lower edge WITHOUT covering the combat HUD.
	_place_battler(actor_sprite, actor_placeholder, 0.08, 0.425, 0.30, 0.71)
	_place_battler(enemy_sprite, enemy_placeholder, 0.64, 0.425, 0.88, 0.71)
	# The supplied Asmodeus PNG looks left. Flip him when on the PLAYER/left side;
	# leave him facing left when he's the opponent on the right (prologue).
	actor_sprite.flip_h = actor_id == "asmodeus"
	enemy_sprite.flip_h = false


func _draw_alley() -> void:
	super._draw_alley()
	if not alley_mode or wave_engine == null:
		return
	_place_battler(actor_sprite, actor_placeholder, 0.05, 0.43, 0.20, 0.71)
	_place_battler(ally_sprite, ally_label, 0.21, 0.43, 0.38, 0.71)
	_place_battler(enemy_sprite, enemy_placeholder, 0.59, 0.43, 0.73, 0.71)
	_place_battler(extra_thug_sprite, extra_thug_label, 0.73, 0.43, 0.86, 0.71)
	_place_battler(joren_boss_sprite, joren_boss_label, 0.85, 0.43, 0.99, 0.71)
	actor_sprite.flip_h = int(wave_engine.wave) == 2


func _draw_interlude() -> void:
	# The old daily menu used a fixed-size, vertically centered panel. A long
	# action summary or smaller window made buttons awkward to reach. Scroll this
	# panel instead of clipping it, and explain why actions become disabled.
	_hide_pixel_stage()
	_ensure_layers()
	_clear_frontend()
	frontend.show()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	portraits.hide()
	_set_story_background(str(current_profile.get("scene", "campfire.jpg")))

	var content: VBoxContainer = _front_panel()
	var panel: PanelContainer = content.get_parent() as PanelContainer
	var scroll := ScrollContainer.new()
	scroll.name = "DailyActivitiesScroll"
	scroll.custom_minimum_size = Vector2(806.0, minf(610.0, get_viewport_rect().size.y * 0.82))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frontend_body.add_child(scroll)
	frontend_body.remove_child(panel)
	scroll.add_child(panel)

	var state: Dictionary = interlude_engine.state
	var available: int = int(state.get("actions_left", 0))
	var total: int = maxi(1, int(current_profile.get("day_actions", 3)))
	_front_label(content, "A DAY IN THE LIFE OF " + str(current_profile.get("pov", "asmodeus")).to_upper(), 25)
	_front_label(content, str(current_profile.get("name", "Interlude")) + "  •  " + str(current_profile.get("location", "Forest Camp")), 18)
	_front_label(content, "DAY %d  |  ACTIONS %d / %d REMAIN  |  HP %d/%d" % [
		int(state.get("day", 1)), available, total,
		int(state.get("hp", 65)), int(state.get("max_hp", 100))], 15, Color(0.83, 0.88, 0.95))
	_front_label(content, "LV %d  |  EXP %d  |  SUPPLIES %d" % [
		int(state.get("level", 1)), int(state.get("xp", 0)),
		int(state.get("supplies", 0))], 15, Color(0.83, 0.88, 0.95))
	if last_activity_text != "":
		var details := _front_label(content, last_activity_text, 15, Color(0.88, 0.84, 0.74))
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if available == 0:
		var explanation := _front_label(content, "You've used today's activities. Hunt if you still have HP, or start another ORDINARY DAY to refresh them. The main story will NOT advance.", 16, Color(0.99, 0.82, 0.62))
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var refresh := _front_button(content, "START ANOTHER ORDINARY DAY  •  Refresh activities", _ordinary_tomorrow, 52.0)
		refresh.name = "Daily_NewOrdinaryDay"
	else:
		_front_label(content, "Choose up to %d activities today. You can hunt more than once." % total, 15, Color(0.76, 0.87, 0.95))

	var hunt_button := _front_button(content, "HUNT  •  Repeatable  •  No daily action cost", _start_hunt, 46.0)
	hunt_button.name = "Daily_Hunt"
	hunt_button.disabled = not interlude_engine.may_hunt()
	for action in current_profile.get("actions", []):
		var id: String = str(action.get("id", ""))
		var button := _front_button(content,
			str(action.get("label", "Activity")) + "  •  " + str(action.get("description", "")),
			Callable(self, "_take_interlude_action").bind(id), 46.0)
		button.name = "Daily_action_" + id
		button.disabled = not interlude_engine.can_spend_action()
		if button.disabled:
			button.tooltip_text = "No daily actions remaining. Start another ordinary day to refresh them."
	var bedtime := _front_button(content, "GO TO BED  •  Choose ordinary or exciting tomorrow", _bedtime_question, 48.0)
	bedtime.name = "Daily_Bedtime"
	var save := _front_button(content, "SAVE AND RETURN TO TITLE", _show_menu, 41.0)
	save.name = "Daily_Save"

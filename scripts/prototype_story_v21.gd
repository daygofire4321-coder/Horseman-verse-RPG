extends "res://scripts/prototype_story_v20.gd"
## Prototype 021: genuinely collapsible daily routine categories and a first
## combat-feel pass. Inherits all established game logic and visual assets.
##
## The accordion MOVES existing functional Buttons, not copies of them.
## Battle sprites gain click-to-target overlays and HP-change feedback.

var routine_open_section := "activities"
var routine_dropdown_bodies: Dictionary = {}
var pending_target_move := ""
var pending_food_slot := -1
var combat_animation_serial := 0


func _daily_group(parent: VBoxContainer, id: String, heading_text: String, subtitle: String, accent: Color) -> VBoxContainer:
	var shell := _daily_panel(parent, "DailyDropdown_" + id,
		Color(0.071, 0.113, 0.174, 0.98),
		Color(accent.r, accent.g, accent.b, 0.64), 12)
	var header := Button.new()
	header.name = "DailyDropdownToggle_" + id
	header.flat = false
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size.y = 50
	shell.add_child(header)
	_daily_style_button(header, accent, true)
	header.pressed.connect(Callable(self, "_daily_select_group").bind(id))
	var sub := _daily_left_label(shell, subtitle, 12, DAILY_MUTED)
	sub.name = "DailyDropdownSubtitle_" + id
	var body := VBoxContainer.new()
	body.name = "DailyDropdownContent_" + id
	body.add_theme_constant_override("separation", 10)
	shell.add_child(body)
	routine_dropdown_bodies[id] = {"header":header, "body":body, "name":heading_text}
	return body


func _daily_select_group(id: String) -> void:
	# One category at a time prevents the dashboard growing back into the
	# enormous list that prompted this redesign.
	routine_open_section = "" if routine_open_section == id else id
	_daily_apply_open_state()


func _daily_apply_open_state() -> void:
	for raw_id in routine_dropdown_bodies:
		var id := str(raw_id)
		var data: Dictionary = routine_dropdown_bodies[id]
		var button: Button = data["header"]
		var body: VBoxContainer = data["body"]
		var is_open := routine_open_section == id
		body.visible = is_open
		button.text = ("▾ " if is_open else "▸ ") + str(data["name"])


func _daily_nav_into(nav_grid: GridContainer, parent: VBoxContainer, name: String) -> bool:
	var card: Control = nav_grid.find_child("DailyNavigation_" + name, false, false) as Control
	if card == null:
		return false
	card.reparent(parent)
	card.custom_minimum_size.y = 0
	return true


func _draw_interlude() -> void:
	super._draw_interlude()
	if not interlude_mode or interlude_engine == null:
		return
	var scroll: ScrollContainer = frontend_body.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	var content: VBoxContainer = scroll.find_child("DailyDashboardHeader", true, false).get_parent() as VBoxContainer
	if content == null:
		return
	var activity_grid: GridContainer = content.find_child("DailyActivityBubbleGrid", false, false) as GridContainer
	var nav_grid: GridContainer = content.find_child("DailyNavigationBubbleGrid", false, false) as GridContainer
	var stats: GridContainer = content.find_child("DailyDashboardStats", false, false) as GridContainer
	if activity_grid == null or nav_grid == null or stats == null:
		return
	routine_dropdown_bodies.clear()

	# Keep the essential moment-to-moment info visible without requiring a
	# stat-dropdown click; move the other six detail chips below the fold.
	var header: PanelContainer = content.find_child("DailyDashboardHeader", false, false) as PanelContainer
	if header != null:
		var header_body: VBoxContainer = header.get_child(0) as VBoxContainer
		var state: Dictionary = interlude_engine.state
		var total := maxi(1, int(current_profile.get("day_actions", 3)))
		var quick := _daily_left_label(header_body, "DAY %d    •    %d / %d ACTIONS    •    HP %d / %d" % [
			int(state.get("day", 1)), int(state.get("actions_left", 0)), total,
			int(state.get("hp", 0)), int(state.get("max_hp", 100))], 15, DAILY_GOLD)
		quick.name = "DailyQuickStatus"
		# Remove repeated decorative slogan now that the section hierarchy
		# guides the user and the header has the important information.
		for child in header_body.get_children():
			if child is Label and child != quick and child.text == "There is no rush. Choose how to spend today.":
				child.hide()

	# These v20 explanatory titles are obsolete once collapsible headers
	# have replaced the full-width grids.
	for node in content.get_children():
		if node is Label and (node.text in [
			"TODAY'S ACTIVITIES", "MANAGE & TRAVEL",
			"These rounded cards are your free-time choices. Most cost one action; hunting is repeatable.",
			"These options do not use your limited activities."]):
			node.hide()

	var activities := _daily_group(content, "activities",
		"TODAY'S ACTIVITIES", "Rest, train, gather, hunt, craft, or explore.", DAILY_AQUA)
	activity_grid.reparent(activities)
	activity_grid.columns = 2 if get_viewport_rect().size.x >= 900 else 1

	var stats_section := _daily_group(content, "details",
		"CHARACTER DETAILS", "Level, EXP, supplies, health, and daily statistics.", DAILY_LILAC)
	stats.reparent(stats_section)
	# The grid remains intact for older UI queries and for the smaller viewport.
	stats.columns = 3 if get_viewport_rect().size.x >= 670 else 2

	var manage := _daily_group(content, "manage",
		"CHARACTERS & INVENTORY", "Your party, equipment, and carried items.", DAILY_MINT)
	var place := _daily_group(content, "travel",
		"PLACES & COMPANIONS", "Visit the market or switch who you play.", DAILY_GOLD)
	var end_day := _daily_group(content, "tomorrow",
		"TOMORROW & SAVE", "Sleep, start another ordinary morning, or exit.", DAILY_ROSE)
	# Reparent the existing navigation cards so every saved callback remains.
	for node in nav_grid.get_children():
		var card: PanelContainer = node as PanelContainer
		if card == null:
			continue
		var original: String = str(card.name).trim_prefix("DailyNavigation_")
		match original:
			"Daily_NewOrdinaryDay", "Daily_Bedtime", "Daily_Save":
				card.reparent(end_day)
			"Daily_VisitMarket", "Daily_SwitchPOV", "HomesteadSwitchPOV":
				card.reparent(place)
			_:
				card.reparent(manage)
		card.custom_minimum_size.y = 0
	nav_grid.hide()
	# Group visiting companions with places and people rather than leaving
	# another tall display outside the dropdowns.
	var visitor: PanelContainer = content.find_child("DailyVisitingHelpersBubble", false, false) as PanelContainer
	if visitor != null:
		visitor.reparent(place)
	# Keep event feedback and location-specific stats above the dropdowns.
	# Relocate sections above the inert empty nav grid.
	var marker := nav_grid.get_index()
	for id in ["activities", "details", "manage", "travel", "tomorrow"]:
		var data: Dictionary = routine_dropdown_bodies[id]
		var section: Node = (data["header"] as Button).get_parent().get_parent()
		content.move_child(section, marker)
		marker += 1
	# Activity results remain visible even if the user had another group open.
	if routine_open_section == "":
		routine_open_section = "activities"
	_daily_apply_open_state()
	scroll.scroll_vertical = 0


func _combat_hp_snapshot() -> Dictionary:
	var capture := {"allies":[], "enemies":[]}
	if party_battle == null:
		return capture
	for unit in party_battle.allies:
		capture["allies"].append({
			"id":str(unit.get("id", "")), "hp":int(unit.get("hp", 0))})
	for unit in party_battle.enemies:
		capture["enemies"].append({
			"id":str(unit.get("id", "")), "hp":int(unit.get("hp", 0))})
	return capture


func _combat_result_overlay(frame: PanelContainer, delta: int, is_enemy: bool) -> void:
	if frame == null or delta == 0:
		return
	var number := Label.new()
	number.name = "CombatFloatingValue"
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.text = ("+%d" % delta) if delta > 0 else ("%d" % delta)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.position = Vector2(12, -14)
	number.custom_minimum_size = Vector2(95, 34)
	number.add_theme_font_size_override("font_size", 24)
	number.add_theme_color_override("font_color",
		DAILY_MINT if delta > 0 else (DAILY_ROSE if is_enemy else DAILY_GOLD))
	number.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.86))
	number.add_theme_constant_override("shadow_offset_x", 1)
	number.add_theme_constant_override("shadow_offset_y", 2)
	frame.add_child(number)
	# Frame itself is the real sprite; briefly brighten it to show impact.
	var end_color := frame.modulate
	if delta < 0:
		frame.modulate = Color(1.0, 0.52, 0.54, 1.0)
	else:
		frame.modulate = Color(0.55, 1.0, 0.72, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(frame, "modulate", end_color, 0.36)
	tween.tween_property(number, "position:y", -53.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.75)
	tween.chain().tween_callback(number.queue_free)


func _combat_animate_changes(before: Dictionary) -> void:
	if not party_battle_active or party_battle == null:
		return
	# Every turn can include retaliation when the round ends. Animate each
	# actual HP change, not just the chosen target, without touching rules.
	for group in ["allies", "enemies"]:
		var old: Array = before.get(group, [])
		var members: Array = party_battle.allies if group == "allies" else party_battle.enemies
		for i in range(mini(old.size(), members.size())):
			var entry: Dictionary = old[i]
			var member: Dictionary = members[i]
			if str(entry.get("id", "")) != str(member.get("id", "")):
				continue
			var delta := int(member.get("hp", 0)) - int(entry.get("hp", 0))
			if delta == 0:
				continue
			var prefix := "EnemyBattler_" if group == "enemies" else "AllyBattler_"
			var frame: PanelContainer = frontend_body.find_child(prefix + str(i), true, false) as PanelContainer
			_combat_result_overlay(frame, delta, group == "enemies")


func _combat_actor_lunge(id: String) -> void:
	if id == "" or party_battle == null:
		return
	var frame: PanelContainer = null
	for i in range(party_battle.allies.size()):
		if str(party_battle.allies[i].get("id", "")) == id:
			frame = frontend_body.find_child("AllyBattler_" + str(i), true, false) as PanelContainer
			break
	if frame == null:
		return
	var start: float = frame.position.x
	var motion := create_tween()
	motion.tween_property(frame, "position:x", start - 35.0, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(frame, "position:x", start, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _party_battle_use(move_id: String, target_index: int) -> void:
	var actor_id := ""
	var is_attack := false
	if party_battle != null and not party_battle.finished:
		actor_id = str(party_battle.current_actor().get("id", ""))
		for raw in party_battle.current_moves():
			var move: Dictionary = raw
			if str(move.get("id", "")) == move_id:
				is_attack = str(move.get("kind", "")) == "damage"
				break
	var before := _combat_hp_snapshot()
	super._party_battle_use(move_id, target_index)
	_combat_animate_changes(before)
	if is_attack:
		_combat_actor_lunge(actor_id)


func _party_battle_use_food(slot_index: int, target_index: int) -> void:
	var before := _combat_hp_snapshot()
	super._party_battle_use_food(slot_index, target_index)
	_combat_animate_changes(before)


func _party_battle_pick_target(move_id: String) -> void:
	pending_target_move = move_id
	pending_food_slot = -1
	super._party_battle_pick_target(move_id)


func _party_battle_food_targets(slot_index: int) -> void:
	pending_food_slot = slot_index
	pending_target_move = ""
	super._party_battle_food_targets(slot_index)


func _combat_ignore_decorative_mouse_input(node: Node) -> void:
	# Status HUD labels, panels and progress bars are decorative. Even if
	# their rectangles overlap the battler artwork, they must not eat clicks.
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_combat_ignore_decorative_mouse_input(child)


func _field_target_markers(enemy_side: bool, indices: Array) -> void:
	super._field_target_markers(enemy_side, indices)
	var stage: Control = frontend_body.find_child("BattlefieldStage", true, false) as Control
	var sprites: Control = frontend_body.find_child("FacingBattlers", true, false) as Control
	if stage != null:
		stage.mouse_filter = Control.MOUSE_FILTER_PASS
	if sprites != null:
		sprites.mouse_filter = Control.MOUSE_FILTER_PASS
	if stage != null:
		for wing_name in ["EnemyWing", "AllyWing"]:
			var wing: Node = stage.get_node_or_null(wing_name)
			if wing != null:
				_combat_ignore_decorative_mouse_input(wing)
	for i in indices:
		var name := ("EnemyBattler_" if enemy_side else "AllyBattler_") + str(i)
		var frame: PanelContainer = frontend_body.find_child(name, true, false) as PanelContainer
		if frame == null:
			continue
		var click := Button.new()
		click.name = "CombatSpriteTarget_" + ("Enemy_" if enemy_side else "Ally_") + str(i)
		# Attach BEFORE applying full-rect anchors; doing it the other way
		# can leave a zero-size click region that cannot target the sprite.
		frame.add_child(click)
		click.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click.offset_left = 0.0
		click.offset_top = 0.0
		click.offset_right = 0.0
		click.offset_bottom = 0.0
		click.flat = true
		click.mouse_filter = Control.MOUSE_FILTER_STOP
		click.focus_mode = Control.FOCUS_ALL
		click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		click.tooltip_text = "Select this character as your target"
		click.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		click.add_theme_stylebox_override("hover", _new_hud_box(0.22, HUD_GOLD, 10))
		click.add_theme_stylebox_override("focus", _new_hud_box(0.25, HUD_GOLD, 10))
		click.add_theme_stylebox_override("pressed", _new_hud_box(0.34, DAILY_AQUA, 10))
		var callback: Callable
		if pending_food_slot >= 0:
			callback = Callable(self, "_party_battle_use_food").bind(pending_food_slot, int(i))
		else:
			callback = Callable(self, "_party_battle_use").bind(pending_target_move, int(i))
		click.pressed.connect(callback)

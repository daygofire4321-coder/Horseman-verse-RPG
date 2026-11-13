extends "res://scripts/prototype_story_v19.gd"
## Prototype 020 — the daily-life UI is a real dashboard rather than
## an accumulating stack of miscellaneous full-width buttons.
## Reparent EXISTING activity controls, retaining their original callbacks,
## disabled states, action costs, and save operations.

const DAILY_AQUA := Color(0.55, 0.87, 0.84)
const DAILY_GOLD := Color(0.96, 0.80, 0.56)
const DAILY_LILAC := Color(0.76, 0.72, 0.94)
const DAILY_ROSE := Color(0.94, 0.65, 0.72)
const DAILY_MINT := Color(0.65, 0.88, 0.70)
const DAILY_TEXT := Color(0.94, 0.96, 0.98)
const DAILY_MUTED := Color(0.72, 0.79, 0.86)


func _daily_bubble_style(fill: Color, outline: Color, radius: int = 21, padding: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = outline
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	return style


func _daily_panel(parent: Node, node_name: String, fill: Color, outline: Color, padding: int = 13) -> VBoxContainer:
	var box := PanelContainer.new()
	box.name = node_name
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", _daily_bubble_style(fill, outline, 21, padding))
	parent.add_child(box)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	box.add_child(body)
	return body


func _daily_left_label(parent: Node, value: String, size_value: int, color: Color = DAILY_TEXT) -> Label:
	var label := _front_label(parent, value, size_value, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _daily_status_chip(parent: Node, key: String, value: String, tint: Color) -> void:
	var chip := _daily_panel(parent, "DailyStat_" + key, Color(0.085, 0.127, 0.191, 0.96),
		Color(tint.r, tint.g, tint.b, 0.53), 9)
	chip.get_parent().custom_minimum_size = Vector2(145, 64)
	_daily_left_label(chip, key.to_upper(), 11, DAILY_MUTED)
	_daily_left_label(chip, value, 18, tint)


func _daily_accent_for(id: String) -> Color:
	match id:
		"rest", "care":
			return DAILY_MINT
		"train", "patrol", "explore", "explore_safely":
			return DAILY_AQUA
		"garden", "camp":
			return DAILY_GOLD
		"woodwork", "reflect":
			return DAILY_LILAC
		"hunt":
			return DAILY_ROSE
		_:
			return DAILY_AQUA


func _daily_action_detail(id: String) -> Dictionary:
	if id == "hunt":
		return {
			"title":"HUNT", "description":"Repeatable wildlife encounter. No daily action cost.",
			"cost":"FREE • REPEATABLE"
		}
	for raw in current_profile.get("actions", []):
		var action: Dictionary = raw
		if str(action.get("id", "")) == id:
			return {
				"title":str(action.get("label", id)).to_upper(),
				"description":str(action.get("description", "")),
				"cost":"1 DAILY ACTION"
			}
	return {"title":id.replace("_", " ").to_upper(), "description":"Available today.", "cost":"1 DAILY ACTION"}


func _daily_style_button(button: Button, accent: Color, is_primary: bool = false) -> void:
	button.custom_minimum_size.y = 41 if not is_primary else 47
	button.add_theme_font_size_override("font_size", 13 if not is_primary else 15)
	button.add_theme_color_override("font_color", DAILY_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.66, 0.71))
	var dark_fill := Color(0.13, 0.22, 0.30, 0.98)
	button.add_theme_stylebox_override("normal",
		_daily_bubble_style(dark_fill, Color(accent.r, accent.g, accent.b, 0.8), 16, 9))
	button.add_theme_stylebox_override("hover",
		_daily_bubble_style(Color(0.21, 0.33, 0.41, 0.99), accent, 16, 9))
	button.add_theme_stylebox_override("pressed",
		_daily_bubble_style(Color(0.11, 0.19, 0.26, 0.99), accent, 16, 9))
	button.add_theme_stylebox_override("disabled",
		_daily_bubble_style(Color(0.09, 0.12, 0.16, 0.90),
			Color(0.31, 0.37, 0.42, 0.42), 16, 9))
	button.add_theme_stylebox_override("focus",
		_daily_bubble_style(Color(0.1, 0.17, 0.22, 0.14), accent, 16, 9))


func _daily_add_action_card(grid: GridContainer, button: Button, id: String, number: int) -> void:
	var detail := _daily_action_detail(id)
	var accent := _daily_accent_for(id)
	var body := _daily_panel(grid, "DailyBubble_" + id,
		Color(0.068, 0.103, 0.158, 0.96),
		Color(accent.r, accent.g, accent.b, 0.62), 15)
	body.get_parent().custom_minimum_size.y = 145
	body.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	body.add_child(top)
	var stamp := _daily_panel(top, "DailyBubbleIcon_" + id,
		Color(accent.r, accent.g, accent.b, 0.17),
		Color(accent.r, accent.g, accent.b, 0.43), 6)
	stamp.get_parent().custom_minimum_size = Vector2(38, 36)
	var glyph := _daily_left_label(stamp, "%02d" % number, 16, accent)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 3)
	top.add_child(words)
	_daily_left_label(words, str(detail["title"]), 15, DAILY_TEXT)
	var desc := _daily_left_label(words, str(detail["description"]), 12, DAILY_MUTED)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.reparent(body)
	button.text = "UNAVAILABLE TODAY" if button.disabled else "START  •  " + str(detail["cost"])
	if button.disabled and button.tooltip_text == "":
		button.tooltip_text = "This activity is currently unavailable."
	_daily_style_button(button, accent)
	# Cliffside has no wildlife hunting; Haniel's homestead is a carpentry
	# day. Keep those old controls in the tree for compatibility but don't
	# waste a large visible bubble on an impossible action.
	if id == "hunt" and button.disabled and (_is_cliffside_day() or
			(_is_homestead_day() and str(current_profile.get("pov", "")) == "haniel")):
		body.get_parent().hide()


func _daily_add_navigation_card(grid: GridContainer, button: Button, title_text: String, subtext: String, accent: Color) -> void:
	var body := _daily_panel(grid, "DailyNavigation_" + str(button.name),
		Color(0.071, 0.110, 0.172, 0.96),
		Color(accent.r, accent.g, accent.b, 0.5), 13)
	body.get_parent().custom_minimum_size.y = 103
	_daily_left_label(body, title_text, 15, accent)
	_daily_left_label(body, subtext, 12, DAILY_MUTED)
	button.reparent(body)
	button.text = "OPEN" if not button.disabled else "UNAVAILABLE"
	_daily_style_button(button, accent)


func _daily_original_section(content: VBoxContainer) -> Dictionary:
	# Each of these controls originates in v7/v10/v13/v14/v19 and
	# already has the correct pressed signal and enable/disable logic.
	var actions: Array[Button] = []
	var navigation: Array[Button] = []
	var visitors: Array[HBoxContainer] = []
	var old_copy: Array[Node] = content.get_children()
	for node in old_copy:
		if node is Button:
			var button: Button = node as Button
			if button.name == "Daily_Hunt" or str(button.name).begins_with("Daily_action_"):
				actions.append(button)
			else:
				navigation.append(button)
		elif node is HBoxContainer:
			visitors.append(node as HBoxContainer)
		else:
			node.hide()
	return {"actions":actions, "navigation":navigation, "visitors":visitors}


func _daily_nav_metadata(button: Button) -> Dictionary:
	match str(button.name):
		"Daily_NewOrdinaryDay":
			return {"title":"A FRESH MORNING", "subtitle":"Refill daily actions, without moving the story forward.", "accent":DAILY_MINT}
		"Daily_Bedtime":
			return {"title":"GO TO BED", "subtitle":"End the day and choose what tomorrow holds.", "accent":DAILY_GOLD}
		"Daily_Save":
			return {"title":"SAVE & EXIT", "subtitle":"Return to the title without losing your activities.", "accent":DAILY_ROSE}
		"Daily_VisitMarket":
			return {"title":"VISIT THE MARKET", "subtitle":"Buy or sell in town. No daily action cost.", "accent":DAILY_GOLD}
		"Daily_SwitchPOV", "HomesteadSwitchPOV":
			return {"title":"SWITCH CHARACTER", "subtitle":"Spend ordinary days with the other protagonist.", "accent":DAILY_AQUA}
		_:
			var label := button.text.to_upper()
			if label.begins_with("PARTY"):
				return {"title":"PARTY & STATUS", "subtitle":"Check your characters and equipment.", "accent":DAILY_LILAC}
			if label.begins_with("INVENTORY"):
				return {"title":"INVENTORY", "subtitle":"Prepare equipment and useful supplies.", "accent":DAILY_MINT}
			return {"title":label.split("  •  ")[0], "subtitle":"Open this option.", "accent":DAILY_AQUA}


func _draw_interlude() -> void:
	# The full inherited chain builds every actual gameplay button first.
	# Only after that do we arrange them into the new card dashboard.
	super._draw_interlude()
	if not interlude_mode or interlude_engine == null:
		return
	var scroll: ScrollContainer = frontend_body.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var panel: PanelContainer = scroll.get_child(0) as PanelContainer
	if panel == null or panel.get_child_count() == 0:
		return
	var content: VBoxContainer = panel.get_child(0) as VBoxContainer
	if content == null:
		return
	var originals: Dictionary = _daily_original_section(content)
	var action_buttons: Array = originals["actions"]
	var navigation_buttons: Array = originals["navigation"]
	var visitor_rows: Array = originals["visitors"]
	var view_width := minf(940.0, maxf(320.0, get_viewport_rect().size.x - 30.0))
	var viewport_h := get_viewport_rect().size.y
	frontend_body.custom_minimum_size.x = view_width
	scroll.custom_minimum_size = Vector2(view_width, minf(660.0, maxf(270.0, viewport_h - 30.0)))
	panel.custom_minimum_size.x = view_width - 18.0
	panel.add_theme_stylebox_override("panel",
		_daily_bubble_style(Color(0.034, 0.061, 0.102, 0.96),
			Color(0.55, 0.78, 0.82, 0.8), 26, 16))
	content.add_theme_constant_override("separation", 13)

	var profile_name: String = str(current_profile.get("pov", "asmodeus")).capitalize()
	var state: Dictionary = interlude_engine.state
	var available := int(state.get("actions_left", 0))
	var max_actions := maxi(1, int(current_profile.get("day_actions", 3)))
	var heading := _daily_panel(content, "DailyDashboardHeader",
		Color(0.085, 0.150, 0.212, 0.96), Color(0.51, 0.85, 0.85, 0.7), 16)
	_daily_left_label(heading, "A DAY WITH " + profile_name.to_upper(), 23, DAILY_TEXT)
	_daily_left_label(heading,
		str(current_profile.get("name", "Ordinary Day")) + "  ·  " + str(current_profile.get("location", "Forest Camp")),
		14, DAILY_AQUA)
	_daily_left_label(heading, "There is no rush. Choose how to spend today.", 13, DAILY_MUTED)

	var stats := GridContainer.new()
	stats.name = "DailyDashboardStats"
	stats.columns = 3 if view_width >= 660 else 2
	stats.add_theme_constant_override("h_separation", 9)
	stats.add_theme_constant_override("v_separation", 9)
	content.add_child(stats)
	_daily_status_chip(stats, "Day", str(state.get("day", 1)), DAILY_AQUA)
	_daily_status_chip(stats, "Actions", "%d / %d" % [available, max_actions],
		DAILY_GOLD if available == 0 else DAILY_MINT)
	_daily_status_chip(stats, "Health", "%d / %d" % [
		int(state.get("hp", 0)), int(state.get("max_hp", 100))], DAILY_ROSE)
	_daily_status_chip(stats, "Level", str(state.get("level", 1)), DAILY_GOLD)
	_daily_status_chip(stats, "EXP", str(state.get("xp", 0)), DAILY_LILAC)
	_daily_status_chip(stats, "Supplies", str(state.get("supplies", 0)), DAILY_AQUA)

	if _is_cliffside_day():
		var gold := _daily_panel(content, "DailyEconomyBubble",
			Color(0.17, 0.137, 0.083, 0.91), Color(0.94, 0.76, 0.43, 0.65), 12)
		_daily_left_label(gold, "GOLD  %d     ·     OUTLAW WINS  %d" % [
			economy_engine.wallet(), int(economy_engine.state.get("outlaw_victories", 0))], 15, DAILY_GOLD)
	if _is_homestead_day():
		var progress := _daily_panel(content, "DailyHomesteadBubble",
			Color(0.107, 0.119, 0.198, 0.91), Color(0.68, 0.70, 0.91, 0.66), 12)
		_daily_left_label(progress, "GARDEN SESSIONS  %d     ·     WOODWORK LESSONS  %d" % [
			int(state.get("gardening_sessions", 0)), int(state.get("woodwork_sessions", 0))], 14, DAILY_LILAC)

	if last_activity_text != "":
		var news := _daily_panel(content, "DailyLastActivityBubble",
			Color(0.104, 0.152, 0.168, 0.94), Color(0.45, 0.78, 0.67, 0.53), 12)
		_daily_left_label(news, "LAST ACTIVITY", 12, DAILY_MINT)
		_daily_left_label(news, last_activity_text, 14, DAILY_TEXT)
	if available <= 0:
		var info := _daily_panel(content, "DailyActionsExhaustedBubble",
			Color(0.18, 0.12, 0.094, 0.92), Color(0.98, 0.73, 0.51, 0.65), 12)
		_daily_left_label(info, "ALL ACTIVITIES USED TODAY", 15, DAILY_GOLD)
		_daily_left_label(info,
			"Start another ordinary day to refill your actions. The story will not advance.", 13, DAILY_MUTED)

	_daily_left_label(content, "TODAY'S ACTIVITIES", 19, DAILY_TEXT)
	_daily_left_label(content,
		"These rounded cards are your free-time choices. Most cost one action; hunting is repeatable.",
		13, DAILY_MUTED)
	var action_grid := GridContainer.new()
	action_grid.name = "DailyActivityBubbleGrid"
	action_grid.columns = 2 if view_width >= 740 else 1
	action_grid.add_theme_constant_override("h_separation", 12)
	action_grid.add_theme_constant_override("v_separation", 12)
	action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(action_grid)
	var number := 1
	for entry in action_buttons:
		var button: Button = entry as Button
		var id := "hunt" if button.name == "Daily_Hunt" else str(button.name).trim_prefix("Daily_action_")
		_daily_add_action_card(action_grid, button, id, number)
		number += 1

	if visitor_rows.size() > 0:
		var folks := _daily_panel(content, "DailyVisitingHelpersBubble",
			Color(0.091, 0.120, 0.168, 0.91), Color(0.64, 0.73, 0.89, 0.53), 12)
		_daily_left_label(folks, "FRIENDS HELPING OUT", 16, DAILY_LILAC)
		for row in visitor_rows:
			(row as HBoxContainer).reparent(folks)

	_daily_left_label(content, "MANAGE & TRAVEL", 19, DAILY_TEXT)
	_daily_left_label(content, "These options do not use your limited activities.", 13, DAILY_MUTED)
	var nav_grid := GridContainer.new()
	nav_grid.name = "DailyNavigationBubbleGrid"
	nav_grid.columns = 2 if view_width >= 740 else 1
	nav_grid.add_theme_constant_override("h_separation", 12)
	nav_grid.add_theme_constant_override("v_separation", 12)
	content.add_child(nav_grid)
	for entry in navigation_buttons:
		var button: Button = entry as Button
		var meta := _daily_nav_metadata(button)
		_daily_add_navigation_card(nav_grid, button, str(meta["title"]), str(meta["subtitle"]), meta["accent"] as Color)

	scroll.scroll_vertical = 0

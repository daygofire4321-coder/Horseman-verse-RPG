extends "res://scripts/prototype_story_v15.gd"
## Prototype 016 — JRPG-inspired combat HUD and cleanup of an old title UI.
## The player's battle reference informs grouping and presentation only;
## no external UI art or UI assets are copied.

const HUD_RED := Color(0.90, 0.37, 0.43, 1.0)
const HUD_AQUA := Color(0.32, 0.88, 0.79, 1.0)
const HUD_GOLD := Color(0.94, 0.78, 0.43, 1.0)

var combat_tab := "skills"
var combat_last_actor := ""
var combat_last_round := -1


func _legacy_dialogue_frame() -> Control:
	if not is_instance_valid(speaker) or speaker.get_parent() == null:
		return null
	return speaker.get_parent().get_parent() as Control


func _prepare_campaign_screen() -> void:
	super._prepare_campaign_screen()
	# The old visual-novel dialogue panel isn't part of the campaign hub.
	# Before this pass it remained as a large, empty dark bar on the art.
	var legacy: Control = _legacy_dialogue_frame()
	if legacy != null:
		legacy.hide()


func _restore_story_dialogue() -> void:
	var legacy: Control = _legacy_dialogue_frame()
	if legacy != null:
		legacy.show()


func _start_dialogue() -> void:
	_restore_story_dialogue()
	super._start_dialogue()


func _show_event() -> void:
	_restore_story_dialogue()
	super._show_event()


func _choose_fighter() -> void:
	_restore_story_dialogue()
	super._choose_fighter()


func _draw_battle() -> void:
	_restore_story_dialogue()
	super._draw_battle()


func _new_hud_box(alpha: float = 0.89, border: Color = Color(0.41, 0.61, 0.77, 0.74), radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.022, 0.041, 0.077, alpha)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(9)
	return style


func _bar_fill(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.set_corner_radius_all(3)
	return style


func _compact_hp(parent: Node, hp: int, maximum: int, is_enemy: bool, width_value: float = 145.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "EnemyHpMini" if is_enemy else "AllyHpMini"
	bar.custom_minimum_size = Vector2(width_value, 9.0)
	bar.min_value = 0.0
	bar.max_value = maxf(1.0, float(maximum))
	bar.value = clampf(float(hp), 0.0, bar.max_value)
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bar_fill(Color(0.09, 0.115, 0.16, 0.93)))
	var ratio := float(hp) / float(maxi(1, maximum))
	var color := HUD_RED if is_enemy else HUD_AQUA
	if ratio < 0.30 and hp > 0:
		color = HUD_GOLD
	bar.add_theme_stylebox_override("fill", _bar_fill(color))
	parent.add_child(bar)
	return bar


func _small_battle_portrait(parent: Node, id: String, size_value: Vector2 = Vector2(70, 78)) -> void:
	_read_pixel_data()
	var filename := str(pixel_data.get("sprites", {}).get(id, ""))
	var path := AREA_ART_ROOT + filename
	var preview := TextureRect.new()
	preview.custom_minimum_size = size_value
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if filename != "" and ResourceLoader.exists(path):
		preview.texture = load(path)
	parent.add_child(preview)


func _enemy_lane(parent: Node) -> void:
	var enemy_side := VBoxContainer.new()
	enemy_side.name = "EnemyWing"
	enemy_side.custom_minimum_size.x = 274.0
	enemy_side.add_theme_constant_override("separation", 7)
	parent.add_child(enemy_side)
	var tag := _front_label(enemy_side, "ENEMIES", 14, HUD_RED)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in range(party_battle.enemies.size()):
		var foe: Dictionary = party_battle.enemies[i]
		var chip := PanelContainer.new()
		chip.name = "EnemyMini_" + str(i)
		chip.add_theme_stylebox_override("panel", _new_hud_box(0.82, Color(0.69, 0.36, 0.43, 0.78)))
		chip.custom_minimum_size = Vector2(257, 68)
		enemy_side.add_child(chip)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		chip.add_child(row)
		_small_battle_portrait(row, str(foe.get("id", "")), Vector2(54, 50))
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 4)
		row.add_child(details)
		var name_label := _front_label(details, "#%d %s" % [i + 1, str(foe.get("name", "Enemy"))], 13)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_compact_hp(details, int(foe.get("hp", 0)), int(foe.get("max_hp", 1)), true, 138.0)
		var hp_label := _front_label(details, "%d / %d HP" % [
			int(foe.get("hp", 0)), int(foe.get("max_hp", 1))], 11, Color(0.94, 0.81, 0.84))
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _ally_lane(parent: Node) -> void:
	var wing := VBoxContainer.new()
	wing.name = "AllyWing"
	wing.add_theme_constant_override("separation", 7)
	wing.custom_minimum_size.x = 364.0
	parent.add_child(wing)
	var tag := _front_label(wing, "YOUR PARTY", 14, HUD_AQUA)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_END
	wing.add_child(row)
	var actor: Dictionary = party_battle.current_actor()
	for unit in party_battle.allies:
		var member: Dictionary = unit
		var cell := VBoxContainer.new()
		cell.custom_minimum_size.x = 96
		cell.add_theme_constant_override("separation", 3)
		row.add_child(cell)
		_small_battle_portrait(cell, str(member.get("id", "")), Vector2(92, 100))
		var name_label := _front_label(cell, str(member.get("name", "")), 12, UI_TEXT)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if str(member.get("id", "")) == str(actor.get("id", "")):
			name_label.add_theme_color_override("font_color", HUD_GOLD)
		if int(member.get("hp", 0)) <= 0:
			name_label.add_theme_color_override("font_color", Color(0.55, 0.59, 0.65))


func _party_status_strip(parent: Node) -> void:
	var row := HBoxContainer.new()
	row.name = "BattlePartyStatus"
	row.add_theme_constant_override("separation", 9)
	parent.add_child(row)
	var actor: Dictionary = party_battle.current_actor()
	for member_raw in party_battle.allies:
		var member: Dictionary = member_raw
		var card := PanelContainer.new()
		var is_active := str(member.get("id", "")) == str(actor.get("id", ""))
		card.add_theme_stylebox_override("panel", _new_hud_box(
			0.94, HUD_GOLD if is_active else Color(0.35, 0.63, 0.73, 0.68)))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(185, 72)
		row.add_child(card)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 4)
		card.add_child(info)
		var headline := HBoxContainer.new()
		info.add_child(headline)
		var who := _front_label(headline, str(member.get("name", "Ally")).to_upper(), 14,
			HUD_GOLD if is_active else UI_ICE)
		who.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hp_label := _front_label(headline, "%d/%d" % [
			int(member.get("hp", 0)), int(member.get("max_hp", 1))], 13, UI_TEXT)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_compact_hp(info, int(member.get("hp", 0)), int(member.get("max_hp", 1)), false, 160.0)
		var status := "◈ YOUR TURN" if is_active else ("KO" if int(member.get("hp", 0)) == 0 else ("GUARD" if bool(member.get("guard", false)) else "READY"))
		var status_label := _front_label(info, status, 10, HUD_GOLD if is_active else Color(0.70, 0.79, 0.87))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _battle_roster_row(content: VBoxContainer) -> void:
	var stage := HBoxContainer.new()
	stage.name = "PartyBattleRoster"
	stage.custom_minimum_size.y = 180
	stage.add_theme_constant_override("separation", 12)
	content.add_child(stage)
	_enemy_lane(stage)
	var flexible_space := Control.new()
	flexible_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flexible_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(flexible_space)
	_ally_lane(stage)


func _battle_panel(title_text: String) -> VBoxContainer:
	# This replaces the old tall button-panel, leaving the world background
	# visible and putting compact enemy/ally information on opposite sides.
	_ensure_layers()
	_hide_pixel_stage()
	_clear_frontend()
	frontend.show()
	portraits.hide()
	_set_hp_visible(false)
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	_set_area_background(party_battle_area)
	if frontend.get_child_count() > 0 and frontend.get_child(0) is ColorRect:
		var veil: ColorRect = frontend.get_child(0) as ColorRect
		veil.color = Color(0.013, 0.02, 0.035, 0.13)
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_width := minf(1210.0, maxf(350.0, viewport_size.x - 30.0))
	var panel_height := minf(662.0, maxf(315.0, viewport_size.y - 28.0))
	frontend_body.custom_minimum_size = Vector2(panel_width, 0)
	var scroll := ScrollContainer.new()
	scroll.name = "PartyPanelScroll"
	scroll.custom_minimum_size = Vector2(panel_width, panel_height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	frontend_body.add_child(scroll)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = panel_width - 10.0
	var outer_style := _new_hud_box(0.22, Color(0.56, 0.64, 0.76, 0.20), 12)
	outer_style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", outer_style)
	scroll.add_child(panel)
	var content := VBoxContainer.new()
	content.name = "BattleContent"
	content.add_theme_constant_override("separation", 9)
	panel.add_child(content)
	var title := _front_label(content, title_text, 22, HUD_GOLD)
	title.name = "CombatSceneTitle"
	var subtext := str(live_outlaw_scenario.get("title", "REAL DAILY ENCOUNTER")) if live_outlaw_active else "PRACTICE BATTLE  •  NO SAVE CHANGES"
	var subtitle := _front_label(content, subtext, 13, UI_ICE)
	subtitle.name = "CombatContext"
	_battle_roster_row(content)
	_party_status_strip(content)
	var narrative := PanelContainer.new()
	narrative.name = "CombatLogPanel"
	narrative.add_theme_stylebox_override("panel", _new_hud_box(0.83, Color(0.41, 0.57, 0.69, 0.55)))
	content.add_child(narrative)
	var log := _front_label(narrative, str(party_battle.last_log), 14, UI_TEXT)
	log.name = "CombatLogText"
	log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return content


func _party_battle_draw() -> void:
	super._party_battle_draw()
	if not party_battle_active or party_battle == null or party_battle.finished:
		return
	var scroll: ScrollContainer = frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	var content: VBoxContainer = scroll.find_child("BattleContent", true, false) as VBoxContainer
	if content == null:
		return
	var actor: Dictionary = party_battle.current_actor()
	var actor_key: String = str(actor.get("id", ""))
	if combat_last_actor != actor_key or combat_last_round != party_battle.round_number:
		combat_tab = "skills"
		combat_last_actor = actor_key
		combat_last_round = party_battle.round_number

	# Existing controls continue to exist (and keep their callbacks) for
	# backward-compatibility and automated tests. The new JRPG command dock
	# provides the visually arranged, player-facing controls.
	for child in content.get_children():
		if child is Button:
			child.hide()
		elif child is Label and (
			child.text.begins_with("YOUR TURN:") or
			child.text.begins_with("Characters act in Speed order.")
		):
			child.hide()

	_draw_command_dock(content, actor)


func _tab_button(parent: Node, tab_id: String, title_text: String, enabled: bool = true) -> Button:
	var callback: Callable = Callable(self, "_set_combat_tab").bind(tab_id)
	var button := _front_button(parent, title_text, callback, 42.0)
	button.name = "CombatTab_" + tab_id
	button.disabled = not enabled
	if combat_tab == tab_id:
		button.add_theme_stylebox_override("normal",
			_button_style(Color(0.22, 0.21, 0.16, 0.98), HUD_GOLD))
		button.add_theme_color_override("font_color", HUD_GOLD)
	return button


func _set_combat_tab(tab_id: String) -> void:
	if not ["attack", "skills", "items", "guard", "switch"].has(tab_id):
		return
	if party_battle == null or party_battle.finished:
		return
	combat_tab = tab_id
	_party_battle_draw()


func _primary_attack() -> Dictionary:
	for move_raw in party_battle.current_moves():
		var move: Dictionary = move_raw
		if str(move.get("id", "")) == "attack" or str(move.get("id", "")) == "hammer":
			return move
	for move_raw in party_battle.current_moves():
		var move: Dictionary = move_raw
		if str(move.get("kind", "")) == "damage":
			return move
	return {}


func _draw_command_dock(content: VBoxContainer, actor: Dictionary) -> void:
	var dock := PanelContainer.new()
	dock.name = "CombatCommandDock"
	dock.add_theme_stylebox_override("panel", _new_hud_box(0.965, Color(0.82, 0.67, 0.42, 0.80)))
	content.add_child(dock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	dock.add_child(row)

	var categories := VBoxContainer.new()
	categories.name = "CombatCategories"
	categories.custom_minimum_size.x = 420
	categories.add_theme_constant_override("separation", 7)
	row.add_child(categories)
	var section := _front_label(categories, "COMMAND  /  " + str(actor.get("name", "")).to_upper(), 14, HUD_GOLD)
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	categories.add_child(grid)
	_tab_button(grid, "attack", "ATTACK")
	_tab_button(grid, "skills", "SKILLS")
	_tab_button(grid, "items", "ITEMS")
	_tab_button(grid, "guard", "GUARD")
	_tab_button(grid, "switch", "SWITCH", not party_battle.reserves.is_empty())
	var retreat: Button = _front_button(grid, "RETREAT" if live_outlaw_active else "EXIT", 
		_retreat_outlaw if live_outlaw_active else _show_menu, 42.0)
	retreat.name = "CombatExit"

	var detail_panel := PanelContainer.new()
	detail_panel.name = "CombatDetailPanel"
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _new_hud_box(0.96, Color(0.37, 0.62, 0.75, 0.70)))
	row.add_child(detail_panel)
	var details := VBoxContainer.new()
	details.name = "CombatActionList"
	details.add_theme_constant_override("separation", 5)
	detail_panel.add_child(details)

	var label_text := combat_tab.to_upper() + "  •  SELECT ACTION"
	var label := _front_label(details, label_text, 14, HUD_AQUA)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	match combat_tab:
		"attack":
			var base: Dictionary = _primary_attack()
			if base.is_empty():
				_front_label(details, "No basic attack equipped.", 14)
			else:
				_move_action(details, base, "Attack")
		"skills":
			var count := 0
			for raw in party_battle.current_moves():
				var move: Dictionary = raw
				if str(move.get("kind", "")) == "guard":
					continue
				if str(move.get("id", "")) in ["attack", "hammer"]:
					continue
				_move_action(details, move, "Skill")
				count += 1
			if count == 0:
				_front_label(details, "No other skills equipped yet.", 14, UI_ICE)
		"items":
			var valid := 0
			var items: Array = actor.get("items", [])
			for index in party_battle.usable_food_slots():
				var item: Dictionary = items[index]
				var button := _front_button(details,
					"%s  •  +%d HP" % [str(item.get("name", "Food")), int(item.get("heal", 0))],
					Callable(self, "_party_battle_food_targets").bind(index), 41.0)
				button.name = "CombatAction_Item_" + str(index)
				button.disabled = party_battle.food_targets(index).is_empty()
				valid += 1
			if valid == 0:
				_front_label(details, "No prepared food in this fighter's slots.", 14, UI_ICE)
		"guard":
			var defended := false
			for raw in party_battle.current_moves():
				var move: Dictionary = raw
				if str(move.get("kind", "")) == "guard":
					_move_action(details, move, "Guard")
					defended = true
			if not defended:
				_front_label(details, "No guard technique equipped.", 14, UI_ICE)
		"switch":
			var count := 0
			for raw in party_battle.reserves:
				var ally: Dictionary = raw
				if int(ally.get("hp", 0)) <= 0:
					continue
				var id := str(ally.get("id", ""))
				var button := _front_button(details, "BRING IN " + str(ally.get("name", id)).to_upper(),
					Callable(self, "_party_battle_switch").bind(id), 41.0)
				button.name = "CombatAction_Switch_" + id
				count += 1
			if count == 0:
				_front_label(details, "No available reserve fighters.", 14, UI_ICE)


func _move_action(parent: Node, move: Dictionary, prefix: String) -> void:
	var id := str(move.get("id", ""))
	var kind := str(move.get("kind", "damage"))
	var power := int(move.get("power", 0))
	var suffix := ("  •  %d" % power) if power > 0 else ""
	var callback: Callable = Callable(self, "_party_battle_use").bind(id, -1) if kind == "guard" else Callable(self, "_party_battle_pick_target").bind(id)
	var button := _front_button(parent, str(move.get("name", id)) + suffix, callback, 41.0)
	button.name = "CombatAction_" + prefix + "_" + id


func _target_card(parent: Node, name_text: String, hp: int, max_hp: int, foe: bool, action: Callable, index: int) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _new_hud_box(0.94,
		HUD_RED if foe else HUD_AQUA))
	card.custom_minimum_size.x = 240
	parent.add_child(card)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	card.add_child(layout)
	var reticle := _front_label(layout, "◇", 38, HUD_GOLD)
	reticle.name = "TargetReticle_" + str(index)
	var button := _front_button(layout, name_text, action, 50.0)
	button.name = ("PartyTarget_Enemy_" if foe else "PartyTarget_Ally_") + str(index)
	_compact_hp(layout, hp, max_hp, foe, 160.0)
	_front_label(layout, "%d / %d HP" % [hp, max_hp], 13, UI_ICE)


func _party_battle_pick_target(move_id: String) -> void:
	if not party_battle_active or party_battle == null or party_battle.finished:
		return
	var move: Dictionary = {}
	for raw in party_battle.current_moves():
		var candidate: Dictionary = raw
		if str(candidate.get("id", "")) == move_id:
			move = candidate
			break
	if move.is_empty():
		return
	var heal: bool = str(move.get("kind", "damage")) == "heal"
	var content := _battle_panel("SELECT " + ("ALLY" if heal else "ENEMY") + " TARGET")
	_front_label(content, str(move.get("name", move_id)) + "  •  Select a living target.", 17, UI_ICE)
	var targets_row := HBoxContainer.new()
	targets_row.name = "CombatTargetChoices"
	targets_row.add_theme_constant_override("separation", 12)
	content.add_child(targets_row)
	var members: Array = party_battle.allies if heal else party_battle.enemies
	for i in party_battle.targets(move_id):
		var unit: Dictionary = members[i]
		_target_card(targets_row, str(unit.get("name", "")), int(unit.get("hp", 0)),
			int(unit.get("max_hp", 1)), not heal,
			Callable(self, "_party_battle_use").bind(move_id, i), i)
	_front_button(content, "BACK TO COMMANDS", _party_battle_draw, 44.0)


func _party_battle_food_targets(slot_index: int) -> void:
	if party_battle == null or party_battle.finished:
		return
	var content := _battle_panel("CHOOSE WHO EATS")
	_front_label(content, "Prepared food costs this fighter's turn.", 16, UI_ICE)
	var row := HBoxContainer.new()
	row.name = "CombatTargetChoices"
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	for i in party_battle.food_targets(slot_index):
		var unit: Dictionary = party_battle.allies[i]
		_target_card(row, str(unit.get("name", "")), int(unit.get("hp", 0)),
			int(unit.get("max_hp", 1)), false,
			Callable(self, "_party_battle_use_food").bind(slot_index, i), i)
	_front_button(content, "BACK TO ITEMS", Callable(self, "_set_combat_tab").bind("items"), 44.0)

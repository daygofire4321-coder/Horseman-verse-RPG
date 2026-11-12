extends "res://scripts/prototype_story_v11.gd"
## Prototype 012: optional 3-person party combat, move and target selection.
## Completely separate from scripted story battles and ordinary-day rewards.

const PartyBattleEngine = preload("res://scripts/core/party_battle_engine.gd")

var party_battle = null
var party_battle_active := false
var party_battle_area := "forest_clearing"


func _show_menu() -> void:
	party_battle_active = false
	party_battle = null
	super._show_menu()
	var scroll: ScrollContainer = frontend_body.find_child("TitleMenuScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var panel: PanelContainer = scroll.get_child(0) as PanelContainer
	var content: VBoxContainer = panel.get_child(0) as VBoxContainer
	_front_button(content, "PARTY BATTLE PRACTICE  •  Three-character combat", _party_battle_select_arena, 47.0)


func _party_battle_select_arena() -> void:
	var content := _party_panel("PARTY BATTLE PRACTICE", "Non-canon test battles  •  No EXP, HP loss, or save changes")
	_front_label(content, "Choose a battlefield. Your current party and trained moves will be loaded from your save.", 16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "WOODLAND SKIRMISH  •  Boar and Wolf", Callable(self, "_party_battle_start").bind("forest_clearing"), 53.0)
	_front_button(content, "CLIFFSIDE DRILL  •  Two Thugs", Callable(self, "_party_battle_start").bind("cliffside_alley"), 53.0)
	_front_button(content, "BACK TO TITLE", _show_menu, 42.0)


func _party_battle_start(area_id: String = "forest_clearing") -> void:
	_party_load()
	var sheets: Dictionary = {}
	for id in party_engine.unlocked:
		sheets[id] = party_engine.sheet(id, save_data)
	var active_ids: Array = []
	for slot_id in party_engine.active:
		if str(slot_id) != "":
			active_ids.append(str(slot_id))
	var reserve_ids: Array = []
	for id in party_engine.unlocked:
		if not active_ids.has(id):
			reserve_ids.append(id)
	var encounter: Array = ["wild_boar", "gray_wolf"]
	party_battle_area = "forest_clearing"
	if area_id == "cliffside_alley":
		encounter = ["bandit_thug", "bandit_thug"]
		party_battle_area = "cliffside_alley"
	party_battle = PartyBattleEngine.new()
	party_battle.setup(active_ids, reserve_ids, sheets, encounter, selected_profile)
	party_battle_active = true
	_party_battle_draw()


func _battle_picture(parent: Node, id: String, is_foe: bool) -> void:
	_read_pixel_data()
	var file_id := id
	if id == "bandit_thug":
		file_id = "bandit_thug"
	var file_name := str(pixel_data.get("sprites", {}).get(file_id, ""))
	var image_path := AREA_ART_ROOT + file_name
	var image := TextureRect.new()
	image.name = "BattlePicture_" + id
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	image.custom_minimum_size = Vector2(144, 112)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if file_name != "" and ResourceLoader.exists(image_path):
		image.texture = load(image_path)
		image.flip_h = not is_foe and id == "asmodeus"
	parent.add_child(image)


func _battle_roster_row(content: VBoxContainer) -> void:
	var stage := HBoxContainer.new()
	stage.name = "PartyBattleRoster"
	stage.add_theme_constant_override("separation", 12)
	content.add_child(stage)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 348
	stage.add_child(side)
	_front_label(side, "YOUR PARTY", 18)
	var own := HBoxContainer.new()
	own.add_theme_constant_override("separation", 7)
	side.add_child(own)
	for member in party_battle.allies:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 106
		own.add_child(column)
		_battle_picture(column, str(member.get("id", "")), false)
		_front_label(column, str(member.get("name", "")), 13)
		var hp := _front_label(column, "%d / %d HP" % [int(member.get("hp", 0)), int(member.get("max_hp", 0))], 13)
		if int(member.get("hp", 0)) == 0:
			hp.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
		if bool(member.get("guard", false)):
			_front_label(column, "GUARD", 12, Color(0.73, 0.88, 1.0))

	var enemy_side := VBoxContainer.new()
	enemy_side.custom_minimum_size.x = 305
	stage.add_child(enemy_side)
	_front_label(enemy_side, "OPPONENTS", 18)
	var foes := HBoxContainer.new()
	enemy_side.add_child(foes)
	for i in range(party_battle.enemies.size()):
		var foe: Dictionary = party_battle.enemies[i]
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 130
		foes.add_child(column)
		_battle_picture(column, str(foe.get("id", "")), true)
		_front_label(column, "#%d %s" % [i + 1, str(foe.get("name", ""))], 13)
		_front_label(column, "%d / %d HP" % [int(foe.get("hp", 0)), int(foe.get("max_hp", 0))], 13)


func _battle_panel(title_text: String) -> VBoxContainer:
	_set_area_background(party_battle_area)
	var content := _party_panel(title_text, "NON-CANON COMBAT TEST  •  Saved HP, EXP, and story are unaffected")
	_battle_roster_row(content)
	var battle_log := _front_label(content, str(party_battle.last_log), 15, Color(0.92, 0.86, 0.75))
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return content


func _party_battle_draw() -> void:
	if not party_battle_active or party_battle == null:
		return
	if party_battle.finished:
		var result_text := "VICTORY!" if party_battle.victory else "PARTY DEFEATED"
		var ended := _battle_panel(result_text)
		_front_label(ended, "This practice battle does not affect your save or EXP.", 15)
		_front_button(ended, "TRY AGAIN", Callable(self, "_party_battle_start").bind(party_battle_area), 48.0)
		_front_button(ended, "RETURN TO TITLE", _show_menu, 45.0)
		return
	var actor: Dictionary = party_battle.current_actor()
	var content := _battle_panel("PARTY BATTLE  •  ROUND %d" % party_battle.round_number)
	_front_label(content, "YOUR TURN: " + str(actor.get("name", "Ally")).to_upper(), 18, Color(0.85, 0.96, 1.0))
	_front_label(content, "Characters act in Speed order. Choose a move, then its target.", 14)
	for move in party_battle.current_moves():
		var data: Dictionary = move
		var mid := str(data.get("id", ""))
		var mtype := str(data.get("kind", "damage"))
		var label_text := str(data.get("name", mid)) + "  •  " + mtype.capitalize()
		if int(data.get("power", 0)) > 0:
			label_text += " %d" % int(data.get("power", 0))
		var callback: Callable = Callable(self, "_party_battle_use").bind(mid, -1) if mtype == "guard" else Callable(self, "_party_battle_pick_target").bind(mid)
		var button := _front_button(content, label_text, callback, 43.0)
		button.name = "PartyMove_" + mid
	var switch_button := _front_button(content, "SWITCH FIGHTER  •  Costs a turn", _party_battle_switch_menu, 43.0)
	switch_button.name = "PartyBattleSwitch"
	switch_button.disabled = party_battle.reserves.is_empty()
	_front_button(content, "LEAVE PRACTICE (NO SAVE CHANGES)", _show_menu, 42.0)


func _party_battle_pick_target(move_id: String) -> void:
	if not party_battle_active or party_battle == null or party_battle.finished:
		return
	var move: Dictionary = {}
	for choice in party_battle.current_moves():
		if str(choice.get("id", "")) == move_id:
			move = choice
			break
	if move.is_empty():
		return
	var is_heal: bool = str(move.get("kind", "damage")) == "heal"
	var content := _battle_panel("SELECT " + ("ALLY" if is_heal else "ENEMY") + " TARGET")
	_front_label(content, str(move.get("name", move_id)) + "  •  Choose a living target.", 17)
	var candidates: Array = party_battle.allies if is_heal else party_battle.enemies
	for index in party_battle.targets(move_id):
		var data: Dictionary = candidates[index]
		var btn := _front_button(content, "%s  •  %d / %d HP" % [
			str(data.get("name", "")), int(data.get("hp", 0)), int(data.get("max_hp", 0))],
			Callable(self, "_party_battle_use").bind(move_id, index), 45.0)
		btn.name = ("PartyTarget_Ally_" if is_heal else "PartyTarget_Enemy_") + str(index)
	_front_button(content, "BACK TO MOVES", _party_battle_draw, 43.0)


func _party_battle_use(move_id: String, target_index: int) -> void:
	if not party_battle_active or party_battle == null:
		return
	var result: Dictionary = party_battle.use_move(move_id, target_index)
	if not bool(result.get("ok", false)):
		# Rejecting an invalid move never consumes a character turn.
		party_battle.last_log = str(result.get("message", "Invalid action."))
	_party_battle_draw()


func _party_battle_switch_menu() -> void:
	if not party_battle_active or party_battle == null or party_battle.finished:
		return
	var content := _battle_panel("SWITCH CURRENT FIGHTER")
	_front_label(content, "A replacement joins from your unlocked reserves. Switching consumes the active fighter's turn.", 16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if party_battle.reserves.is_empty():
		_front_label(content, "No unlocked reserves. To test switching, leave one unlocked character out of the active three.", 15)
	for member in party_battle.reserves:
		var id := str(member.get("id", ""))
		if int(member.get("hp", 0)) <= 0:
			continue
		var button := _front_button(content, "BRING IN %s  •  %d HP" % [
			str(member.get("name", "")), int(member.get("hp", 0))],
			Callable(self, "_party_battle_switch").bind(id), 48.0)
		button.name = "PartySwitch_" + id
	_front_button(content, "BACK TO MOVES", _party_battle_draw, 44.0)


func _party_battle_switch(reserve_id: String) -> void:
	if not party_battle_active or party_battle == null:
		return
	var result: Dictionary = party_battle.switch_with_reserve(reserve_id)
	if not bool(result.get("ok", false)):
		party_battle.last_log = str(result.get("message", "Cannot switch."))
	_party_battle_draw()

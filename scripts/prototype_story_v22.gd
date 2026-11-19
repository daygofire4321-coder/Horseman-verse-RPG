extends "res://scripts/prototype_story_v21.gd"
## Prototype 022 — actual RPG level-aware encounter balance, difficulty
## selection from the campaign menu, and EXP for active teammates.
## Story bosses/duels retain their authored outcomes. No save schema changes.

const EncounterBalance = preload("res://scripts/core/encounter_balance.gd")
const CharacterLeveling = preload("res://scripts/core/character_leveling.gd")


func _battle_difficulty_with_progress(player_level: int = 1) -> Dictionary:
	var effective: Dictionary = selected_profile.duplicate(true)
	effective["story_part"] = _completed_story_part()
	effective["player_level"] = maxi(1, player_level)
	return effective


func _party_battle_start(area_id: String = "forest_clearing") -> void:
	# Parent computes the actual active party and reserves from the save.
	# Inject chapter position only for this optional encounter; restore the
	# profile immediately so story duels remain canonically untouched.
	var saved_profile: Dictionary = selected_profile.duplicate(true)
	selected_profile = _battle_difficulty_with_progress()
	super._party_battle_start(area_id)
	selected_profile = saved_profile


func _start_outlaw_encounter(forced_id: String = "") -> void:
	var saved_profile: Dictionary = selected_profile.duplicate(true)
	selected_profile = _battle_difficulty_with_progress(
		int(interlude_engine.state.get("level", 1)) if interlude_engine != null else 1)
	super._start_outlaw_encounter(forced_id)
	selected_profile = saved_profile


func _start_hunt() -> void:
	var saved_profile: Dictionary = selected_profile.duplicate(true)
	selected_profile = _battle_difficulty_with_progress(
		int(interlude_engine.state.get("level", 1)) if interlude_engine != null else 1)
	super._start_hunt()
	selected_profile = saved_profile


func _finish_outlaw_encounter(retreated: bool) -> void:
	var was_victory: bool = live_outlaw_active and not live_outlaw_resolved and \
		party_battle != null and party_battle.finished and party_battle.victory and not retreated
	var earned := maxi(0, int(live_outlaw_scenario.get("exp", 15))) if was_victory else 0
	var participating: Array = []
	if was_victory:
		# Give every active fighter the encounter's EXP, even if they were
		# knocked out during the fight. Reserve characters never gain EXP.
		for unit in party_battle.allies:
			var member: Dictionary = unit
			var id := str(member.get("id", ""))
			if id != "" and id != live_outlaw_pov:
				participating.append({
					"id":id, "max_hp":int(member.get("max_hp", 100)),
					"level":int(member.get("level", 1))
				})
	super._finish_outlaw_encounter(retreated)
	if not was_victory or participating.is_empty():
		return
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var love: Dictionary = campaigns.get("love_beyond", {})
	var progression: Dictionary = love.get("progression", {})
	var announcements: Array[String] = []
	for unit in participating:
		var id: String = str(unit["id"])
		var prior: Dictionary = progression.get(id, {})
		# Fallback to the real character sheet's base maximum if the ally
		# has never received EXP. HP has already been persisted by the parent.
		var max_hp := int(unit.get("max_hp", 100))
		var gained: Dictionary = CharacterLeveling.grant_xp(prior, earned, max_hp)
		progression[id] = gained["progress"]
		var levels := int(gained.get("levels", 0))
		if levels > 0:
			announcements.append("%s +%d EXP — LEVEL UP!" % [id.capitalize(), earned])
		else:
			announcements.append("%s +%d EXP" % [id.capitalize(), earned])
	love["progression"] = progression
	campaigns["love_beyond"] = love
	save_data["campaigns"] = campaigns
	last_activity_text += "\nParty training: " + ", ".join(announcements) + "."
	_save_interlude()
	_draw_interlude()


func _field_hp_card(parent: Node, member: Dictionary, index: int, enemy_side: bool) -> void:
	super._field_hp_card(parent, member, index, enemy_side)
	if not enemy_side or parent.get_child_count() == 0:
		return
	var card: PanelContainer = parent.get_child(parent.get_child_count() - 1) as PanelContainer
	if card == null:
		return
	var body: VBoxContainer = card.get_child(0) as VBoxContainer
	if body != null and body.get_child_count() > 0 and body.get_child(0) is Label:
		var nameplate: Label = body.get_child(0) as Label
		nameplate.text = "LV %d  •  %s" % [
			int(member.get("level", 1)), str(member.get("name", "Enemy"))]


func _show_love_adventure() -> void:
	super._show_love_adventure()
	var menu: VBoxContainer = frontend_body.find_child("CampaignMenuContent", true, false) as VBoxContainer
	if menu == null:
		return
	var button := _front_button(menu, "CHALLENGE SETTINGS  •  %s" % [
		str(selected_profile.get("name", "Normal")).to_upper()], _show_challenge_settings, 48.0)
	button.name = "LoveDifficulty"
	for child in menu.get_children():
		if child is Button and (child.text == "BACK TO LOVE BEYOND" or child.name == "LoveHomestead"):
			menu.move_child(button, child.get_index())
			break


func _show_challenge_settings() -> void:
	var expected := EncounterBalance.expected_level(_completed_story_part())
	var content := _title_panel("CHALLENGE SETTINGS",
		"Choose the danger level for optional encounters. Change it anytime.")
	_front_label(content, "STORY PROGRESS  •  PART %d    |    EXPECTED PLAY LEVEL  •  LV %d" %
		[_completed_story_part(), expected], 16, UI_ICE)
	var description := _front_label(content,
		"Enemy levels are based on story progress, not copied from your party. "
		+ "Leveling up, training moves and finding better gear will still give you an advantage.", 14, UI_TEXT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for difficulty in difficulty_data.get("profiles", []):
		var config: Dictionary = difficulty
		var id := str(config.get("id", "normal"))
		var target := EncounterBalance.target_level(_completed_story_part(), config)
		var hp := roundi(float(config.get("enemy_hp_multiplier", 1.0)) * 100.0)
		var damage := roundi(float(config.get("enemy_damage_multiplier", 1.0)) * 100.0)
		var selected := "  ✓ CURRENT" if str(selected_profile.get("id", "")) == id else ""
		var title := "%s  •  ENEMY LV %d    HP %d%% / DMG %d%%%s" % [
			str(config.get("name", id)).to_upper(), target, hp, damage, selected]
		var select := _front_button(content, title,
			Callable(self, "_choose_challenge_difficulty").bind(id), 53.0)
		select.name = "ChallengeMode_" + id
		_front_label(content, str(config.get("description", "")), 13, UI_ICE).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "BACK TO ADVENTURE", _show_love_adventure, 43.0)


func _choose_challenge_difficulty(difficulty_id: String) -> void:
	if not ["story", "normal", "hard", "nightmare"].has(difficulty_id):
		return
	selected_profile = _find_profile(difficulty_id)
	SaveStore.set_difficulty(save_data, difficulty_id)
	if not party_disable_disk_writes:
		SaveStore.write_save(save_data)
	_show_challenge_settings()

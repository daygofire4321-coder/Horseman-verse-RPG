extends "res://scripts/prototype_illustrated.gd"
## Optional modular version of Prototype 001.
## Reuses the proven illustrated layout but takes dialogue/moves/combat from data.

const ContentStore = preload("res://scripts/core/content_store.gd")
const DuelEngine = preload("res://scripts/core/duel_engine.gd")
const SaveStore = preload("res://scripts/core/save_store.gd")
const CHAPTER_ID = "love_beyond_prototype_001"

var chapter_data: Dictionary = {}
var difficulty_data: Dictionary = {}
var selected_profile: Dictionary = {}
var save_data: Dictionary = {}
var duel = null


func _ready() -> void:
	chapter_data = ContentStore.load_chapter(CHAPTER_ID)
	difficulty_data = ContentStore.read_dictionary("res://data/difficulties.json")
	save_data = SaveStore.load_save()
	var settings: Dictionary = save_data.get("settings", {})
	selected_profile = _find_profile(str(settings.get("difficulty", difficulty_data.get("default", "normal"))))
	super._ready()


func _find_profile(difficulty_id: String) -> Dictionary:
	for profile in difficulty_data.get("profiles", []):
		if str(profile.get("id", "")) == difficulty_id:
			return profile
	return {"id": "normal", "name": "Normal", "enemy_hp_multiplier": 1.0, "enemy_damage_multiplier": 1.0}


func _choose_fighter() -> void:
	_clear_buttons()
	_set_hp_visible(false)
	heading.text = "CHOOSE YOUR FIGHTER"
	subheading.text = "THE FIRST DUEL"
	speaker.text = "YOUR PERSPECTIVE"
	message.text = "Haniel: divine arrows and healing.\nAsmodeus: black ice and defensive magic."
	_button("Play as Haniel", Callable(self, "_show_difficulty_picker").bind("Haniel", "Asmodeus"))
	_button("Play as Asmodeus", Callable(self, "_show_difficulty_picker").bind("Asmodeus", "Haniel"))


func _show_difficulty_picker(chosen: String, enemy_name: String) -> void:
	_clear_buttons()
	heading.text = "SELECT DIFFICULTY"
	subheading.text = "FIGHT AS " + chosen.to_upper()
	speaker.text = "DIFFICULTY"
	message.text = "Choose the challenge for this duel. Your choice will be remembered."
	for profile in difficulty_data.get("profiles", []):
		var difficulty_id := str(profile.get("id", "normal"))
		var difficulty_label := str(profile.get("name", difficulty_id))
		_button(difficulty_label, Callable(self, "_begin_with_difficulty").bind(chosen, enemy_name, difficulty_id))
	_button("Back", _choose_fighter)


func _begin_with_difficulty(chosen: String, enemy_name: String, difficulty_id: String) -> void:
	selected_profile = _find_profile(difficulty_id)
	SaveStore.set_difficulty(save_data, str(selected_profile.get("id", "normal")))
	SaveStore.write_save(save_data)
	_start_battle(chosen, enemy_name)


func _chapter_background(key: String, fallback: String) -> void:
	var backgrounds: Dictionary = chapter_data.get("backgrounds", {})
	_background(str(backgrounds.get(key, fallback)))


func _start_dialogue() -> void:
	line_index = 0
	_chapter_background("dialogue", "storm_duel.jpg")
	_show_dialogue()


func _show_dialogue() -> void:
	var entries: Array = chapter_data.get("dialogue", [])
	if entries.is_empty():
		# Keeps this scene usable if the chapter data is missing.
		super._show_dialogue()
		return

	_clear_buttons()
	_set_hp_visible(false)
	heading.text = str(chapter_data.get("title", "THE FIRST ENCOUNTER")).to_upper()
	subheading.text = str(chapter_data.get("series", "LOVE BEYOND")).to_upper() + " / " + str(chapter_data.get("subtitle", "IN THE SKY")).to_upper()
	var entry: Dictionary = entries[line_index]
	speaker.text = str(entry.get("speaker", "NARRATOR"))
	message.text = str(entry.get("text", ""))
	if line_index + 1 < entries.size():
		_button("Continue", _advance_dialogue)
	else:
		_button("Choose your fighter", _choose_fighter)


func _start_battle(chosen: String, enemy_name: String) -> void:
	var player_data: Dictionary = ContentStore.load_character(chosen.to_lower())
	var enemy_data: Dictionary = ContentStore.load_character(enemy_name.to_lower())
	if player_data.is_empty() or enemy_data.is_empty():
		_clear_buttons()
		speaker.text = "CONTENT ERROR"
		message.text = "Character data is missing. Check the Godot Output panel."
		_button("Back to title", _show_menu)
		return

	fighter = chosen
	opponent = enemy_name
	duel = DuelEngine.new()
	duel.setup(player_data, enemy_data, selected_profile)
	player_hp = duel.player_hp
	enemy_hp = duel.enemy_hp
	last_message = str(chapter_data.get("battle_intro", "The battle begins!"))
	_chapter_background("battle", "storm_duel.jpg")
	_draw_battle()


func _draw_battle() -> void:
	if duel == null:
		return
	_clear_buttons()
	_set_hp_visible(true)
	_update_hp()
	heading.text = "THE FIRST DUEL"
	subheading.text = "YOU CONTROL: %s    |    OPPONENT: %s    |    %s" % [fighter.to_upper(), opponent.to_upper(), str(selected_profile.get("name", "Normal")).to_upper()]
	speaker.text = "BATTLE"
	message.text = last_message
	for move in duel.player_moves():
		var move_id := str(move.get("id", ""))
		var label_text := str(move.get("name", move_id))
		if str(move.get("kind", "")) == "damage":
			label_text += " · %d" % int(move.get("power", 0))
		elif str(move.get("kind", "")) == "heal":
			label_text += " · +%d" % int(move.get("power", 0))
		_button(label_text, Callable(self, "_turn").bind(move_id))


func _turn(move_id: String) -> void:
	if duel == null:
		return
	var outcome: Dictionary = duel.take_turn(move_id)
	player_hp = int(outcome.get("player_hp", player_hp))
	enemy_hp = int(outcome.get("enemy_hp", enemy_hp))
	last_message = str(outcome.get("message", ""))
	if bool(outcome.get("finished", false)):
		_result(bool(outcome.get("victory", false)))
	else:
		_draw_battle()



func _update_hp() -> void:
	if duel == null:
		return
	var haniel_value: int = player_hp if fighter == "Haniel" else enemy_hp
	var haniel_max: int = duel.player_max_hp if fighter == "Haniel" else duel.enemy_max_hp
	var asmo_value: int = player_hp if fighter == "Asmodeus" else enemy_hp
	var asmo_max: int = duel.player_max_hp if fighter == "Asmodeus" else duel.enemy_max_hp
	haniel_hp.max_value = haniel_max
	asmodeus_hp.max_value = asmo_max
	haniel_hp.value = haniel_value
	asmodeus_hp.value = asmo_value
	haniel_hp.get_parent().get_node("HPText").text = "%d / %d HP" % [haniel_value, haniel_max]
	asmodeus_hp.get_parent().get_node("HPText").text = "%d / %d HP" % [asmo_value, asmo_max]


func _result(won: bool) -> void:
	if won:
		SaveStore.record_test_victory(save_data, CHAPTER_ID, fighter.to_lower(), str(selected_profile.get("id", "normal")))
		SaveStore.write_save(save_data)
	super._result(won)
	if won:
		message.text += "\nPrototype victory recorded in your local save."

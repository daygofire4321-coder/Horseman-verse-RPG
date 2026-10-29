extends "res://scripts/prototype_illustrated.gd"
## Optional modular version of Prototype 001.
## Reuses the proven illustrated layout but takes dialogue/moves/combat from data.

const ContentStore = preload("res://scripts/core/content_store.gd")
const DuelEngine = preload("res://scripts/core/duel_engine.gd")
const CHAPTER_ID = "love_beyond_prototype_001"

var chapter_data: Dictionary = {}
var duel = null


func _ready() -> void:
	chapter_data = ContentStore.load_chapter(CHAPTER_ID)
	super._ready()


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
	duel.setup(player_data, enemy_data)
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
	subheading.text = "YOU CONTROL: %s    |    OPPONENT: %s" % [fighter.to_upper(), opponent.to_upper()]
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

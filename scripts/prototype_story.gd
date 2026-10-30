extends "res://scripts/prototype_v2.gd"
## Prototype 003 — The three-part Love Beyond opening.
## This inherits the tested title menu, prologue duel, abilities and save data.
## Narrative scenes are data-driven and the grizzly fight ends at 50% HP.

const STORY_PATH := "res://data/chapters/love_beyond_opening_story.json"
const STORY_ART_ROOT := "res://assets/love_beyond/story_001/"
const BEAR_ID := "grizzly_bear"

var story_mode := false
var bear_mode := false
var story_data: Dictionary = {}
var story_events: Array = []
var event_index := 0
var part_label := "PART ONE"
var current_part := "AFTERMATH"
var gathering_count := 0
var gathering_target := 3
var bear_busy := false

var boss_hud: PanelContainer
var bear_bar: ProgressBar
var hero_bar: ProgressBar
var bear_hp_label: Label
var hero_hp_label: Label


func _show_menu() -> void:
	story_mode = false
	bear_mode = false
	bear_busy = false
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	if is_instance_valid(portraits):
		portraits.show()
	super._show_menu()


func _start_dialogue() -> void:
	story_mode = true
	bear_mode = false
	_load_story_if_needed()
	if is_instance_valid(portraits):
		portraits.show()
	super._start_dialogue()


func _load_story_if_needed() -> void:
	if not story_events.is_empty():
		return
	story_data = ContentStore.read_dictionary(STORY_PATH)
	story_events = story_data.get("events", [])


func _result(won: bool) -> void:
	if not story_mode or bear_mode:
		super._result(won)
		return
	super._result(won)
	heading.text = "THE THUNDERCLOUD DUEL"
	subheading.text = "LOVE BEYOND  /  PROLOGUE COMPLETE"
	speaker.text = "AFTERMATH"
	message.text = "The battle ends with both otherworldly fighters exhausted. Whatever the outcome of the tutorial, their story continues in a damp cave."
	_clear_buttons()
	_button("Continue to Part One: Aftermath", _begin_story_events)
	_button("Back to title", _show_menu)


func _begin_story_events() -> void:
	_load_story_if_needed()
	if story_events.is_empty():
		speaker.text = "STORY CONTENT MISSING"
		message.text = "The opening story file could not be loaded."
		_clear_buttons()
		_button("Return to title", _show_menu)
		return
	event_index = 0
	gathering_count = 0
	if is_instance_valid(frontend):
		frontend.hide()
	_show_event()


func _advance_event() -> void:
	event_index += 1
	_show_event()


func _set_story_background(file_name: String) -> void:
	var image_path := STORY_ART_ROOT + file_name
	if ResourceLoader.exists(image_path):
		scene_image.texture = load(image_path)
	elif ResourceLoader.exists(ASSET_ROOT + "storm_duel.jpg"):
		# Missing story art must never block the event flow.
		scene_image.texture = load(ASSET_ROOT + "storm_duel.jpg")


func _show_event() -> void:
	_clear_buttons()
	_set_hp_visible(false)
	if is_instance_valid(frontend):
		frontend.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	portraits.hide()
	if event_index >= story_events.size():
		_finish_story()
		return

	var event: Dictionary = story_events[event_index]
	if event.has("image"):
		_set_story_background(str(event.get("image", "")))
	heading.text = "%s  /  %s" % [part_label, current_part]
	subheading.text = "A LOVE STRONGER THAN HEAVEN OR HELL"
	var kind := str(event.get("kind", "line"))
	match kind:
		"title":
			part_label = str(event.get("part", "PART ONE"))
			current_part = str(event.get("title", "AFTERMATH"))
			heading.text = part_label
			subheading.text = "A LOVE STRONGER THAN HEAVEN OR HELL"
			speaker.text = current_part
			message.text = "Continue to begin."
			_button("Enter " + current_part, _advance_event)
		"line":
			speaker.text = str(event.get("speaker", "NARRATOR"))
			message.text = str(event.get("text", ""))
			_button("Continue", _advance_event)
		"gather":
			gathering_target = maxi(1, int(event.get("count", 3)))
			gathering_count = 0
			_draw_gathering()
		"battle":
			_start_bear_battle(event)
		_:
			speaker.text = "UNKNOWN STORY EVENT"
			message.text = "Unsupported event type: " + kind
			_button("Skip event", _advance_event)


func _draw_gathering() -> void:
	_clear_buttons()
	heading.text = "PART TWO  /  THE NATURAL ORDER"
	subheading.text = "FOREST UNDER THE OLD OAK"
	speaker.text = "HANIEL"
	message.text = "Gather only fallen branches. %d of %d collected." % [gathering_count, gathering_target]
	if gathering_count < gathering_target:
		_button("Pick up a fallen branch", _collect_branch)
	else:
		message.text = "Haniel has gathered enough branches without harming the old oak."
		_button("Continue", _advance_event)


func _collect_branch() -> void:
	gathering_count += 1
	_draw_gathering()


func _ensure_boss_hud() -> void:
	if is_instance_valid(boss_hud):
		return
	boss_hud = PanelContainer.new()
	boss_hud.name = "BearBossHUD"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.040, 0.065, 0.95)
	panel_style.border_color = Color(0.87, 0.44, 0.33, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(9)
	boss_hud.add_theme_stylebox_override("panel", panel_style)

	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 3)
	boss_hud.add_child(block)
	bear_hp_label = Label.new()
	bear_hp_label.add_theme_font_size_override("font_size", 17)
	block.add_child(bear_hp_label)
	bear_bar = ProgressBar.new()
	bear_bar.show_percentage = false
	bear_bar.custom_minimum_size.y = 15
	block.add_child(bear_bar)
	hero_hp_label = Label.new()
	hero_hp_label.add_theme_font_size_override("font_size", 17)
	block.add_child(hero_hp_label)
	hero_bar = ProgressBar.new()
	hero_bar.show_percentage = false
	hero_bar.custom_minimum_size.y = 15
	block.add_child(hero_bar)

	var stack: VBoxContainer = heading.get_parent() as VBoxContainer
	stack.add_child(boss_hud)
	stack.move_child(boss_hud, 2)
	boss_hud.hide()


func _start_bear_battle(event: Dictionary) -> void:
	var asmo: Dictionary = ContentStore.load_character("asmodeus")
	var bear: Dictionary = ContentStore.load_character(BEAR_ID)
	if asmo.is_empty() or bear.is_empty():
		speaker.text = "BATTLE DATA MISSING"
		message.text = "Cannot load Asmodeus or the grizzly bear data."
		_button("Continue story", _advance_event)
		return

	bear_mode = true
	bear_busy = false
	fighter = "Asmodeus"
	opponent = "Grizzly Bear"
	duel = DuelEngine.new()
	duel.setup(asmo, bear, selected_profile)
	# The duel with Haniel has already left Asmodeus severely weakened.
	duel.player_hp = mini(duel.player_max_hp, 65)
	player_hp = duel.player_hp
	enemy_hp = duel.enemy_hp
	_set_story_background(str(event.get("image", "bear_boss.jpg")))
	_ensure_boss_hud()
	_draw_battle()


func _draw_battle() -> void:
	if not bear_mode:
		super._draw_battle()
		return
	_clear_buttons()
	portraits.hide()
	boss_hud.show()
	_update_boss_hud()
	heading.text = "PART THREE  /  THE BEAR"
	subheading.text = "ASMODEUS  VS  GRIZZLY BEAR  /  %s" % str(selected_profile.get("name", "Normal")).to_upper()
	speaker.text = "SURVIVE THE ENCOUNTER"
	message.text = "The beast is far stronger than Asmodeus in his weakened state.\nPush it back. Do not give up."
	for move in duel.player_moves():
		var id := str(move.get("id", ""))
		var label_text := str(move.get("name", "Attack"))
		if str(move.get("kind", "")) == "damage":
			label_text += "  -  %d damage" % int(move.get("power", 0))
		_button(label_text, Callable(self, "_bear_turn").bind(id))


func _update_boss_hud() -> void:
	if duel == null or not is_instance_valid(boss_hud):
		return
	bear_bar.max_value = duel.enemy_max_hp
	bear_bar.value = duel.enemy_hp
	hero_bar.max_value = duel.player_max_hp
	hero_bar.value = duel.player_hp
	bear_hp_label.text = "GRIZZLY BEAR    %d / %d HP" % [duel.enemy_hp, duel.enemy_max_hp]
	hero_hp_label.text = "ASMODEUS    %d / %d HP" % [duel.player_hp, duel.player_max_hp]


func _bear_turn(move_id: String) -> void:
	if not bear_mode or bear_busy or duel == null:
		return
	bear_busy = true
	_clear_buttons()
	var outcome: Dictionary = duel.take_turn(move_id)
	player_hp = int(outcome.get("player_hp", player_hp))
	enemy_hp = int(outcome.get("enemy_hp", enemy_hp))
	speaker.text = "THE STRUGGLE"
	message.text = str(outcome.get("message", ""))
	_bear_visual_effect(move_id)
	await get_tree().create_timer(0.65).timeout
	if not is_inside_tree() or not bear_mode:
		return
	_update_boss_hud()

	var trigger_hp: int = int(ceil(float(duel.enemy_max_hp) * 0.5))
	if enemy_hp <= trigger_hp or player_hp <= 0:
		_bear_rescue()
	else:
		bear_busy = false
		_draw_battle()


func _bear_visual_effect(move_id: String) -> void:
	# Temporary, asset-free battle feedback in the illustrated forest.
	var tint := Color(0.43, 0.19, 0.71, 0.58) if move_id == "black_ice" else Color(0.92, 0.73, 0.50, 0.35)
	if move_id == "ice_guard":
		tint = Color(0.25, 0.45, 1.0, 0.32)
	var flash := ColorRect.new()
	flash.color = tint
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx_layer.add_child(flash)
	var fade := create_tween()
	fade.tween_property(flash, "modulate:a", 0.0, 0.46)
	fade.tween_callback(flash.queue_free)


func _bear_rescue() -> void:
	# Story battles never block progress. The author controls the ending.
	bear_busy = false
	bear_mode = false
	boss_hud.hide()
	# The event immediately following the bear encounter is the rescue scene.
	_advance_event()


func _finish_story() -> void:
	_save_story_completion()
	_set_story_background("haniel_collapse.jpg")
	heading.text = "PART THREE COMPLETE"
	subheading.text = "A LOVE STRONGER THAN HEAVEN OR HELL"
	speaker.text = "TO BE CONTINUED"
	message.text = "Haniel has saved Asmodeus. The next scene begins with Part Four, once its story is added to the game."
	_clear_buttons()
	_button("Replay the opening", _start_dialogue)
	_button("Return to title", _show_menu)


func _save_story_completion() -> void:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var love_beyond: Dictionary = campaigns.get("love_beyond", {})
	love_beyond["opening_parts_completed"] = 3
	love_beyond["last_story_event"] = "end_part_three"
	campaigns["love_beyond"] = love_beyond
	save_data["campaigns"] = campaigns
	SaveStore.write_save(save_data)

extends "res://scripts/prototype_story_v4.gd"
## Prototype 005 / Visual Pass 1.
## Full-width area-specific pixel art only appears in battles.
## Illustrated story cutscenes, canonical outcomes and interludes stay intact.

const BATTLE_ART_MAP := "res://data/battle_areas.json"
const AREA_ART_ROOT := "res://assets/love_beyond/pixel_battles/"

var pixel_data: Dictionary = {}
var pixel_layer: Control
var actor_sprite: TextureRect
var enemy_sprite: TextureRect
var actor_placeholder: Label
var enemy_placeholder: Label
var stage_area := ""
var battle_demo := false


func _read_pixel_data() -> void:
	if pixel_data.is_empty():
		pixel_data = ContentStore.read_dictionary(BATTLE_ART_MAP)


func _hide_pixel_stage() -> void:
	if is_instance_valid(pixel_layer):
		pixel_layer.hide()
	stage_area = ""
	scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE


func _show_menu() -> void:
	_hide_pixel_stage()
	battle_demo = false
	super._show_menu()
	# Keep testing a new visual style one click away, without touching saves.
	if is_instance_valid(frontend_body) and frontend_body.get_child_count() > 0:
		var main_panel: Node = frontend_body.get_child(0)
		var panel_content: Node = main_panel.get_child(0)
		_front_button(panel_content, "PIXEL BATTLE PREVIEW  •  ASMODEUS VS BOAR", _start_battle_preview, 46.0)


func _show_about() -> void:
	super._show_about()
	if is_instance_valid(frontend_body) and frontend_body.get_child_count() > 0:
		var panel_content: Node = frontend_body.get_child(0).get_child(0)
		_front_label(panel_content, "Prototype 005  •  Location-based pixel battle backgrounds, character sprite layer and battle preview.", 15, Color(0.77, 0.84, 0.93))


func _show_event() -> void:
	_hide_pixel_stage()
	super._show_event()


func _draw_interlude() -> void:
	_hide_pixel_stage()
	super._draw_interlude()


func _result(won: bool) -> void:
	_hide_pixel_stage()
	super._result(won)


func _finish_story() -> void:
	_hide_pixel_stage()
	super._finish_story()


func _ensure_pixel_layer() -> void:
	if is_instance_valid(pixel_layer):
		return
	pixel_layer = Control.new()
	pixel_layer.name = "PixelBattleStage"
	pixel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(pixel_layer)
	# Added last so sprites sit on the stage but cannot intercept UI input.
	actor_sprite = _create_battler("PlayerBattler", 0.08, 0.36, 0.30, 0.73)
	enemy_sprite = _create_battler("EnemyBattler", 0.64, 0.33, 0.88, 0.73)
	actor_placeholder = _create_placeholder("PlayerPlaceholder", 0.10, 0.32, 0.36, 0.68)
	enemy_placeholder = _create_placeholder("EnemyPlaceholder", 0.64, 0.32, 0.90, 0.68)
	pixel_layer.hide()


func _create_battler(node_name: String, left: float, top: float, right: float, bottom: float) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = node_name
	sprite.anchor_left = left
	sprite.anchor_top = top
	sprite.anchor_right = right
	sprite.anchor_bottom = bottom
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = Control.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_layer.add_child(sprite)
	return sprite


func _create_placeholder(node_name: String, left: float, top: float, right: float, bottom: float) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.anchor_left = left
	lbl.anchor_top = top
	lbl.anchor_right = right
	lbl.anchor_bottom = bottom
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color(0.93, 0.93, 0.97))
	lbl.add_theme_color_override("font_shadow_color", Color(0.04, 0.04, 0.07, 0.98))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pixel_layer.add_child(lbl)
	return lbl


func _set_battler(rect: TextureRect, placeholder: Label, character_id: String, display_name: String) -> void:
	var sprites: Dictionary = pixel_data.get("sprites", {})
	var texture_file: String = str(sprites.get(character_id, ""))
	if texture_file != "" and ResourceLoader.exists(AREA_ART_ROOT + texture_file):
		rect.texture = load(AREA_ART_ROOT + texture_file)
		rect.show()
		placeholder.hide()
	else:
		rect.texture = null
		rect.hide()
		placeholder.text = display_name.to_upper() + "\n[PIXEL SPRITE PENDING]"
		placeholder.show()


func _set_area_background(area_id: String) -> void:
	var definitions: Array = pixel_data.get("areas", [])
	for entry in definitions:
		var area: Dictionary = entry
		if str(area.get("id", "")) != area_id:
			continue
		var file_name := str(area.get("background", ""))
		if file_name != "" and ResourceLoader.exists(AREA_ART_ROOT + file_name):
			scene_image.texture = load(AREA_ART_ROOT + file_name)
			scene_image.texture_filter = Control.TEXTURE_FILTER_NEAREST
		else:
			scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
			var fallback: String = str(area.get("fallback", "forest_hunt.jpg"))
			if area_id == "thundercloud":
				_background(fallback)
			else:
				_set_story_background(fallback)
		return


func _show_pixel_stage(area_id: String, actor_id: String, target_id: String, player_name: String, enemy_name: String) -> void:
	_read_pixel_data()
	_ensure_pixel_layer()
	if stage_area != area_id or not pixel_layer.visible:
		_set_area_background(area_id)
	stage_area = area_id
	_set_battler(actor_sprite, actor_placeholder, actor_id, player_name)
	_set_battler(enemy_sprite, enemy_placeholder, target_id, enemy_name)
	pixel_layer.show()


func _draw_hunt() -> void:
	super._draw_hunt()
	if hunt_mode and duel != null:
		var target_id := str(duel.enemy.get("id", ""))
		_show_pixel_stage("forest_clearing", str(duel.player.get("id", "asmodeus")), target_id, str(duel.player.get("name", "Asmodeus")), str(duel.enemy.get("name", "Wildlife")))


func _draw_alley() -> void:
	super._draw_alley()
	if alley_mode and wave_engine != null:
		var actor_id := "haniel" if int(wave_engine.wave) == 1 else "asmodeus"
		var enemy_id := "bandit_thug" if int(wave_engine.wave) == 1 else "joren"
		var actor_name := "Haniel + Alric" if int(wave_engine.wave) == 1 else "Asmodeus + Alric"
		var enemy_name := "Thugs" if int(wave_engine.wave) == 1 else "Joren + Thugs"
		_show_pixel_stage("cliffside_alley", actor_id, enemy_id, actor_name, enemy_name)


func _draw_battle() -> void:
	super._draw_battle()
	if hunt_mode or battle_demo:
		return
	if bear_mode and duel != null:
		_show_pixel_stage("forest_clearing", "asmodeus", "grizzly_bear", "Asmodeus", "Grizzly Bear")
	elif not alley_mode and duel != null and fighter != "" and opponent != "":
		_show_pixel_stage("thundercloud", fighter.to_lower(), opponent.to_lower(), fighter, opponent)


func _hit_feedback(target: TextureRect) -> void:
	if not is_instance_valid(target) or not target.visible:
		return
	var tween := create_tween()
	tween.tween_property(target, "modulate", Color(1.0, 0.38, 0.48, 1.0), 0.09)
	tween.tween_property(target, "modulate", Color.WHITE, 0.24)


func _hunt_turn(move_id: String) -> void:
	super._hunt_turn(move_id)
	_hit_feedback(enemy_sprite)


func _alley_turn(move_id: String) -> void:
	super._alley_turn(move_id)
	_hit_feedback(enemy_sprite)


func _bear_visual_effect(move_id: String) -> void:
	super._bear_visual_effect(move_id)
	_hit_feedback(enemy_sprite)


func _start_battle_preview() -> void:
	# Isolated one-on-one battle; does not mutate campaign EXP, inventory or saves.
	battle_demo = true
	bear_mode = false
	hunt_mode = false
	alley_mode = false
	if is_instance_valid(frontend):
		frontend.hide()
	var hero: Dictionary = ContentStore.load_character("asmodeus")
	var target: Dictionary = ContentStore.load_character("wild_boar")
	if hero.is_empty() or target.is_empty():
		battle_demo = false
		_show_menu()
		return
	duel = DuelEngine.new()
	duel.setup(hero, target, selected_profile)
	_ensure_boss_hud()
	_draw_battle_preview()


func _draw_battle_preview() -> void:
	if not battle_demo or duel == null:
		return
	_clear_buttons()
	portraits.hide()
	_set_hp_visible(false)
	boss_hud.show()
	bear_bar.max_value = duel.enemy_max_hp
	bear_bar.value = duel.enemy_hp
	hero_bar.max_value = duel.player_max_hp
	hero_bar.value = duel.player_hp
	bear_hp_label.text = "WILD BOAR    %d / %d HP" % [duel.enemy_hp, duel.enemy_max_hp]
	hero_hp_label.text = "ASMODEUS    %d / %d HP" % [duel.player_hp, duel.player_max_hp]
	heading.text = "PIXEL BATTLE ART PREVIEW"
	subheading.text = "FOREST CLEARING  /  NON-CANON TEST FIGHT"
	speaker.text = "ASMODEUS VS WILD BOAR"
	message.text = "This short test shows the new battle presentation. Your story and EXP are unaffected."
	_show_pixel_stage("forest_clearing", "asmodeus", "wild_boar", "Asmodeus", "Wild Boar")
	for move in duel.player_moves():
		_button(str(move.get("name", "Attack")), Callable(self, "_preview_turn").bind(str(move.get("id", ""))))
	_button("Leave preview", _exit_preview)


func _preview_turn(move_id: String) -> void:
	if not battle_demo or duel == null:
		return
	var outcome: Dictionary = duel.take_turn(move_id)
	if bool(outcome.get("finished", false)):
		_clear_buttons()
		heading.text = "BOAR DEFEATED!" if bool(outcome.get("victory", false)) else "ASMODEUS FALLS"
		subheading.text = "PIXEL BATTLE PREVIEW"
		speaker.text = "BATTLE CONCLUDED"
		message.text = str(outcome.get("message", "")) + "\nNo campaign progress was changed."
		_hit_feedback(enemy_sprite)
		_button("Fight again", _start_battle_preview)
		_button("Return to title", _exit_preview)
	else:
		_draw_battle_preview()
		message.text = str(outcome.get("message", ""))
		_hit_feedback(enemy_sprite)


func _exit_preview() -> void:
	battle_demo = false
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	_hide_pixel_stage()
	_show_menu()

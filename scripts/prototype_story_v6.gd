extends "res://scripts/prototype_story_v5.gd"
## Prototype 006: user-supplied Love Beyond battlers + alley party formation.
## Keeps the existing story, scripted boss rescues, saves and interludes intact.

var ally_sprite: TextureRect
var extra_thug_sprite: TextureRect
var joren_boss_sprite: TextureRect
var ally_label: Label
var extra_thug_label: Label
var joren_boss_label: Label


func _show_menu() -> void:
	super._show_menu()
	if is_instance_valid(frontend_body) and frontend_body.get_child_count() > 0:
		var content: Node = frontend_body.get_child(0).get_child(0)
		_front_button(content, "VIEW NEW CHARACTER SPRITES", Callable(self, "_show_sprite_gallery").bind(0), 45.0)


func _ensure_pixel_layer() -> void:
	super._ensure_pixel_layer()
	if is_instance_valid(ally_sprite):
		return
	ally_sprite = _create_battler("AllyBattler", 0.21, 0.37, 0.37, 0.74)
	extra_thug_sprite = _create_battler("SecondThugBattler", 0.73, 0.37, 0.86, 0.74)
	joren_boss_sprite = _create_battler("JorenBossBattler", 0.86, 0.36, 0.98, 0.74)
	ally_label = _create_placeholder("AllyFallback", 0.21, 0.37, 0.37, 0.74)
	extra_thug_label = _create_placeholder("ThugFallback", 0.73, 0.37, 0.86, 0.74)
	joren_boss_label = _create_placeholder("JorenFallback", 0.86, 0.36, 0.98, 0.74)
	_hide_extra_battlers()


func _hide_extra_battlers() -> void:
	for node in [ally_sprite, extra_thug_sprite, joren_boss_sprite, ally_label, extra_thug_label, joren_boss_label]:
		if is_instance_valid(node):
			node.hide()


func _place_battler(sprite: TextureRect, fallback: Label, left: float, top: float, right: float, bottom: float) -> void:
	for item in [sprite, fallback]:
		item.anchor_left = left
		item.anchor_top = top
		item.anchor_right = right
		item.anchor_bottom = bottom


func _show_pixel_stage(area_id: String, actor_id: String, target_id: String, player_name: String, enemy_name: String) -> void:
	super._show_pixel_stage(area_id, actor_id, target_id, player_name, enemy_name)
	_hide_extra_battlers()
	_place_battler(actor_sprite, actor_placeholder, 0.08, 0.36, 0.30, 0.73)
	_place_battler(enemy_sprite, enemy_placeholder, 0.64, 0.33, 0.88, 0.73)


func _draw_alley() -> void:
	super._draw_alley()
	if not alley_mode or wave_engine == null:
		return
	_ensure_pixel_layer()
	var wave: int = int(wave_engine.wave)
	# Both protagonists and Alric are physically visible in the alley battle.
	_place_battler(actor_sprite, actor_placeholder, 0.05, 0.40, 0.20, 0.72)
	_place_battler(ally_sprite, ally_label, 0.21, 0.38, 0.38, 0.74)
	_set_battler(ally_sprite, ally_label, "alric", "Alric")
	_place_battler(enemy_sprite, enemy_placeholder, 0.59, 0.40, 0.73, 0.74)
	_set_battler(enemy_sprite, enemy_placeholder, "bandit_thug", "Thug 1")
	_place_battler(extra_thug_sprite, extra_thug_label, 0.73, 0.40, 0.86, 0.74)
	_set_battler(extra_thug_sprite, extra_thug_label, "bandit_club", "Thug 2")
	if wave == 2:
		_place_battler(joren_boss_sprite, joren_boss_label, 0.85, 0.39, 0.99, 0.74)
		_set_battler(joren_boss_sprite, joren_boss_label, "joren", "Joren")
	else:
		joren_boss_sprite.hide()
		joren_boss_label.hide()


func _show_sprite_gallery(page: int = 0) -> void:
	_read_pixel_data()
	_ensure_layers()
	_clear_frontend()
	frontend.show()
	_hide_pixel_stage()
	var content: VBoxContainer = _front_panel()
	_front_label(content, "LOVE BEYOND — SPRITE GALLERY", 28)
	_front_label(content, "Extracted from your own character sheets", 16, Color(0.77, 0.87, 0.97))
	var groups: Array = [
		[{"id":"asmodeus","name":"Asmodeus (battle)"},{"id":"haniel","name":"Haniel (battle)"},{"id":"joren","name":"Joren"},{"id":"alric","name":"Alric"}],
		[{"id":"bandit_thug","name":"Knife Thug"},{"id":"bandit_club","name":"Club Thug"},{"id":"grizzly_bear","name":"Bear"},{"id":"wild_boar","name":"Wild Boar"}],
		[{"id":"asmodeus_idle","name":"Asmodeus (neutral)"},{"id":"haniel_idle","name":"Haniel (neutral)"},{"id":"michael","name":"Michael"},{"id":"deer","name":"Deer"}]
	]
	var current_page: int = clampi(page, 0, groups.size() - 1)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 7)
	content.add_child(grid)
	var sprites: Dictionary = pixel_data.get("sprites", {})
	for entry in groups[current_page]:
		var data: Dictionary = entry
		var id := str(data.get("id", ""))
		var image_file := str(sprites.get(id, ""))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(346, 174)
		grid.add_child(card)
		var column := VBoxContainer.new()
		card.add_child(column)
		var picture := TextureRect.new()
		picture.custom_minimum_size = Vector2(320, 143)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = Control.TEXTURE_FILTER_NEAREST
		var path := AREA_ART_ROOT + image_file
		if image_file != "" and ResourceLoader.exists(path):
			picture.texture = load(path)
		column.add_child(picture)
		_front_label(column, str(data.get("name", id)), 16)
	_front_label(content, "Page %d of %d" % [current_page + 1, groups.size()], 14, Color(0.72, 0.79, 0.86))
	var nav := HBoxContainer.new()
	content.add_child(nav)
	if current_page > 0:
		_front_button(nav, "PREVIOUS", Callable(self, "_show_sprite_gallery").bind(current_page - 1), 42.0)
	if current_page + 1 < groups.size():
		_front_button(nav, "NEXT", Callable(self, "_show_sprite_gallery").bind(current_page + 1), 42.0)
	_front_button(content, "BACK TO TITLE", _show_menu, 44.0)

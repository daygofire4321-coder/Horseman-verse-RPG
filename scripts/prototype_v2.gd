extends "res://scripts/prototype_modular.gd"
## Prototype 002: illustrated front end + scripted combat feedback.
## Reuses modular story, battle rules and save data. No new textures required.

var frontend: Control
var frontend_body: VBoxContainer
var fx_layer: Control
var busy_animating := false
var animate_hp_next := false


func _ensure_layers() -> void:
	if is_instance_valid(frontend):
		return

	fx_layer = Control.new()
	fx_layer.name = "BattleEffects"
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)

	frontend = Control.new()
	frontend.name = "FrontEnd"
	frontend.mouse_filter = Control.MOUSE_FILTER_STOP
	frontend.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frontend)

	var veil := ColorRect.new()
	veil.color = Color(0.018, 0.026, 0.055, 0.81)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frontend.add_child(veil)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frontend.add_child(center)

	frontend_body = VBoxContainer.new()
	frontend_body.custom_minimum_size = Vector2(785, 0)
	frontend_body.add_theme_constant_override("separation", 12)
	center.add_child(frontend_body)


func _clear_frontend() -> void:
	for child in frontend_body.get_children():
		frontend_body.remove_child(child)
		child.queue_free()


func _front_panel() -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(785, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.063, 0.11, 0.97)
	style.border_color = Color(0.48, 0.69, 0.88, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(23)
	panel.add_theme_stylebox_override("panel", style)
	frontend_body.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	return content


func _front_label(parent: Node, value: String, size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _front_button(parent: Node, value: String, action: Callable, height: float = 54.0) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _show_menu() -> void:
	super._show_menu()
	_ensure_layers()
	_clear_frontend()
	frontend.visible = true
	var content := _front_panel()
	_front_label(content, "THE PALE HORSEMAN", 35, Color(0.86, 0.93, 1.0))
	_front_label(content, "STORY-DRIVEN FANTASY RPG", 17, Color(0.62, 0.79, 0.95))
	_front_label(content, "LOVE BEYOND HEAVEN OR HELL", 23)
	_front_label(content, "Prototype 002  •  The First Encounter", 17, Color(0.77, 0.82, 0.92))
	_front_button(content, "BEGIN THE CHAPTER", _start_dialogue)
	_front_button(content, "QUICK BATTLE", _choose_fighter)
	_front_button(content, "ABOUT THIS BUILD", _show_about)
	_front_label(content, "Your progress and difficulty are stored on this device.", 14, Color(0.70, 0.75, 0.84))


func _show_about() -> void:
	_ensure_layers()
	_clear_frontend()
	frontend.visible = true
	var content := _front_panel()
	_front_label(content, "PROTOTYPE 002", 31)
	_front_label(content, "Love Beyond: Haniel vs Asmodeus", 20)
	_front_label(content, "A test of visual novel dialogue, difficulty settings, combat\nfeedback, and character data. Story text and balance are placeholders.", 16)
	_front_label(content, "Original audiobook artwork is used for the backgrounds and portraits.\nThis is not the complete campaign.", 15, Color(0.78, 0.86, 0.94))
	_front_button(content, "BACK TO TITLE", _show_menu)


func _start_dialogue() -> void:
	if is_instance_valid(frontend):
		frontend.hide()
	super._start_dialogue()


func _choose_fighter() -> void:
	super._choose_fighter()
	_ensure_layers()
	_clear_frontend()
	frontend.show()

	var content := _front_panel()
	_front_label(content, "CHOOSE YOUR FIGHTER", 31)
	_front_label(content, "Choose who you control in this non-canon test duel.", 16, Color(0.72, 0.84, 0.95))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	_character_card(row, "Haniel", "haniel_portrait.jpg", "ARCHANGEL", "Divine Arrow  •  Heal",
		Callable(self, "_show_difficulty_picker").bind("Haniel", "Asmodeus"))
	_character_card(row, "Asmodeus", "asmodeus_portrait.jpg", "DEMON LORD", "Black Ice  •  Ice Guard",
		Callable(self, "_show_difficulty_picker").bind("Asmodeus", "Haniel"))
	_front_button(content, "BACK TO TITLE", _show_menu, 43.0)


func _character_card(parent: Node, character_name: String, portrait_file: String, role: String, powers: String, chosen: Callable) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(335, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.077, 0.105, 0.18, 1.0)
	style.border_color = Color(0.39, 0.60, 0.79, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	style.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	card.add_child(body)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(290, 135)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(ASSET_ROOT + portrait_file):
		portrait.texture = load(ASSET_ROOT + portrait_file)
	body.add_child(portrait)

	_front_label(body, character_name.to_upper(), 23)
	_front_label(body, role, 14, Color(0.62, 0.82, 1.0))
	_front_label(body, powers, 15, Color(0.86, 0.89, 0.94))
	_front_button(body, "SELECT " + character_name.to_upper(), chosen, 46.0)


func _show_difficulty_picker(chosen: String, enemy_name: String) -> void:
	_ensure_layers()
	_clear_frontend()
	frontend.show()
	var content := _front_panel()
	_front_label(content, "CHOOSE DIFFICULTY", 31)
	_front_label(content, "Fighting as %s  •  Your selection is remembered" % chosen, 17)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for profile in difficulty_data.get("profiles", []):
		var difficulty_id := str(profile.get("id", "normal"))
		var difficulty_name := str(profile.get("name", difficulty_id)).to_upper()
		var hp_percent := int(round(float(profile.get("enemy_hp_multiplier", 1.0)) * 100.0))
		var damage_percent := int(round(float(profile.get("enemy_damage_multiplier", 1.0)) * 100.0))
		var caption := "%s\nEnemy HP %d%%  •  Damage %d%%" % [difficulty_name, hp_percent, damage_percent]
		var btn := _front_button(grid, caption, Callable(self, "_begin_with_difficulty").bind(chosen, enemy_name, difficulty_id), 83.0)
		btn.custom_minimum_size.x = 345
	_front_button(content, "BACK TO FIGHTERS", _choose_fighter, 45.0)


func _begin_with_difficulty(chosen: String, enemy_name: String, difficulty_id: String) -> void:
	frontend.hide()
	busy_animating = false
	super._begin_with_difficulty(chosen, enemy_name, difficulty_id)


func _start_battle(chosen: String, enemy_name: String) -> void:
	busy_animating = false
	animate_hp_next = false
	super._start_battle(chosen, enemy_name)


func _portrait_center(character: String) -> Vector2:
	if not is_instance_valid(fx_layer) or portraits.get_child_count() < 3:
		return size / 2.0
	var card_index := 0 if character == "Haniel" else 2
	var portrait_card: Control = portraits.get_child(card_index) as Control
	return portrait_card.get_global_rect().get_center() - fx_layer.global_position


func _portrait_rect(character: String) -> Rect2:
	var card_index := 0 if character == "Haniel" else 2
	var portrait_card: Control = portraits.get_child(card_index) as Control
	return Rect2(portrait_card.global_position - fx_layer.global_position, portrait_card.size)


func _flash(character: String, tint: Color) -> void:
	if not is_instance_valid(fx_layer):
		return
	var rect := _portrait_rect(character)
	var highlight := ColorRect.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.position = rect.position
	highlight.size = rect.size
	highlight.color = tint
	fx_layer.add_child(highlight)
	var pulse := create_tween()
	pulse.tween_property(highlight, "modulate:a", 0.0, 0.30)
	pulse.tween_callback(highlight.queue_free)


func _floating_number(character: String, text_value: String, tint: Color) -> void:
	var word := Label.new()
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.text = text_value
	word.position = _portrait_center(character) - Vector2(55, 22)
	word.add_theme_font_size_override("font_size", 27)
	word.add_theme_color_override("font_color", tint)
	fx_layer.add_child(word)
	var rise := create_tween().set_parallel(true)
	rise.tween_property(word, "position:y", word.position.y - 48.0, 0.58)
	rise.tween_property(word, "modulate:a", 0.0, 0.58)
	rise.chain().tween_callback(word.queue_free)


func _play_projectile(tint: Color, destination: String, outcome: Dictionary) -> void:
	var start := _portrait_center(fighter)
	var target := _portrait_center(destination)
	var beam := ColorRect.new()
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.color = tint
	beam.size = Vector2(118, 9)
	beam.pivot_offset = Vector2(59, 4)
	beam.rotation = (target - start).angle()
	beam.position = start - beam.pivot_offset
	fx_layer.add_child(beam)

	var halo := ColorRect.new()
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.color = Color(tint.r, tint.g, tint.b, 0.25)
	halo.size = Vector2(144, 23)
	halo.pivot_offset = Vector2(72, 11)
	halo.rotation = beam.rotation
	halo.position = start - halo.pivot_offset
	fx_layer.add_child(halo)

	var shot := create_tween().set_parallel(true)
	shot.tween_property(beam, "position", target - beam.pivot_offset, 0.36).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	shot.tween_property(halo, "position", target - halo.pivot_offset, 0.36).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	shot.chain().tween_callback(Callable(self, "_hit_and_clear").bind(destination, beam, halo, tint, outcome))


func _hit_and_clear(destination: String, beam: ColorRect, halo: ColorRect, tint: Color, outcome: Dictionary) -> void:
	if is_instance_valid(beam):
		beam.queue_free()
	if is_instance_valid(halo):
		halo.queue_free()
	_flash(destination, Color(tint.r, tint.g, tint.b, 0.56))
	_damage_number(destination)
	_schedule_effect_completion(outcome, 0.25)


func _damage_number(destination: String) -> void:
	# The rules module already resolved the turn, so display the move's nominal
	# damage here. The exact combat results are displayed in the battle log.
	_floating_number(destination, "HIT!", Color(1.0, 0.91, 0.72))


func _play_black_ice(destination: String, outcome: Dictionary) -> void:
	var midpoint := _portrait_center(destination)
	var ice_color := Color(0.48, 0.33, 0.88, 0.93)
	for n in range(7):
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(-13, 44), Vector2(0, -61), Vector2(16, 36), Vector2(3, 17)
		])
		shard.color = ice_color if n % 2 == 0 else Color(0.12, 0.14, 0.29, 0.95)
		var offset_x := float(n - 3) * 29.0
		shard.position = midpoint + Vector2(offset_x, 65)
		shard.scale = Vector2(0.12, 0.12)
		fx_layer.add_child(shard)
		var grow := create_tween().set_parallel(true)
		grow.tween_property(shard, "scale", Vector2(0.8, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		grow.tween_property(shard, "position:y", midpoint.y + 5.0, 0.25)
		grow.chain().tween_property(shard, "modulate:a", 0.0, 0.22)
		grow.chain().tween_callback(shard.queue_free)
	_flash(destination, Color(0.33, 0.25, 0.55, 0.50))
	_schedule_effect_completion(outcome, 0.52)


func _play_support(kind: String, outcome: Dictionary) -> void:
	var target := _portrait_center(fighter)
	var ring := ColorRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.color = Color(0.45, 1.0, 0.83, 0.48) if kind == "heal" else Color(0.28, 0.43, 0.96, 0.54)
	ring.position = target - Vector2(40, 55)
	ring.size = Vector2(80, 110)
	ring.pivot_offset = Vector2(40, 55)
	ring.scale = Vector2(0.25, 0.25)
	fx_layer.add_child(ring)
	var grow := create_tween().set_parallel(true)
	grow.tween_property(ring, "scale", Vector2(2.1, 2.1), 0.45).set_trans(Tween.TRANS_SINE)
	grow.tween_property(ring, "modulate:a", 0.0, 0.45)
	grow.chain().tween_callback(ring.queue_free)
	if kind == "heal":
		_floating_number(fighter, "+HEAL", Color(0.63, 1.0, 0.78))
	else:
		_floating_number(fighter, "GUARD", Color(0.59, 0.78, 1.0))
	_schedule_effect_completion(outcome, 0.49)


func _schedule_effect_completion(outcome: Dictionary, delay: float) -> void:
	var wait := create_tween()
	wait.tween_interval(delay)
	wait.tween_callback(Callable(self, "_finish_animated_turn").bind(outcome))


func _turn(move_id: String) -> void:
	if busy_animating or duel == null:
		return
	var move: Dictionary = {}
	for candidate in duel.player_moves():
		if str(candidate.get("id", "")) == move_id:
			move = candidate
			break
	if move.is_empty():
		return

	busy_animating = true
	for child in action_row.get_children():
		if child is Button:
			(child as Button).disabled = true

	var outcome: Dictionary = duel.take_turn(move_id)
	player_hp = int(outcome.get("player_hp", player_hp))
	enemy_hp = int(outcome.get("enemy_hp", enemy_hp))
	last_message = str(outcome.get("message", ""))
	speaker.text = "ACTION"
	message.text = "%s uses %s!" % [fighter, str(move.get("name", "Attack"))]

	match str(move.get("kind", "damage")):
		"heal", "guard":
			_play_support(str(move.get("kind", "heal")), outcome)
		"damage":
			if move_id == "black_ice":
				_play_black_ice(opponent, outcome)
			else:
				var tint := Color(0.20, 0.80, 1.0) if move_id == "divine_arrow" else Color(1.0, 0.88, 0.66)
				_play_projectile(tint, opponent, outcome)


func _update_hp() -> void:
	if duel == null:
		return
	var prior_haniel := haniel_hp.value
	var prior_asmo := asmodeus_hp.value
	super._update_hp()
	if animate_hp_next:
		var goal_haniel := haniel_hp.value
		var goal_asmo := asmodeus_hp.value
		haniel_hp.value = prior_haniel
		asmodeus_hp.value = prior_asmo
		var hp_motion := create_tween().set_parallel(true)
		hp_motion.tween_property(haniel_hp, "value", goal_haniel, 0.33)
		hp_motion.tween_property(asmodeus_hp, "value", goal_asmo, 0.33)
		animate_hp_next = false


func _finish_animated_turn(outcome: Dictionary) -> void:
	if not busy_animating:
		return
	# Show the opponent's response after the player attack and before HP changes.
	if str(outcome.get("message", "")).contains("deals"):
		_flash(fighter, Color(1.0, 0.24, 0.28, 0.35))
	animate_hp_next = true
	_update_hp()
	message.text = str(outcome.get("message", ""))
	speaker.text = "BATTLE"
	if bool(outcome.get("finished", false)):
		var ending := create_tween()
		ending.tween_interval(0.43)
		ending.tween_callback(Callable(self, "_finish_battle").bind(bool(outcome.get("victory", false))))
	else:
		# Let the HP animation finish before the next redraw resets its value.
		var resume := create_tween()
		resume.tween_interval(0.36)
		resume.tween_callback(_resume_battle)


func _resume_battle() -> void:
	busy_animating = false
	_draw_battle()


func _finish_battle(won: bool) -> void:
	busy_animating = false
	_result(won)

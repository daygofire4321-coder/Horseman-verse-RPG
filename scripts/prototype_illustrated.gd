extends Control

# Prototype 001, visual pass. All images are optional: text/battles still work
# before the matching asset pack is copied into the Godot project.
const ASSET_ROOT = "res://assets/love_beyond/prototype_001/"
const OPENING_LINES = [
	["NARRATOR", "High above the world, an angel and a demon confront each other within a thundercloud."],
	["ASMODEUS", "You are awfully persistent for someone who doesn't speak."],
	["HANIEL", "..."],
	["NARRATOR", "Blue lightning rips through the clouds. Haniel raises her invisible bow as black ice forms around Asmodeus."],
	["ASMODEUS", "Fine. Let's settle this."]
]

var line_index := 0
var fighter := ""
var opponent := ""
var player_hp := 100
var enemy_hp := 100
var defending := false
var last_message := ""

var scene_image: TextureRect
var heading: Label
var subheading: Label
var speaker: Label
var message: Label
var action_row: HBoxContainer
var haniel_hp: ProgressBar
var asmodeus_hp: ProgressBar

func _ready() -> void:
	get_window().min_size = Vector2i(640, 360)
	_build_ui()
	_show_menu()

func _background(path: String) -> void:
	if ResourceLoader.exists(ASSET_ROOT + path):
		scene_image.texture = load(ASSET_ROOT + path)

func _card(character: String, filename: String) -> ProgressBar:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.065, 0.11, 0.91)
	style.border_color = Color(0.51, 0.67, 0.88, 0.55) if character == "HANIEL" else Color(0.90, 0.38, 0.43, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(235, 220)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	card.add_child(column)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(230, 145)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(ASSET_ROOT + filename):
		portrait.texture = load(ASSET_ROOT + filename)
	column.add_child(portrait)

	var name_label := Label.new()
	name_label.text = character
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	column.add_child(name_label)

	var hp := ProgressBar.new()
	hp.max_value = 100
	hp.value = 100
	hp.show_percentage = false
	hp.custom_minimum_size.y = 14
	column.add_child(hp)

	var hp_text := Label.new()
	hp_text.name = "HPText"
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.text = "100 / 100 HP"
	column.add_child(hp_text)

	# Name and portrait stay visible during the visual novel. HP hides.
	hp.visible = false
	hp_text.visible = false
	portraits.add_child(card)
	return hp

var portraits: HBoxContainer

func _build_ui() -> void:
	var fill := ColorRect.new()
	fill.color = Color("#08101e")
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fill)

	scene_image = TextureRect.new()
	scene_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scene_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(scene_image)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.06, 0.34)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 18)
	add_child(outer)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	outer.add_child(stack)

	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 29)
	stack.add_child(heading)

	subheading = Label.new()
	subheading.add_theme_font_size_override("font_size", 15)
	stack.add_child(subheading)

	portraits = HBoxContainer.new()
	portraits.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portraits.add_theme_constant_override("separation", 12)
	stack.add_child(portraits)
	haniel_hp = _card("HANIEL", "haniel_portrait.jpg")

	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portraits.add_child(space)
	asmodeus_hp = _card("ASMODEUS", "asmodeus_portrait.jpg")

	var dialogue_panel := PanelContainer.new()
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = Color(0.035, 0.05, 0.10, 0.94)
	box_style.border_color = Color(0.43, 0.55, 0.75, 0.9)
	box_style.set_border_width_all(2)
	box_style.set_corner_radius_all(13)
	box_style.set_content_margin_all(13)
	dialogue_panel.add_theme_stylebox_override("panel", box_style)
	stack.add_child(dialogue_panel)

	var text_stack := VBoxContainer.new()
	text_stack.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(text_stack)

	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size", 18)
	text_stack.add_child(speaker)

	message = Label.new()
	message.add_theme_font_size_override("font_size", 20)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 74
	text_stack.add_child(message)

	action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	text_stack.add_child(action_row)

func _clear_buttons() -> void:
	for child in action_row.get_children():
		action_row.remove_child(child)
		child.queue_free()

func _button(label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	action_row.add_child(button)

func _set_hp_visible(visible_bars: bool) -> void:
	haniel_hp.visible = visible_bars
	asmodeus_hp.visible = visible_bars
	haniel_hp.get_parent().get_node("HPText").visible = visible_bars
	asmodeus_hp.get_parent().get_node("HPText").visible = visible_bars

func _show_menu() -> void:
	_clear_buttons()
	_background("storm_clash.jpg")
	_set_hp_visible(false)
	heading.text = "PALE HORSEMAN RPG"
	subheading.text = "LOVE BEYOND  /  PROTOTYPE 001"
	speaker.text = "THE FIRST ENCOUNTER"
	message.text = "A visual novel / turn-based RPG test. Art and dialogue are temporary while we build the production systems."
	_button("Begin", _start_dialogue)

func _start_dialogue() -> void:
	line_index = 0
	_background("storm_duel.jpg")
	_show_dialogue()

func _show_dialogue() -> void:
	_clear_buttons()
	_set_hp_visible(false)
	heading.text = "THE FIRST ENCOUNTER"
	subheading.text = "LOVE BEYOND  /  HIGH ABOVE THE WORLD"
	speaker.text = str(OPENING_LINES[line_index][0])
	message.text = str(OPENING_LINES[line_index][1])
	if line_index + 1 < OPENING_LINES.size():
		_button("Continue", _advance_dialogue)
	else:
		_button("Choose your fighter", _choose_fighter)

func _advance_dialogue() -> void:
	line_index += 1
	_show_dialogue()

func _choose_fighter() -> void:
	_clear_buttons()
	_set_hp_visible(false)
	heading.text = "CHOOSE YOUR FIGHTER"
	subheading.text = "THE FIRST DUEL"
	speaker.text = "YOUR PERSPECTIVE"
	message.text = "Haniel uses divine arrows and healing. Asmodeus commands black ice and defensive magic."
	_button("Play as Haniel", func(): _start_battle("Haniel", "Asmodeus"))
	_button("Play as Asmodeus", func(): _start_battle("Asmodeus", "Haniel"))

func _start_battle(chosen: String, enemy: String) -> void:
	fighter = chosen
	opponent = enemy
	player_hp = 100
	enemy_hp = 100
	defending = false
	last_message = "Lightning flashes around the two airborne fighters. The duel begins!"
	_background("storm_duel.jpg")
	_draw_battle()

func _update_hp() -> void:
	var haniel_value := player_hp if fighter == "Haniel" else enemy_hp
	var asmo_value := player_hp if fighter == "Asmodeus" else enemy_hp
	haniel_hp.value = haniel_value
	asmodeus_hp.value = asmo_value
	haniel_hp.get_parent().get_node("HPText").text = "%d / 100 HP" % haniel_value
	asmodeus_hp.get_parent().get_node("HPText").text = "%d / 100 HP" % asmo_value

func _draw_battle() -> void:
	_clear_buttons()
	_set_hp_visible(true)
	_update_hp()
	heading.text = "THE FIRST DUEL"
	subheading.text = "YOU CONTROL: %s    |    OPPONENT: %s" % [fighter.to_upper(), opponent.to_upper()]
	speaker.text = "BATTLE"
	message.text = last_message
	_button("Attack · 15", func(): _turn("attack"))
	if fighter == "Haniel":
		_button("Divine Arrow · 23", func(): _turn("special"))
		_button("Heal · +20", func(): _turn("heal"))
	else:
		_button("Black Ice · 23", func(): _turn("special"))
		_button("Ice Guard", func(): _turn("guard"))

func _turn(action: String) -> void:
	defending = false
	match action:
		"attack":
			enemy_hp = max(0, enemy_hp - 15)
			last_message = "%s attacks!" % fighter
		"special":
			enemy_hp = max(0, enemy_hp - 23)
			last_message = "%s uses %s!" % [fighter, "Divine Arrow" if fighter == "Haniel" else "Black Ice"]
		"heal":
			player_hp = min(100, player_hp + 20)
			last_message = "Haniel heals herself."
		"guard":
			defending = true
			last_message = "Asmodeus shields himself with black ice."
	if enemy_hp <= 0:
		_result(true)
		return

	var incoming := 17
	if opponent == "Haniel" and enemy_hp <= 35:
		enemy_hp = min(100, enemy_hp + 14)
		last_message += "\nHaniel restores 14 HP."
	else:
		if defending:
			incoming = 6
		player_hp = max(0, player_hp - incoming)
		last_message += "\n%s deals %d damage." % [opponent, incoming]
	if player_hp <= 0:
		_result(false)
	else:
		_draw_battle()

func _result(won: bool) -> void:
	_clear_buttons()
	_background("storm_clash.jpg")
	_set_hp_visible(false)
	heading.text = "VICTORY" if won else "DEFEAT"
	subheading.text = "THE FIRST DUEL"
	speaker.text = "YOU FOUGHT AS %s" % fighter.to_upper()
	message.text = ("You won the test battle!" if won else "You lost the test battle.") + "\nThis non-canon test outcome returns to the same story point."
	_button("Fight as the other character", _choose_fighter)
	_button("Back to title", _show_menu)

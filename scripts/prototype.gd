extends Control

# Prototype 001: placeholder dialogue -> fighter selection -> duel -> ending.
var lines := [
	["NARRATOR", "Within a quiet cave, an archangel and a demon face each other."],
	["ASMODEUS", "You are awfully persistent for someone who doesn't speak."],
	["HANIEL", "..."],
	["NARRATOR", "Haniel lifts her invisible bow. Black ice gathers at Asmodeus's feet."],
	["ASMODEUS", "Fine. Let's settle this."]
]
var current_line := 0
var fighter := ""
var opponent := ""
var player_hp := 100
var enemy_hp := 100
var defending := false
var status := ""

var heading: Label
var details: Label
var body: Label
var actions: VBoxContainer

func _ready() -> void:
	get_window().min_size = Vector2i(640, 360)
	_make_interface()
	_show_menu()

func _make_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#111827")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 15)
	margin.add_child(stack)

	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 30)
	stack.add_child(heading)

	details = Label.new()
	details.add_theme_font_size_override("font_size", 18)
	stack.add_child(details)

	body = Label.new()
	body.add_theme_font_size_override("font_size", 23)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(body)

	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	stack.add_child(actions)

func _clear_buttons() -> void:
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()

func _add_button(caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 46)
	button.pressed.connect(action)
	actions.add_child(button)

func _show_menu() -> void:
	_clear_buttons()
	heading.text = "PALE HORSEMAN RPG"
	details.text = "Prototype 001 | Love Beyond"
	body.text = "THE FIRST ENCOUNTER\n\nDialogue and combat use temporary text-only assets."
	_add_button("Begin", _start_dialogue)

func _start_dialogue() -> void:
	current_line = 0
	_show_line()

func _show_line() -> void:
	_clear_buttons()
	heading.text = "THE FIRST ENCOUNTER"
	details.text = str(lines[current_line][0])
	body.text = str(lines[current_line][1])
	if current_line + 1 < lines.size():
		_add_button("Continue", _next_line)
	else:
		_add_button("Choose your fighter", _choose_fighter)

func _next_line() -> void:
	current_line += 1
	_show_line()

func _choose_fighter() -> void:
	_clear_buttons()
	heading.text = "CHOOSE YOUR FIGHTER"
	details.text = "Both characters use the same combat engine."
	body.text = "HANIEL: divine bow and healing.\n\nASMODEUS: black ice and defense."
	_add_button("Fight as Haniel", func(): _start_battle("Haniel", "Asmodeus"))
	_add_button("Fight as Asmodeus", func(): _start_battle("Asmodeus", "Haniel"))

func _start_battle(chosen: String, foe: String) -> void:
	fighter = chosen
	opponent = foe
	player_hp = 100
	enemy_hp = 100
	defending = false
	status = "The duel begins!"
	_show_battle()

func _show_battle() -> void:
	_clear_buttons()
	heading.text = "THE FIRST DUEL"
	details.text = "%s: %d HP   |   %s: %d HP" % [fighter, player_hp, opponent, enemy_hp]
	body.text = status + "\n\nChoose an action."
	_add_button("Attack (15 damage)", func(): _take_turn("attack"))
	if fighter == "Haniel":
		_add_button("Divine Arrow (23 damage)", func(): _take_turn("special"))
		_add_button("Heal (20 HP)", func(): _take_turn("heal"))
	else:
		_add_button("Black Ice (23 damage)", func(): _take_turn("special"))
		_add_button("Ice Guard (reduce next hit)", func(): _take_turn("guard"))

func _take_turn(action: String) -> void:
	defending = false
	match action:
		"attack":
			enemy_hp = max(0, enemy_hp - 15)
			status = "%s attacks!" % fighter
		"special":
			enemy_hp = max(0, enemy_hp - 23)
			status = "%s uses %s!" % [fighter, "Divine Arrow" if fighter == "Haniel" else "Black Ice"]
		"heal":
			player_hp = min(100, player_hp + 20)
			status = "Haniel heals herself."
		"guard":
			defending = true
			status = "Asmodeus braces behind black ice."
	if enemy_hp <= 0:
		_show_result(true)
		return

	# Simple deterministic enemy AI, deliberately easy to test.
	var incoming := 17
	if opponent == "Haniel" and enemy_hp <= 35:
		enemy_hp = min(100, enemy_hp + 14)
		status += "\nHaniel restores 14 HP."
	else:
		if defending:
			incoming = 6
		player_hp = max(0, player_hp - incoming)
		status += "\n%s deals %d damage." % [opponent, incoming]

	if player_hp <= 0:
		_show_result(false)
	else:
		_show_battle()

func _show_result(victory: bool) -> void:
	_clear_buttons()
	heading.text = "VICTORY" if victory else "DEFEAT"
	details.text = "You played as %s." % fighter
	body.text = ("You won the test battle!" if victory else "You lost the test battle.") + "\n\nBoth outcomes return to the same story point. Final dialogue will replace this placeholder."
	_add_button("Try the other fighter", _choose_fighter)
	_add_button("Return to title", _show_menu)

extends "res://scripts/prototype_story_v9.gd"
## Prototype 010 — Three-member party management and Pokemon/Digimon-like sheets.
## The existing story battles are still scripted; team combat comes later.

const PartyEngine = preload("res://scripts/core/party_engine.gd")
const PARTY_CONFIG_PATH := "res://data/party/love_beyond.json"

var party_engine = null
var party_config: Dictionary = {}
var party_return_to_daily := false
var party_notice := ""
var party_disable_disk_writes := false


func _party_load() -> void:
	if party_config.is_empty():
		party_config = ContentStore.read_dictionary(PARTY_CONFIG_PATH)
	if party_engine == null:
		party_engine = PartyEngine.new()
	party_engine.begin(save_data, party_config)


func _record_part(part: int) -> void:
	super._record_part(part)
	if party_engine != null:
		_party_load()


func _show_menu() -> void:
	super._show_menu()
	if not is_instance_valid(frontend_body) or frontend_body.get_child_count() == 0:
		return
	var panel: Node = frontend_body.get_child(0)
	var content: Node = panel.get_child(0)
	_front_button(content, "PARTY & CHARACTER SHEETS", Callable(self, "_show_party_menu").bind(false), 45.0)


func _draw_interlude() -> void:
	super._draw_interlude()
	if not is_instance_valid(frontend_body):
		return
	var scroll: ScrollContainer = frontend_body.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	if content != null:
		_front_button(content, "PARTY & CHARACTER SHEETS", Callable(self, "_show_party_menu").bind(true), 44.0)


func _show_party_menu(from_daily: bool = false) -> void:
	party_return_to_daily = from_daily and interlude_mode
	party_notice = ""
	_party_load()
	_render_party_overview()


func _party_panel(title_text: String, subtitle: String) -> VBoxContainer:
	_ensure_layers()
	_hide_pixel_stage()
	_clear_frontend()
	frontend.show()
	portraits.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	var content: VBoxContainer = _front_panel()
	var panel: PanelContainer = content.get_parent() as PanelContainer
	var scroll := ScrollContainer.new()
	scroll.name = "PartyPanelScroll"
	scroll.custom_minimum_size = Vector2(815, minf(614.0, get_viewport_rect().size.y * 0.86))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	frontend_body.add_child(scroll)
	frontend_body.remove_child(panel)
	scroll.add_child(panel)
	_front_label(content, title_text, 28)
	_front_label(content, subtitle, 16, Color(0.76, 0.84, 0.95))
	return content


func _render_party_overview() -> void:
	if party_engine == null:
		_party_load()
	_set_area_background("forest_camp")
	var content := _party_panel("YOUR PARTY", "Three active slots  •  Unlocked allies only")
	if party_notice != "":
		var notice := _front_label(content, party_notice, 16, Color(0.99, 0.83, 0.65))
		notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 9)
	content.add_child(slots)
	for i in range(3):
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 228
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(column)
		var id := str(party_engine.active[i])
		var title_text := "SLOT %d\n%s" % [i + 1, "EMPTY" if id == "" else id.to_upper()]
		var open_action: Callable = Callable(self, "_edit_party_slot").bind(i) if id == "" else Callable(self, "_show_character_sheet").bind(id)
		var card := _front_button(column, title_text, open_action, 78.0)
		card.name = "PartySlot_%d" % i
		var edit := _front_button(column, "EDIT SLOT %d" % [i + 1], Callable(self, "_edit_party_slot").bind(i), 40.0)
		edit.name = "PartyEdit_%d" % i

	_front_label(content, "AVAILABLE CHARACTER SHEETS", 19)
	for raw_id in party_config.get("character_order", []):
		var id := str(raw_id)
		var member: Dictionary = party_config.get("characters", {}).get(id, {})
		var available: bool = party_engine.is_unlocked(id)
		var label_text := id.to_upper()
		if not available:
			label_text += "  •  UNLOCK AFTER PART %d" % int(member.get("unlock_after_part", 6))
		elif party_engine.active.has(id):
			label_text += "  •  ACTIVE"
		else:
			label_text += "  •  RESERVE"
		var row_button := _front_button(content, label_text, Callable(self, "_show_character_sheet").bind(id), 41.0)
		row_button.name = "PartyMember_" + id
		row_button.disabled = not available

	_front_label(content, "Roster choices are saved. Story fights still use their authored participants until party combat is implemented.", 14, Color(0.76, 0.85, 0.91)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "BACK", _close_party_menu, 43.0)


func _edit_party_slot(index: int) -> void:
	if party_engine == null:
		_party_load()
	var content := _party_panel("EDIT ACTIVE SLOT %d" % [index + 1], "Choose an available ally. Selecting another active ally swaps positions.")
	for raw_id in party_config.get("character_order", []):
		var id := str(raw_id)
		var available: bool = party_engine.is_unlocked(id)
		var entry: Dictionary = party_config.get("characters", {}).get(id, {})
		var label_text := id.to_upper() if available else "%s  •  UNLOCKS AFTER PART %d" % [id.to_upper(), int(entry.get("unlock_after_part", 6))]
		var choice := _front_button(content, label_text, Callable(self, "_assign_party_member").bind(index, id), 51.0)
		choice.name = "PartyPick_" + id
		choice.disabled = not available
	var clear := _front_button(content, "LEAVE SLOT EMPTY", Callable(self, "_assign_party_member").bind(index, ""), 48.0)
	clear.name = "PartyPick_Empty"
	clear.disabled = party_engine.member_count() <= 1 and str(party_engine.active[index]) != ""
	_front_button(content, "BACK TO PARTY", _render_party_overview, 43.0)


func _assign_party_member(index: int, id: String) -> void:
	if party_engine == null:
		_party_load()
	if party_engine.assign(index, id):
		party_engine.write_to(save_data)
		if not party_disable_disk_writes:
			SaveStore.write_save(save_data)
		party_notice = "Party updated and saved." if not party_disable_disk_writes else "Party updated."
	else:
		party_notice = party_engine.error_text
	_render_party_overview()


func _show_character_sheet(id: String) -> void:
	if party_engine == null:
		_party_load()
	if not party_engine.is_unlocked(id):
		party_notice = "You haven't unlocked that ally yet."
		_render_party_overview()
		return
	var stats: Dictionary = party_engine.sheet(id, save_data)
	if stats.is_empty():
		party_notice = "This character's data could not be loaded."
		_render_party_overview()
		return
	var content := _party_panel(str(stats.get("name", id)).to_upper(), str(stats.get("role", "")) + "  •  LEVEL %d" % int(stats.get("level", 1)))
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 13)
	content.add_child(layout)
	var sprite := TextureRect.new()
	sprite.name = "PartyCharacterSprite"
	sprite.custom_minimum_size = Vector2(155, 170)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_read_pixel_data()
	var sprite_file := str(pixel_data.get("sprites", {}).get(id, id + ".png"))
	if ResourceLoader.exists(AREA_ART_ROOT + sprite_file):
		sprite.texture = load(AREA_ART_ROOT + sprite_file)
	layout.add_child(sprite)

	var stat_column := VBoxContainer.new()
	stat_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(stat_column)
	_front_label(stat_column, "HP %d / %d    LEVEL %d    EXP %d / %d" % [
		int(stats.get("hp", 0)), int(stats.get("max_hp", 100)),
		int(stats.get("level", 1)), int(stats.get("xp", 0)),
		int(stats.get("xp_target", 30))], 16)
	_front_label(stat_column, "ATK %d     DEF %d     SPD %d" % [
		int(stats.get("attack", 0)), int(stats.get("defense", 0)),
		int(stats.get("speed", 0))], 17)
	_front_label(stat_column, "ATK/DEF/SPD are prototype sheet stats, not combat modifiers yet.", 12, Color(0.79, 0.83, 0.90)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var party_slot := int(stats.get("party_slot", -1))
	_front_label(stat_column, "ACTIVE SLOT %d" % (party_slot + 1) if party_slot >= 0 else "RESERVE", 16)

	var ability: Dictionary = stats.get("ability", {})
	_front_label(content, "UNIQUE ABILITY — " + str(ability.get("name", "Under Design")), 18, Color(0.91, 0.91, 1.0))
	_front_label(content, str(ability.get("description", "")), 15, Color(0.81, 0.84, 0.92)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_front_label(content, "MOVES — FOUR EQUIPPED SLOTS", 18)
	for i in range(4):
		var moves: Array = stats.get("moves", [])
		var move: Dictionary = moves[i] if i < moves.size() else {}
		var summary := "SLOT %d  •  EMPTY" % (i + 1)
		if not move.is_empty():
			var label_text := str(move.get("name", "Unknown Move"))
			var power := int(move.get("power", 0))
			summary = "SLOT %d  •  %s  [%s%s]" % [
				i + 1, label_text, str(move.get("kind", "utility")),
				" %d" % power if power > 0 else ""]
		_front_label(content, summary, 15, Color(0.87, 0.91, 0.96))

	_front_label(content, "ITEM SLOTS", 18)
	_front_label(content, "[ Empty ]     [ Empty ]     [ Empty ]", 16, Color(0.82, 0.87, 0.96))
	_front_label(content, "TRAINING / ITEMS COMING NEXT  •  No progress or items will be changed here.", 13, Color(0.73, 0.83, 0.91))
	_front_button(content, "BACK TO PARTY", _render_party_overview, 43.0)


func _close_party_menu() -> void:
	if party_return_to_daily and interlude_mode:
		_draw_interlude()
	else:
		_show_menu()

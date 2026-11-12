extends "res://scripts/prototype_story_v12.gd"
## Prototype 013 — shared backpack, three equipped slots, gear and food.
## Items persist in the same save; practice battles only use temporary copies.

const InventoryEngine = preload("res://scripts/core/inventory_engine.gd")
const ITEM_CATALOG := "res://data/items/love_beyond.json"

var inventory_engine = null
var inventory_catalog: Dictionary = {}
var inventory_selected := "asmodeus"
var inventory_origin := "title"
var inventory_message := ""


func _inventory_load() -> void:
	if inventory_catalog.is_empty():
		inventory_catalog = ContentStore.read_dictionary(ITEM_CATALOG)
	if inventory_engine == null:
		inventory_engine = InventoryEngine.new()
	inventory_engine.begin(save_data, inventory_catalog)
	if inventory_engine.just_granted:
		# Exactly one starter grant; save it immediately to prevent duplication.
		inventory_engine.write_to(save_data)
		_inventory_persist()


func _inventory_persist() -> void:
	if not party_disable_disk_writes:
		SaveStore.write_save(save_data)


func _show_menu() -> void:
	super._show_menu()
	var menu_scroll: ScrollContainer = frontend_body.find_child("TitleMenuScroll", true, false) as ScrollContainer
	if menu_scroll == null or menu_scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = menu_scroll.get_child(0).get_child(0) as VBoxContainer
	_front_button(content, "INVENTORY & EQUIPMENT", _open_inventory, 47.0)


func _draw_interlude() -> void:
	super._draw_interlude()
	var scroll: ScrollContainer = frontend_body.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	_front_button(content, "INVENTORY & EQUIPMENT  •  No daily action cost",
		Callable(self, "_open_inventory").bind("", "daily"), 44.0)


func _render_party_overview() -> void:
	super._render_party_overview()
	var scroll: ScrollContainer = frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	var button := _front_button(content, "MANAGE INVENTORY & EQUIPMENT",
		Callable(self, "_open_inventory").bind("", "party"), 43.0)
	button.name = "PartyOpenInventory"
	for child in content.get_children():
		if child is Button and child.text == "BACK" and child != button:
			content.move_child(button, child.get_index())
			break


func _show_character_sheet(id: String) -> void:
	super._show_character_sheet(id)
	if party_engine == null or not party_engine.is_unlocked(id):
		return
	var scroll: ScrollContainer = frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	var sheet: Dictionary = party_engine.sheet(id, save_data)
	var items: Array = sheet.get("item_slot_details", [])
	var item_names: Array[String] = []
	for i in range(3):
		var item: Dictionary = items[i] if i < items.size() else {}
		item_names.append("%d. %s" % [i + 1, str(item.get("name", "Empty"))])
	for child in content.get_children():
		if not (child is Label):
			continue
		if child.text.begins_with("[ Empty ]"):
			child.text = "    |    ".join(item_names)
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		elif child.text.begins_with("ATK/DEF/SPD are prototype sheet stats"):
			child.text = "Equipment bonuses are included in these stats for party practice battles."
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		elif child.text.begins_with("Three item slots are reserved"):
			var buff: Dictionary = sheet.get("equipment_bonuses", {})
			child.text = "GEAR BONUS: ATK %+d  •  DEF %+d  •  SPD %+d  •  Damage ward %d" % [
				int(buff.get("attack", 0)), int(buff.get("defense", 0)),
				int(buff.get("speed", 0)), int(buff.get("damage_reduction", 0))]
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var manage := _front_button(content, "MANAGE %s'S ITEMS" % str(sheet.get("name", id)).to_upper(),
		Callable(self, "_open_inventory").bind(id, "sheet"), 44.0)
	manage.name = "CharacterManageItems"
	for child in content.get_children():
		if child is Button and child.text == "BACK TO PARTY" and child != manage:
			content.move_child(manage, child.get_index())
			break


func _open_inventory(character_id: String = "", origin: String = "title") -> void:
	inventory_origin = origin
	inventory_message = ""
	_party_load()
	_inventory_load()
	if character_id != "" and party_engine.is_unlocked(character_id):
		inventory_selected = character_id
	elif not party_engine.is_unlocked(inventory_selected):
		inventory_selected = str(party_engine.unlocked[0]) if not party_engine.unlocked.is_empty() else ""
	_inventory_show()


func _inventory_show() -> void:
	_party_load()
	_inventory_load()
	_set_area_background("forest_camp")
	var content := _party_panel("SHARED BACKPACK", "One starter kit per save  •  Three item slots per ally")
	if inventory_message != "":
		_front_label(content, inventory_message, 15, Color(0.99, 0.86, 0.67)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_label(content, "AVAILABLE CHARACTERS", 18)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 8)
	content.add_child(choices)
	for id in party_engine.unlocked:
		var text_label := id.to_upper()
		if id == inventory_selected:
			text_label += "  [SELECTED]"
		var button := _front_button(choices, text_label, Callable(self, "_inventory_choose").bind(id), 42.0)
		button.name = "InventoryCharacter_" + id
	_front_label(content, "BACKPACK", 19)
	var names: Array[String] = []
	for id in inventory_engine.all_backpack_items():
		names.append("%s ×%d" % [inventory_engine.name_of(id), inventory_engine.backpack_count(id)])
	var backpack_text := "    •    ".join(names) if not names.is_empty() else "Empty — everything is equipped or consumed."
	_front_label(content, backpack_text, 15, Color(0.83, 0.90, 0.97)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_label(content, "EQUIPPED / READIED ITEMS — " + inventory_selected.to_upper(), 19)
	var slots: Array = inventory_engine.slots_for(inventory_selected)
	for i in range(3):
		var item_id: String = str(slots[i])
		var item_name := "EMPTY — equip from backpack" if item_id == "" else inventory_engine.name_of(item_id)
		var button := _front_button(content, "SLOT %d  •  %s" % [i + 1, item_name],
			Callable(self, "_inventory_slot_actions").bind(i), 46.0)
		button.name = "InventorySlot_%d" % i
	var sheet: Dictionary = party_engine.sheet(inventory_selected, save_data)
	var bonuses: Dictionary = sheet.get("equipment_bonuses", {})
	_front_label(content, "CURRENT GEAR: ATK %+d  •  DEF %+d  •  SPD %+d  •  WARD %d" % [
		int(bonuses.get("attack", 0)), int(bonuses.get("defense", 0)),
		int(bonuses.get("speed", 0)), int(bonuses.get("damage_reduction", 0))], 15)
	_front_label(content, "Food occupies a slot until used. Once eaten, it disappears. No food can revive a KO'd ally.", 14, Color(0.80, 0.87, 0.94)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "BACK", _inventory_close, 44.0)


func _inventory_choose(id: String) -> void:
	if party_engine != null and party_engine.is_unlocked(id):
		inventory_selected = id
		inventory_message = ""
	_inventory_show()


func _inventory_slot_actions(index: int) -> void:
	_inventory_load()
	var slots: Array = inventory_engine.slots_for(inventory_selected)
	if index < 0 or index >= 3:
		return
	var item_id := str(slots[index])
	var content := _party_panel("ITEM SLOT %d" % [index + 1], inventory_selected.to_upper())
	if item_id != "":
		var item: Dictionary = inventory_engine.definition(item_id)
		_front_label(content, str(item.get("name", item_id)), 21)
		_front_label(content, str(item.get("description", "")), 15).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var unequip := _front_button(content, "RETURN TO SHARED BACKPACK", Callable(self, "_inventory_unequip").bind(index), 48.0)
		unequip.name = "InventoryUnequip"
		if str(item.get("category", "")) == "consumable":
			var use := _front_button(content, "EAT NOW  •  Restore HP (consumes one)", Callable(self, "_inventory_consume").bind(index), 48.0)
			use.name = "InventoryConsume"
	else:
		_front_label(content, "Choose an item from the shared backpack:", 17)
		var count := 0
		for id in inventory_engine.all_backpack_items():
			if not inventory_engine.compatible(id, inventory_selected):
				continue
			var item: Dictionary = inventory_engine.definition(id)
			var title_text := "%s  ×%d" % [str(item.get("name", id)), inventory_engine.backpack_count(id)]
			var choice := _front_button(content, title_text, Callable(self, "_inventory_equip").bind(index, id), 46.0)
			choice.name = "InventoryEquip_" + id
			_front_label(content, str(item.get("description", "")), 13, Color(0.75, 0.84, 0.93)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			count += 1
		if count == 0:
			_front_label(content, "No compatible items left in the backpack.", 15)
	_front_button(content, "BACK TO INVENTORY", _inventory_show, 44.0)


func _inventory_equip(index: int, item_id: String) -> void:
	_party_load()
	_inventory_load()
	if inventory_engine.equip(inventory_selected, index, item_id, party_engine.unlocked):
		inventory_engine.write_to(save_data)
		_inventory_persist()
		inventory_message = "Equipped " + inventory_engine.name_of(item_id) + "."
	else:
		inventory_message = inventory_engine.error_text
	_inventory_show()


func _inventory_unequip(index: int) -> void:
	_party_load()
	_inventory_load()
	if inventory_engine.unequip(inventory_selected, index, party_engine.unlocked):
		inventory_engine.write_to(save_data)
		_inventory_persist()
		inventory_message = "Item returned to the shared backpack."
	else:
		inventory_message = inventory_engine.error_text
	_inventory_show()


func _inventory_consume(index: int) -> void:
	_party_load()
	_inventory_load()
	var character: Dictionary = ContentStore.load_character(inventory_selected)
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var progress: Dictionary = lb.get("progression", {})
	var record: Dictionary = progress.get(inventory_selected, {})
	var maximum := maxi(1, int(record.get("max_hp", character.get("max_hp", 100))))
	var hp := clampi(int(record.get("hp", maximum)), 0, maximum)
	var using_camp := interlude_mode and interlude_engine != null and str(current_profile.get("pov", "")) == inventory_selected
	if using_camp:
		maximum = maxi(1, int(interlude_engine.state.get("max_hp", maximum)))
		hp = clampi(int(interlude_engine.state.get("hp", maximum)), 0, maximum)
	var outcome: Dictionary = inventory_engine.consume(inventory_selected, index, hp, maximum, party_engine.unlocked)
	if not bool(outcome.get("ok", false)):
		inventory_message = str(outcome.get("message", "Cannot consume."))
		_inventory_show()
		return
	record["hp"] = int(outcome["hp"])
	record["max_hp"] = maximum
	if using_camp:
		interlude_engine.state["hp"] = int(outcome["hp"])
		var states: Dictionary = lb.get("interludes", {})
		states[current_interlude_id] = interlude_engine.snapshot()
		lb["interludes"] = states
		# The ongoing camp's progression remains the source of truth for EXP.
		record.merge(interlude_engine.progression(), true)
	progress[inventory_selected] = record
	lb["progression"] = progress
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns
	inventory_engine.write_to(save_data)
	_inventory_persist()
	inventory_message = str(outcome.get("message", "Restored HP."))
	_inventory_show()


func _inventory_close() -> void:
	match inventory_origin:
		"daily":
			if interlude_mode:
				_draw_interlude()
			else:
				_show_menu()
		"party":
			_render_party_overview()
		"sheet":
			_show_character_sheet(inventory_selected)
		_:
			_show_menu()


func _party_battle_draw() -> void:
	super._party_battle_draw()
	if not party_battle_active or party_battle == null or party_battle.finished:
		return
	var scroll: ScrollContainer = frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null or scroll.get_child_count() == 0:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	if party_battle.usable_food_slots().is_empty():
		return
	var button := _front_button(content, "USE FOOD  •  Spends this fighter's turn", _party_battle_food_menu, 43.0)
	button.name = "PartyUseFood"
	var has_target := false
	for index in party_battle.usable_food_slots():
		if not party_battle.food_targets(index).is_empty():
			has_target = true
	button.disabled = not has_target


func _party_battle_food_menu() -> void:
	if party_battle == null or party_battle.finished:
		return
	var content := _battle_panel("CHOOSE EQUIPPED FOOD")
	_front_label(content, "Food heals a living, wounded ally. It disappears in this practice fight only.", 15).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var actor: Dictionary = party_battle.current_actor()
	var items: Array = actor.get("items", [])
	for slot_index in party_battle.usable_food_slots():
		var item: Dictionary = items[slot_index]
		var button := _front_button(content, "SLOT %d  •  %s (+%d HP)" % [
			slot_index + 1, str(item.get("name", "Food")), int(item.get("heal", 0))],
			Callable(self, "_party_battle_food_targets").bind(slot_index), 44.0)
		button.name = "BattleFoodSlot_" + str(slot_index)
		button.disabled = party_battle.food_targets(slot_index).is_empty()
	_front_button(content, "BACK TO MOVES", _party_battle_draw, 43.0)


func _party_battle_food_targets(slot_index: int) -> void:
	if party_battle == null or party_battle.finished:
		return
	var content := _battle_panel("WHO SHOULD EAT?")
	for index in party_battle.food_targets(slot_index):
		var member: Dictionary = party_battle.allies[index]
		var button := _front_button(content, "%s  •  %d / %d HP" % [
			str(member.get("name", "")), int(member.get("hp", 0)), int(member.get("max_hp", 0))],
			Callable(self, "_party_battle_use_food").bind(slot_index, index), 44.0)
		button.name = "BattleFoodTarget_" + str(index)
	_front_button(content, "BACK TO FOOD", _party_battle_food_menu, 43.0)


func _party_battle_use_food(slot_index: int, target_index: int) -> void:
	if party_battle == null or party_battle.finished:
		return
	var result: Dictionary = party_battle.use_food(slot_index, target_index)
	if not bool(result.get("ok", false)):
		party_battle.last_log = str(result.get("message", "Food unavailable."))
	_party_battle_draw()

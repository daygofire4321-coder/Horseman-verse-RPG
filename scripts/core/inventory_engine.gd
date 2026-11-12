extends RefCounted
## Three equipment/food slots per character; a stackable shared backpack.
## Saved under campaigns.love_beyond.inventory; compatible with v1 saves.
## Inventory does not award items after the one-time starter kit grant.

const SLOTS_PER_CHARACTER := 3

var catalog: Dictionary = {}
var state: Dictionary = {}
var error_text := ""
var just_granted := false


func begin(save_data: Dictionary, item_config: Dictionary) -> void:
	catalog = item_config.duplicate(true)
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var existing: Dictionary = lb.get("inventory", {})
	state = existing.duplicate(true)
	just_granted = false
	if not state.has("starter_granted"):
		# First-use kit, never re-awarded after saving or reopening.
		if existing.is_empty():
			just_granted = true
			state["backpack"] = catalog.get("starter_pack", {}).duplicate(true)
			state["slots"] = {}
		else:
			# A preexisting inventory without a starter flag is preserved.
			if not state.has("backpack"):
				state["backpack"] = {}
			if not state.has("slots"):
				state["slots"] = {}
		state["starter_granted"] = true
	if typeof(state.get("backpack")) != TYPE_DICTIONARY:
		state["backpack"] = {}
	if typeof(state.get("slots")) != TYPE_DICTIONARY:
		state["slots"] = {}
	error_text = ""


func definition(item_id: String) -> Dictionary:
	var all_items: Dictionary = catalog.get("items", {})
	var data: Dictionary = all_items.get(item_id, {})
	return data.duplicate(true)


func name_of(item_id: String) -> String:
	return str(definition(item_id).get("name", item_id))


func backpack_count(item_id: String) -> int:
	var pack: Dictionary = state.get("backpack", {})
	return maxi(0, int(pack.get(item_id, 0)))


func all_backpack_items() -> Array[String]:
	var ids: Array[String] = []
	var pack: Dictionary = state.get("backpack", {})
	for key in pack:
		var id := str(key)
		if backpack_count(id) > 0 and not definition(id).is_empty():
			ids.append(id)
	ids.sort()
	return ids


func compatible(item_id: String, character_id: String) -> bool:
	var item := definition(item_id)
	if item.is_empty():
		return false
	var allowed: Array = item.get("compatible", [])
	return allowed.is_empty() or allowed.has(character_id)


func slots_for(character_id: String) -> Array:
	var by_character: Dictionary = state.get("slots", {})
	var stored: Array = by_character.get(character_id, [])
	var slots: Array = []
	for i in range(SLOTS_PER_CHARACTER):
		slots.append(str(stored[i]) if i < stored.size() else "")
	return slots


func _put_slots(character_id: String, slots: Array) -> void:
	var all_slots: Dictionary = state.get("slots", {})
	all_slots[character_id] = slots.duplicate()
	state["slots"] = all_slots


func equip(character_id: String, slot_index: int, item_id: String, unlocked: Array) -> bool:
	error_text = ""
	if not unlocked.has(character_id):
		error_text = "This character isn't unlocked."
		return false
	if slot_index < 0 or slot_index >= SLOTS_PER_CHARACTER:
		error_text = "Invalid item slot."
		return false
	if definition(item_id).is_empty() or not compatible(item_id, character_id):
		error_text = "This item cannot be equipped by that character."
		return false
	var slots := slots_for(character_id)
	if str(slots[slot_index]) != "":
		error_text = "Unequip this slot before placing another item."
		return false
	if backpack_count(item_id) <= 0:
		error_text = "No copies remain in the backpack."
		return false
	var backpack: Dictionary = state.get("backpack", {})
	backpack[item_id] = backpack_count(item_id) - 1
	slots[slot_index] = item_id
	_put_slots(character_id, slots)
	return true


func unequip(character_id: String, slot_index: int, unlocked: Array) -> bool:
	error_text = ""
	if not unlocked.has(character_id):
		error_text = "This character isn't unlocked."
		return false
	if slot_index < 0 or slot_index >= SLOTS_PER_CHARACTER:
		error_text = "Invalid item slot."
		return false
	var slots := slots_for(character_id)
	var id := str(slots[slot_index])
	if id == "":
		error_text = "That item slot is already empty."
		return false
	var backpack: Dictionary = state.get("backpack", {})
	backpack[id] = backpack_count(id) + 1
	slots[slot_index] = ""
	_put_slots(character_id, slots)
	return true


func consume(character_id: String, slot_index: int, hp: int, max_hp: int, unlocked: Array) -> Dictionary:
	error_text = ""
	if not unlocked.has(character_id):
		error_text = "This character isn't unlocked."
		return {"ok":false, "message":error_text}
	if slot_index < 0 or slot_index >= SLOTS_PER_CHARACTER:
		error_text = "Invalid item slot."
		return {"ok":false, "message":error_text}
	var slots := slots_for(character_id)
	var id := str(slots[slot_index])
	var item: Dictionary = definition(id)
	if str(item.get("category", "")) != "consumable":
		error_text = "Only food can be consumed."
		return {"ok":false, "message":error_text}
	if hp <= 0:
		error_text = "Food cannot revive an unconscious ally."
		return {"ok":false, "message":error_text}
	if hp >= max_hp:
		error_text = "Already at full HP; the food has not been consumed."
		return {"ok":false, "message":error_text}
	var healed: int = mini(maxi(0, int(item.get("heal", 0))), maxi(0, max_hp - hp))
	if healed <= 0:
		error_text = "This item has no healing effect."
		return {"ok":false, "message":error_text}
	slots[slot_index] = ""
	_put_slots(character_id, slots)
	# Item is permanently consumed, not returned to the shared backpack.
	return {
		"ok":true, "hp":hp + healed, "healed":healed,
		"item_id":id, "message":"%s ate %s and restored %d HP." % [
			character_id.capitalize(), name_of(id), healed]
	}


func equipped_details(character_id: String) -> Array:
	var details: Array = []
	for id in slots_for(character_id):
		if str(id) == "":
			details.append({})
		else:
			var data := definition(str(id))
			data["id"] = str(id)
			details.append(data)
	return details


func bonuses_for(character_id: String) -> Dictionary:
	var attack := 0
	var defense := 0
	var speed := 0
	var damage_reduction := 0
	for id in slots_for(character_id):
		if str(id) == "":
			continue
		var item := definition(str(id))
		if str(item.get("category", "")) != "equipment":
			continue
		var bonuses: Dictionary = item.get("bonuses", {})
		var special: Dictionary = item.get("special", {})
		attack += int(bonuses.get("attack", 0))
		defense += int(bonuses.get("defense", 0))
		speed += int(bonuses.get("speed", 0))
		damage_reduction += int(special.get("damage_reduction", 0))
	return {
		"attack":attack,
		"defense":defense,
		"speed":speed,
		"damage_reduction":damage_reduction
	}


func write_to(save_data: Dictionary) -> void:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	lb["inventory"] = state.duplicate(true)
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns

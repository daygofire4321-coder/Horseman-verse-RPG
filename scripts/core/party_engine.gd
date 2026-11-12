extends RefCounted
## Reusable three-character party state. No save-file or story-cursor writes.
## Stat sheet bonuses and item/training panels are previews until later systems.

const ContentStore = preload("res://scripts/core/content_store.gd")
const MAX_ACTIVE := 3
const MAX_MOVES := 4
const ITEM_SLOTS := 3

var data: Dictionary = {}
var unlocked: Array[String] = []
var active: Array[String] = ["asmodeus", "haniel", ""]
var error_text := ""


func begin(save_data: Dictionary, config: Dictionary) -> void:
	data = config.duplicate(true)
	unlocked.clear()
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var completed_part := int(lb.get("opening_parts_completed", 0))
	var definitions: Dictionary = data.get("characters", {})
	for raw in data.get("character_order", []):
		var id := str(raw)
		var entry: Dictionary = definitions.get(id, {})
		if not entry.is_empty() and int(entry.get("unlock_after_part", 0)) <= completed_part:
			unlocked.append(id)

	var old_party: Dictionary = lb.get("party", {})
	var saved_slots: Array = old_party.get("active", ["asmodeus", "haniel", ""])
	active.clear()
	for index in range(MAX_ACTIVE):
		var id: String = str(saved_slots[index]) if index < saved_slots.size() else ""
		if id != "" and unlocked.has(id) and not active.has(id):
			active.append(id)
		else:
			active.append("")
	if member_count() == 0 and not unlocked.is_empty():
		active[0] = unlocked[0]
	error_text = ""


func is_unlocked(id: String) -> bool:
	return unlocked.has(id)


func member_count() -> int:
	var total := 0
	for id in active:
		if id != "":
			total += 1
	return total


func assign(slot: int, character_id: String) -> bool:
	error_text = ""
	if slot < 0 or slot >= MAX_ACTIVE:
		error_text = "Invalid party slot."
		return false
	if character_id != "" and not is_unlocked(character_id):
		error_text = "That character is not unlocked yet."
		return false
	if character_id == "" and active[slot] != "" and member_count() <= 1:
		error_text = "At least one party member must remain active."
		return false
	if character_id != "":
		var previous := active.find(character_id)
		if previous != -1 and previous != slot:
			# Swapping is more useful than silently duplicating the character.
			active[previous] = active[slot]
	active[slot] = character_id
	return true


func write_to(save_data: Dictionary) -> void:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	# Preserve chapter checkpoints, EXP, free-time state and every unrelated key.
	lb["party"] = {"active": active.duplicate(), "unlocked": unlocked.duplicate()}
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns


func sheet(character_id: String, save_data: Dictionary) -> Dictionary:
	var definition: Dictionary = data.get("characters", {}).get(character_id, {})
	if definition.is_empty():
		return {}
	var original: Dictionary = ContentStore.load_character(character_id)
	if original.is_empty():
		return {}
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var progress: Dictionary = lb.get("progression", {}).get(character_id, {})
	var level := maxi(1, int(progress.get("level", 1)))
	var base_hp := maxi(1, int(original.get("max_hp", 100)))
	var max_hp := maxi(base_hp, int(progress.get("max_hp", base_hp)))
	var current_hp := clampi(int(progress.get("hp", max_hp)), 0, max_hp)
	var base: Dictionary = definition.get("base_stats", {})
	var moves: Array = original.get("moves", [])
	var move_slots: Array = []
	for i in range(MAX_MOVES):
		move_slots.append(moves[i].duplicate(true) if i < moves.size() else {})
	return {
		"id":character_id,
		"name":str(original.get("name", character_id.capitalize())),
		"role":str(definition.get("role", "")),
		"level":level,
		"xp":maxi(0, int(progress.get("xp", 0))),
		"xp_target":30 * level,
		"hp":current_hp,
		"max_hp":max_hp,
		"attack":int(base.get("attack", 10)) + (level - 1) * 2,
		"defense":int(base.get("defense", 10)) + (level - 1) * 2,
		"speed":int(base.get("speed", 10)) + (level - 1),
		"ability":definition.get("ability", {}),
		"moves":move_slots,
		"item_slots":ITEM_SLOTS,
		"party_slot":active.find(character_id),
		"unlocked":is_unlocked(character_id),
		"unlock_after_part":int(definition.get("unlock_after_part", 0))
	}

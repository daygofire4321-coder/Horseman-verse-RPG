extends RefCounted
## Persistent free-time state. "Ordinary day" never advances narrative events.

var profile: Dictionary = {}
var state: Dictionary = {}

func begin(config: Dictionary, saved_state: Dictionary = {}, character_progress: Dictionary = {}) -> void:
	profile = config.duplicate(true)
	var max_hp: int = maxi(1, int(character_progress.get("max_hp", 100)))
	var starting_hp: int = maxi(1, int(character_progress.get("hp", 65)))
	state = {
		"day": 1,
		"actions_left": maxi(1, int(profile.get("day_actions", 3))),
		"hp": mini(starting_hp, max_hp),
		"max_hp": max_hp,
		"level": maxi(1, int(character_progress.get("level", 1))),
		"xp": maxi(0, int(character_progress.get("xp", 0))),
		"supplies": maxi(0, int(character_progress.get("supplies", 0))),
		"hunts": 0, "care_count": 0, "discovered": 0, "camp_works": 0,
		"complete": false
	}
	state.merge(saved_state, true)
	state["actions_left"] = clampi(int(state.get("actions_left", 3)), 0, int(profile.get("day_actions", 3)))


func can_spend_action() -> bool:
	return int(state.get("actions_left", 0)) > 0 and not bool(state.get("complete", false))


func spend(action_id: String) -> String:
	if not can_spend_action():
		return "No free-time actions remain today. You can still hunt or go to bed."
	var ids: Array = []
	for action in profile.get("actions", []):
		ids.append(str(action.get("id", "")))
	if not ids.has(action_id):
		return "This activity is unavailable at this point in the story."
	state["actions_left"] = int(state["actions_left"]) - 1
	match action_id:
		"rest":
			var restored: int = mini(int(state["max_hp"]) - int(state["hp"]), 35)
			state["hp"] = int(state["hp"]) + restored
			return "Asmodeus takes time to recover. Restored %d HP." % restored
		"care":
			state["care_count"] = int(state["care_count"]) + 1
			return "Asmodeus brings Haniel water and checks that the bear-fur blanket is still covering her. She answers with a grateful nod."
		"camp":
			state["camp_works"] = int(state["camp_works"]) + 1
			state["supplies"] = int(state["supplies"]) + 1
			return "The hide-drying rack gets a little sturdier. Salvaged 1 useful supply."
		"explore":
			state["discovered"] = int(state["discovered"]) + 1
			state["supplies"] = int(state["supplies"]) + 1
			return "An uneventful walk through the trees turns up a useful bundle of supplies."
	return "An ordinary moment passes."


func may_hunt() -> bool:
	return int(state.get("hp", 0)) > 0 and not bool(state.get("complete", false))


func hunt_pool() -> Array:
	return profile.get("hunting_pool", [])


func earn_hunt_exp(amount: int) -> String:
	state["hunts"] = int(state["hunts"]) + 1
	var xp_gained: int = maxi(0, amount)
	state["xp"] = int(state["xp"]) + xp_gained
	var levels := 0
	while int(state["xp"]) >= 30 * int(state["level"]):
		state["xp"] = int(state["xp"]) - 30 * int(state["level"])
		state["level"] = int(state["level"]) + 1
		state["max_hp"] = int(state["max_hp"]) + 8
		state["hp"] = mini(int(state["max_hp"]), int(state["hp"]) + 8)
		levels += 1
	return "+%d EXP%s" % [xp_gained, ", level up!" if levels > 0 else ""]


func ordinary_day() -> void:
	# This deliberately does not know about or change the story cursor.
	state["day"] = int(state["day"]) + 1
	state["actions_left"] = maxi(1, int(profile.get("day_actions", 3)))
	state["hp"] = mini(int(state["max_hp"]), int(state["hp"]) + 12)


func exciting_day() -> void:
	# Only the caller can actually advance the authored story event.
	state["day"] = int(state["day"]) + 1
	state["complete"] = true


func snapshot() -> Dictionary:
	return state.duplicate(true)


func progression() -> Dictionary:
	return {
		"hp": int(state["hp"]), "max_hp": int(state["max_hp"]),
		"level": int(state["level"]), "xp": int(state["xp"]),
		"supplies": int(state["supplies"])
	}

extends RefCounted
## Move training independent from EXP and character levels.
## Owns only campaigns.love_beyond.training; callers spend daily actions.
## This engine doesn't mutate campaign story progress or battles.

var config: Dictionary = {}
var state: Dictionary = {}
var error_text := ""


func begin(training_config: Dictionary, save_data: Dictionary) -> void:
	config = training_config.duplicate(true)
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var love_beyond: Dictionary = campaigns.get("love_beyond", {})
	var original: Dictionary = love_beyond.get("training", {})
	state = original.duplicate(true)
	error_text = ""


func _entry(character_id: String) -> Dictionary:
	var current: Dictionary = state.get(character_id, {})
	if not current.has("learned"):
		current["learned"] = []
	if not current.has("points"):
		current["points"] = 0
	current["points"] = maxi(0, int(current["points"]))
	state[character_id] = current
	return current


func learned(character_id: String) -> Array:
	var current: Dictionary = _entry(character_id)
	return current.get("learned", []).duplicate()


func next_move(character_id: String, completed_part: int) -> Dictionary:
	var candidates: Array = config.get("paths", {}).get(character_id, [])
	var known: Array = learned(character_id)
	for candidate in candidates:
		var move: Dictionary = candidate
		if known.has(str(move.get("id", ""))):
			continue
		var details: Dictionary = move.duplicate(true)
		details["locked"] = completed_part < int(move.get("unlock_after_part", 0))
		details["progress"] = int(_entry(character_id).get("points", 0))
		return details
	return {}


func can_train(character_id: String, completed_part: int) -> bool:
	var move: Dictionary = next_move(character_id, completed_part)
	return not move.is_empty() and not bool(move.get("locked", false))


func session(character_id: String, completed_part: int) -> Dictionary:
	error_text = ""
	var move: Dictionary = next_move(character_id, completed_part)
	if move.is_empty():
		error_text = "No more training techniques are available for this character yet."
		return {"ok":false, "message":error_text}
	if bool(move.get("locked", false)):
		error_text = "This technique becomes trainable after Part %d." % int(move.get("unlock_after_part", 0))
		return {"ok":false, "message":error_text}

	var current: Dictionary = _entry(character_id)
	var gained := maxi(1, int(config.get("points_per_session", 10)))
	var previous := int(current.get("points", 0))
	var goal := maxi(1, int(move.get("points_required", 30)))
	var accumulated := previous + gained
	var just_learned := false
	if accumulated >= goal:
		current["points"] = accumulated - goal
		var learned_ids: Array = current.get("learned", [])
		if not learned_ids.has(str(move.get("id", ""))):
			learned_ids.append(str(move.get("id", "")))
		current["learned"] = learned_ids
		just_learned = true
	else:
		current["points"] = accumulated
	state[character_id] = current
	var result: Dictionary = {
		"ok":true, "gained":gained, "learned":just_learned,
		"move_id":str(move.get("id", "")),
		"move_name":str(move.get("name", "")),
		"points":int(current["points"]),
		"needed":goal
	}
	if just_learned:
		result["message"] = "%s learned %s! (+%d training points; next technique's progress is saved.)" % [character_id.capitalize(), str(move.get("name", "")), gained]
	else:
		result["message"] = "%s practiced %s. +%d training points (%d/%d)." % [character_id.capitalize(), str(move.get("name", "")), gained, int(current["points"]), goal]
	return result


func known_move_definitions(character_id: String) -> Array:
	var known: Array = learned(character_id)
	var moves: Array = []
	for entry in config.get("paths", {}).get(character_id, []):
		var data: Dictionary = entry
		if known.has(str(data.get("id", ""))):
			moves.append(data.duplicate(true))
	return moves


func write_to(save_data: Dictionary) -> void:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var love_beyond: Dictionary = campaigns.get("love_beyond", {})
	love_beyond["training"] = state.duplicate(true)
	campaigns["love_beyond"] = love_beyond
	save_data["campaigns"] = campaigns

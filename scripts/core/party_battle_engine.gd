extends RefCounted
## Independent, non-canon three-member team-battle rules.
## The original scripted duel, bear rescue and Cliffside waves remain untouched.
const ContentStore = preload("res://scripts/core/content_store.gd")

var allies: Array = []
var enemies: Array = []
var reserves: Array = []
var order: Array[String] = []
var cursor := 0
var round_number := 1
var finished := false
var victory := false
var last_log := "The party faces a pair of wild creatures."
var enemy_damage_scale := 1.0


func setup(active_ids: Array, reserve_ids: Array, sheets: Dictionary, enemy_ids: Array, difficulty: Dictionary = {}) -> void:
	allies.clear()
	enemies.clear()
	reserves.clear()
	order.clear()
	cursor = 0
	round_number = 1
	finished = false
	victory = false
	enemy_damage_scale = maxf(0.0, float(difficulty.get("enemy_damage_multiplier", 1.0)))
	last_log = "The party faces a pair of wild creatures."
	for raw_id in active_ids:
		var id := str(raw_id)
		if id == "" or _has_id(allies, id) or allies.size() >= 3:
			continue
		var sheet: Dictionary = sheets.get(id, {})
		if not sheet.is_empty():
			allies.append(_member_from_sheet(sheet))
	for raw_id in reserve_ids:
		var id := str(raw_id)
		if id == "" or _has_id(allies, id) or _has_id(reserves, id):
			continue
		var sheet: Dictionary = sheets.get(id, {})
		if not sheet.is_empty():
			reserves.append(_member_from_sheet(sheet))
	var hp_scale := maxf(0.1, float(difficulty.get("enemy_hp_multiplier", 1.0)))
	for raw_id in enemy_ids:
		var creature: Dictionary = ContentStore.load_character(str(raw_id))
		if creature.is_empty():
			continue
		var hp := maxi(1, int(roundf(float(creature.get("max_hp", 50)) * hp_scale)))
		enemies.append({
			"id":str(creature.get("id", "")), "name":str(creature.get("name", "Enemy")),
			"hp":hp, "max_hp":hp, "ai_damage":maxi(0, int(creature.get("ai", {}).get("damage", 10)))
		})
	if allies.is_empty() or enemies.is_empty():
		finished = true
		victory = enemies.is_empty() and not allies.is_empty()
	else:
		_begin_round()


func _member_from_sheet(sheet: Dictionary) -> Dictionary:
	var maximum := maxi(1, int(sheet.get("max_hp", 100)))
	return {
		"id":str(sheet.get("id", "")), "name":str(sheet.get("name", "Ally")),
		"hp":clampi(int(sheet.get("hp", maximum)), 0, maximum), "max_hp":maximum,
		"attack":int(sheet.get("attack", 20)), "defense":int(sheet.get("defense", 20)),
		"speed":int(sheet.get("speed", 20)), "level":int(sheet.get("level", 1)),
		"moves":sheet.get("moves", []).duplicate(true),
		"items":sheet.get("item_slot_details", [{}, {}, {}]).duplicate(true),
		"damage_reduction":maxi(0, int(sheet.get("damage_reduction", 0))),
		"guard":false, "ability":sheet.get("ability", {}).duplicate(true)
	}


func _has_id(members: Array, id: String) -> bool:
	for member in members:
		if str(member.get("id", "")) == id:
			return true
	return false


func _speed_sort(a: Dictionary, b: Dictionary) -> bool:
	if int(a["speed"]) == int(b["speed"]):
		return str(a["id"]) < str(b["id"])
	return int(a["speed"]) > int(b["speed"])


func _begin_round() -> void:
	if finished:
		return
	var ready: Array = []
	for member in allies:
		if int(member.get("hp", 0)) > 0:
			ready.append({"id":str(member["id"]), "speed":int(member.get("speed", 0))})
	ready.sort_custom(Callable(self, "_speed_sort"))
	order.clear()
	for entry in ready:
		order.append(str(entry["id"]))
	cursor = 0
	if order.is_empty():
		finished = true
		victory = false


func current_actor() -> Dictionary:
	if finished or cursor >= order.size():
		return {}
	var id: String = order[cursor]
	for member in allies:
		if str(member.get("id", "")) == id and int(member.get("hp", 0)) > 0:
			return member
	return {}


func current_moves() -> Array:
	var actor: Dictionary = current_actor()
	var available: Array = []
	for move in actor.get("moves", []):
		if not move.is_empty():
			available.append(move)
	return available


func _find_move(move_id: String) -> Dictionary:
	for move in current_moves():
		if str(move.get("id", "")) == move_id:
			return move
	return {}


func targets(move_id: String) -> Array[int]:
	var move: Dictionary = _find_move(move_id)
	var valid: Array[int] = []
	if move.is_empty():
		return valid
	var kind := str(move.get("kind", "damage"))
	var pool: Array = allies if kind == "heal" else enemies
	for i in range(pool.size()):
		if int(pool[i].get("hp", 0)) > 0:
			valid.append(i)
	return valid


func use_move(move_id: String, target_index: int = -1) -> Dictionary:
	var actor: Dictionary = current_actor()
	var move: Dictionary = _find_move(move_id)
	if actor.is_empty() or move.is_empty():
		return {"ok":false, "message":"That move is unavailable."}
	var kind := str(move.get("kind", "damage"))
	if not ["damage", "heal", "guard"].has(kind):
		return {"ok":false, "message":"Unsupported move type."}
	if kind != "guard" and not targets(move_id).has(target_index):
		return {"ok":false, "message":"Choose a living target first."}

	var power := maxi(0, int(move.get("power", 0)))
	var log_line := ""
	if kind == "damage":
		var foe: Dictionary = enemies[target_index]
		# Prototype ATK stat gives a modest boost on top of the move's power.
		var attack_bonus := maxi(0, int((int(actor.get("attack", 20)) - 20) / 5))
		if str(actor.get("id", "")) == "asmodeus" and str(move_id).begins_with("black_ice"):
			attack_bonus += 2  # Black Ice Affinity: prototype team-mode passive
		var damage := power + attack_bonus
		foe["hp"] = maxi(0, int(foe["hp"]) - damage)
		log_line = "%s used %s on %s: %d damage." % [actor["name"], move.get("name", move_id), foe["name"], damage]
	elif kind == "heal":
		var friend: Dictionary = allies[target_index]
		if str(actor.get("id", "")) == "haniel":
			power += 3  # Angelic Grace: prototype healing passive
		var restored: int = mini(power, int(friend["max_hp"]) - int(friend["hp"]))
		friend["hp"] = int(friend["hp"]) + restored
		log_line = "%s healed %s for %d HP." % [actor["name"], friend["name"], restored]
	else:
		actor["guard"] = true
		log_line = "%s takes a guarded stance." % actor["name"]
	last_log = log_line
	_advance_after_action()
	return {"ok":true, "message":last_log, "finished":finished, "victory":victory}



func usable_food_slots() -> Array[int]:
	var valid: Array[int] = []
	var actor: Dictionary = current_actor()
	var items: Array = actor.get("items", [])
	for i in range(items.size()):
		var item: Dictionary = items[i]
		if str(item.get("category", "")) == "consumable" and int(item.get("heal", 0)) > 0:
			valid.append(i)
	return valid


func food_targets(slot_index: int) -> Array[int]:
	var valid: Array[int] = []
	if not usable_food_slots().has(slot_index):
		return valid
	for i in range(allies.size()):
		var member: Dictionary = allies[i]
		if int(member.get("hp", 0)) > 0 and int(member.get("hp", 0)) < int(member.get("max_hp", 0)):
			valid.append(i)
	return valid


func use_food(slot_index: int, target_index: int) -> Dictionary:
	var actor: Dictionary = current_actor()
	if actor.is_empty() or not usable_food_slots().has(slot_index):
		return {"ok":false, "message":"No food is equipped in that slot."}
	if not food_targets(slot_index).has(target_index):
		return {"ok":false, "message":"Choose a living, wounded ally."}
	var items: Array = actor.get("items", [])
	var food: Dictionary = items[slot_index]
	var friend: Dictionary = allies[target_index]
	var amount := mini(maxi(0, int(food.get("heal", 0))), int(friend.get("max_hp", 0)) - int(friend.get("hp", 0)))
	friend["hp"] = int(friend["hp"]) + amount
	items[slot_index] = {}
	actor["items"] = items
	last_log = "%s shared %s with %s, restoring %d HP. The food is gone for this practice fight." % [
		actor.get("name", ""), food.get("name", "food"), friend.get("name", ""), amount]
	_advance_after_action()
	return {"ok":true, "message":last_log, "finished":finished, "victory":victory}


func switch_with_reserve(reserve_id: String) -> Dictionary:
	var actor: Dictionary = current_actor()
	if actor.is_empty():
		return {"ok":false, "message":"No active character can switch."}
	var reserve_index := -1
	for i in range(reserves.size()):
		if str(reserves[i].get("id", "")) == reserve_id and int(reserves[i].get("hp", 0)) > 0:
			reserve_index = i
			break
	if reserve_index < 0:
		return {"ok":false, "message":"That reserve character is not available."}
	var position := -1
	for i in range(allies.size()):
		if str(allies[i].get("id", "")) == str(actor.get("id", "")):
			position = i
			break
	if position < 0:
		return {"ok":false, "message":"Active party member missing."}
	var substitute: Dictionary = reserves[reserve_index]
	allies[position] = substitute
	reserves[reserve_index] = actor
	last_log = "%s switches out for %s. The switch uses this turn." % [actor["name"], substitute["name"]]
	_advance_after_action()
	return {"ok":true, "message":last_log, "finished":finished, "victory":victory}


func _advance_after_action() -> void:
	if _enemies_defeated():
		finished = true
		victory = true
		return
	cursor += 1
	while cursor < order.size() and current_actor().is_empty():
		cursor += 1
	if cursor >= order.size():
		_enemy_phase()
		if not finished:
			round_number += 1
			_begin_round()


func _enemies_defeated() -> bool:
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			return false
	return true


func _enemy_phase() -> void:
	var messages: Array[String] = [last_log]
	for foe in enemies:
		if int(foe.get("hp", 0)) <= 0:
			continue
		var survivors: Array[int] = []
		for i in range(allies.size()):
			if int(allies[i].get("hp", 0)) > 0:
				survivors.append(i)
		if survivors.is_empty():
			break
		# Stable target rotation so tests remain deterministic.
		var target_index: int = survivors[(round_number - 1 + enemies.find(foe)) % survivors.size()]
		var victim: Dictionary = allies[target_index]
		var raw := int(roundf(float(foe.get("ai_damage", 10)) * enemy_damage_scale))
		var defense_reduction := maxi(0, int((int(victim.get("defense", 20)) - 20) / 6))
		var ward_reduction := maxi(0, int(victim.get("damage_reduction", 0)))
		var taken := maxi(1, raw - defense_reduction - ward_reduction)
		if bool(victim.get("guard", false)):
			taken = maxi(1, int(ceil(float(taken) / 2.0)))
		victim["hp"] = maxi(0, int(victim["hp"]) - taken)
		messages.append("%s struck %s for %d." % [foe["name"], victim["name"], taken])
	for member in allies:
		member["guard"] = false
	last_log = "\n".join(messages)
	var any_alive := false
	for member in allies:
		if int(member.get("hp", 0)) > 0:
			any_alive = true
	if not any_alive:
		finished = true
		victory = false

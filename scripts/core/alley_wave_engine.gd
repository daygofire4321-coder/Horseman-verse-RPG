extends RefCounted
## Two ally-assisted, multi-target scripted waves for Cliffside.
## HP represents fighting ability, never permission to kill a story character.

var wave: int = 0
var player: Dictionary = {}
var player_hp: int = 0
var player_max_hp: int = 0
var alric_hp: int = 0
var enemies: Array = []
var round_number := 0
var enemy_damage_multiplier := 1.0


func setup(number: int, difficulty: Dictionary = {}) -> void:
	wave = number
	player = _character("haniel" if number == 1 else "asmodeus")
	player_max_hp = 55 if number == 1 else 95
	player_hp = player_max_hp
	alric_hp = 110 if number == 1 else 45
	round_number = 0
	enemies.clear()
	var hp_scale: float = maxf(0.1, float(difficulty.get("enemy_hp_multiplier", 1.0)))
	enemy_damage_multiplier = maxf(0.0, float(difficulty.get("enemy_damage_multiplier", 1.0)))
	for index in range(2):
		enemies.append({"name":"Thug %d" % [index+1], "hp":maxi(1,roundi(34.0*hp_scale)), "damage":7})
	if number == 2:
		enemies.append({"name":"Joren (Gang Leader)", "hp":maxi(1,roundi(65.0*hp_scale)), "damage":10, "protected":true})


func _character(id: String) -> Dictionary:
	var text: String = "res://data/characters/%s.json" % id
	if not FileAccess.file_exists(text):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(text))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func player_moves() -> Array:
	return player.get("moves", [])


func _next_alive() -> int:
	for index in range(enemies.size()):
		var candidate: Dictionary = enemies[index]
		if int(candidate.get("hp", 0)) > 0:
			return index
	return -1


func enemy_summary() -> String:
	var parts: Array[String] = []
	for value in enemies:
		var enemy: Dictionary = value
		parts.append("%s: %d HP" % [str(enemy.get("name", "Enemy")), int(enemy.get("hp", 0))])
	return "    |    ".join(parts)


func _strike(index: int, amount: int) -> String:
	var foe: Dictionary = enemies[index]
	var previous: int = int(foe.get("hp", 0))
	foe["hp"] = maxi(0, previous - maxi(0, amount))
	enemies[index] = foe
	return "%s takes %d damage." % [str(foe.get("name", "Enemy")), previous - int(foe["hp"])]


func take_turn(move_id: String) -> Dictionary:
	var move: Dictionary = {}
	for candidate in player_moves():
		if str(candidate.get("id", "")) == move_id:
			move = candidate
			break
	if move.is_empty():
		return {"finished":false, "message":"That move is unavailable."}

	round_number += 1
	var logs: Array[String] = []
	var guard := false
	var kind := str(move.get("kind", "damage"))
	var power: int = maxi(0, int(move.get("power", 0)))
	match kind:
		"damage":
			var target := _next_alive()
			if target >= 0:
				logs.append(str(player.get("name", "Hero")) + " attacks. " + _strike(target, power))
		"heal":
			var healed: int = mini(player_max_hp - player_hp, power)
			player_hp += healed
			logs.append("Haniel restores %d HP." % healed)
		"guard":
			guard = true
			logs.append("Asmodeus guards with black ice.")

	# Alric fights alongside the POV character, even while injured in Wave 2.
	if alric_hp > 0:
		var other_target := _next_alive()
		if other_target >= 0:
			var alric_damage := 16 if wave == 1 else 9
			logs.append("Alric swings his hammer. " + _strike(other_target, alric_damage))

	if _next_alive() < 0:
		return {"finished":true, "won":true, "message":"\n".join(logs)}

	for enemy_data in enemies:
		var foe: Dictionary = enemy_data
		if int(foe.get("hp", 0)) <= 0:
			continue
		var dmg: int = maxi(1, int(round(float(foe.get("damage", 7)) * enemy_damage_multiplier)))
		if guard:
			dmg = maxi(1, int(round(float(dmg) * 0.35)))
		# Splitting targeting between the two actors makes Alric a real ally.
		if round_number % 2 == 0 and alric_hp > 0:
			alric_hp = maxi(0, alric_hp - dmg)
			logs.append("%s strikes Alric (%d damage)." % [str(foe["name"]), dmg])
		else:
			player_hp = maxi(0, player_hp - dmg)
			logs.append("%s strikes %s (%d damage)." % [str(foe["name"]), str(player.get("name", "hero")), dmg])

	var lost: bool = player_hp <= 0 or alric_hp <= 0
	# If either active fighter falls, yield to the scripted scene instead of allowing a fallen character to act.
	return {"finished":lost, "won":not lost, "message":"\n".join(logs)}

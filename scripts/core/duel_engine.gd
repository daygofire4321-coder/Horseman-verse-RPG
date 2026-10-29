extends RefCounted
## Standalone rules/state for a one-versus-one duel.
## Content, presentation, saves and difficulty menus live elsewhere.

var player: Dictionary = {}
var enemy: Dictionary = {}
var player_hp: int = 0
var enemy_hp: int = 0
var player_max_hp: int = 100
var enemy_max_hp: int = 100
var enemy_damage_multiplier: float = 1.0
var enemy_used_heal: bool = false


func setup(player_data: Dictionary, enemy_data: Dictionary, difficulty: Dictionary = {}) -> void:
	player = player_data.duplicate(true)
	enemy = enemy_data.duplicate(true)
	player_max_hp = max(1, int(player.get("max_hp", 100)))
	var hp_scale := maxf(0.1, float(difficulty.get("enemy_hp_multiplier", 1.0)))
	enemy_max_hp = max(1, int(round(float(enemy.get("max_hp", 100)) * hp_scale)))
	enemy_damage_multiplier = maxf(0.0, float(difficulty.get("enemy_damage_multiplier", 1.0)))
	player_hp = player_max_hp
	enemy_hp = enemy_max_hp
	enemy_used_heal = false


func player_moves() -> Array:
	return player.get("moves", [])


func _find_move(move_id: String) -> Dictionary:
	for move in player_moves():
		if str(move.get("id", "")) == move_id:
			return move
	return {}


func _enemy_can_heal() -> bool:
	for move in enemy.get("moves", []):
		if str(move.get("kind", "")) == "heal":
			return true
	return false


func _outcome(description: String, finished: bool = false, victory: bool = false) -> Dictionary:
	return {
		"message": description,
		"finished": finished,
		"victory": victory,
		"player_hp": player_hp,
		"enemy_hp": enemy_hp,
		"player_max_hp": player_max_hp,
		"enemy_max_hp": enemy_max_hp
	}


func take_turn(move_id: String) -> Dictionary:
	var move := _find_move(move_id)
	if move.is_empty():
		return _outcome("Unknown move: " + move_id)

	var power := max(0, int(move.get("power", 0)))
	var kind := str(move.get("kind", "damage"))
	var guard_active := false
	var log_text := ""
	var actor := str(player.get("name", "Player"))

	match kind:
		"damage":
			enemy_hp = max(0, enemy_hp - power)
			log_text = "%s uses %s for %d damage." % [actor, str(move.get("name", "Attack")), power]
		"heal":
			var old_hp := player_hp
			player_hp = min(player_max_hp, player_hp + power)
			log_text = "%s restores %d HP." % [actor, player_hp - old_hp]
		"guard":
			guard_active = true
			log_text = "%s raises a protective barrier." % actor
		_:
			return _outcome("Unsupported move kind: " + kind)

	if enemy_hp <= 0:
		return _outcome(log_text, true, true)

	var enemy_ai: Dictionary = enemy.get("ai", {})
	var heal_threshold_percent := float(enemy_ai.get("heal_threshold", 35.0))
	var heal_trigger_hp := int(round(float(enemy_max_hp) * heal_threshold_percent / 100.0))
	if not enemy_used_heal and _enemy_can_heal() and enemy_hp <= heal_trigger_hp:
		enemy_used_heal = true
		var old_enemy_hp := enemy_hp
		enemy_hp = min(enemy_max_hp, enemy_hp + max(0, int(enemy_ai.get("heal_amount", 14))))
		log_text += "\n%s restores %d HP." % [str(enemy.get("name", "Opponent")), enemy_hp - old_enemy_hp]
	else:
		var base_damage := int(enemy_ai.get("damage", 17))
		if guard_active:
			base_damage = int(enemy_ai.get("damage_vs_guard", 6))
		var damage := max(0, int(round(float(base_damage) * enemy_damage_multiplier)))
		player_hp = max(0, player_hp - damage)
		log_text += "\n%s deals %d damage." % [str(enemy.get("name", "Opponent")), damage]

	if player_hp <= 0:
		return _outcome(log_text, true, false)
	return _outcome(log_text)

extends RefCounted
## Single source of truth for character-sheet stats.
## Status modifiers are optional; 1.0 leaves Prototype 022 unchanged.
## Hunger and future status effects can use the same entry point.

static func effective_stats(base: Dictionary, level: int, equipment: Dictionary, modifiers: Dictionary = {}) -> Dictionary:
	var steps := maxi(0, level - 1)
	var raw_attack := int(base.get("attack", 10)) + steps * 2 + int(equipment.get("attack", 0))
	var raw_defense := int(base.get("defense", 10)) + steps * 2 + int(equipment.get("defense", 0))
	var raw_speed := int(base.get("speed", 10)) + steps + int(equipment.get("speed", 0))
	# Fractional status multipliers are rounded once, after additive bonuses.
	return {
		"attack":maxi(0, roundi(raw_attack * maxf(0.0, float(modifiers.get("attack", 1.0))))),
		"defense":maxi(0, roundi(raw_defense * maxf(0.0, float(modifiers.get("defense", 1.0))))),
		"speed":maxi(0, roundi(raw_speed * maxf(0.0, float(modifiers.get("speed", 1.0))))),
		"damage_reduction":maxi(0, int(equipment.get("damage_reduction", 0)))
	}

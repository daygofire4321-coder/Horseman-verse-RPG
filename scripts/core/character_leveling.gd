extends RefCounted
## Shared level math for party companions. Mirrors InterludeEngine's
## existing 30 * current level XP requirement and +8 HP per level.
## This operates on one progression dictionary and never writes a save.

static func grant_xp(progress: Dictionary, gained: int, base_hp: int = 100) -> Dictionary:
	var result := progress.duplicate(true)
	var level := maxi(1, int(result.get("level", 1)))
	var xp := maxi(0, int(result.get("xp", 0))) + maxi(0, gained)
	var maximum := maxi(1, int(result.get("max_hp", base_hp)))
	var hp := clampi(int(result.get("hp", maximum)), 0, maximum)
	var levels := 0
	while xp >= 30 * level:
		xp -= 30 * level
		level += 1
		maximum += 8
		hp = mini(maximum, hp + 8)
		levels += 1
	result["level"] = level
	result["xp"] = xp
	result["hp"] = hp
	result["max_hp"] = maximum
	return {"progress":result, "levels":levels}

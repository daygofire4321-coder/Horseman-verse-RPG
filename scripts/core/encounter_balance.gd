extends RefCounted
## Explicit encounter level targets, separate from save/XP/UI.
## Story position determines the expected level. The player's actual level
## does not automatically raise the target: optional grinding stays useful.
## Difficulty moves enemies closer to (or past) the expected level.

static func expected_level(completed_part: int) -> int:
	# Assumes some ordinary-day exploration and repeatable encounters.
	# Part 0-2 -> Lv1, 3-5 -> Lv2, 6-8 -> Lv3, 9-11 -> Lv4.
	return clampi(1 + maxi(0, completed_part) / 3, 1, 40)


static func target_level(completed_part: int, profile: Dictionary) -> int:
	var expectation := expected_level(completed_part)
	var approach := int(profile.get("level_offset", -1))
	return clampi(expectation + approach, 1, 40)


static func enemy_stats(creature: Dictionary, completed_part: int, profile: Dictionary) -> Dictionary:
	var level := target_level(completed_part, profile)
	var steps := level - 1
	var base_hp := maxi(1, int(creature.get("max_hp", 50)))
	var base_damage := maxi(0, int(creature.get("ai", {}).get("damage", 10)))
	# Levels supplement the established difficulty HP/damage multipliers,
	# not replace them. A gentle per-level curve avoids instant one-shots.
	var hp := maxi(1, int(roundf(float(base_hp + steps * 9) *
		maxf(0.1, float(profile.get("enemy_hp_multiplier", 1.0))))))
	var damage := maxi(0, base_damage + steps * 2)
	return {
		"level":level, "hp":hp, "max_hp":hp, "ai_damage":damage,
		"defense":steps, "expected_level":expected_level(completed_part)
	}

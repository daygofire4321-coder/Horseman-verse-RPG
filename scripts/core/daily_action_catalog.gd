extends RefCounted
## UI-independent descriptions for free-time actions.
## Keeps daily dashboard labels out of the versioned scene scripts.

static func detail(profile: Dictionary, action_id: String) -> Dictionary:
	if action_id == "hunt":
		return {
			"title":"HUNT",
			"description":"Repeatable wildlife encounter. No daily action cost.",
			"cost":"FREE • REPEATABLE"
		}
	for raw in profile.get("actions", []):
		var action: Dictionary = raw
		if str(action.get("id", "")) == action_id:
			return {
				"title":str(action.get("label", action_id)).to_upper(),
				"description":str(action.get("description", "")),
				"cost":"1 DAILY ACTION"
			}
	return {"title":action_id.replace("_", " ").to_upper(), "description":"Available today.", "cost":"1 DAILY ACTION"}

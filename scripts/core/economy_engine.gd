extends RefCounted
## Persistent gold wallet plus Cliffside market purchases/sales.
## No currency is awarded by practice battles or the scripted story.
var config: Dictionary = {}
var item_catalog: Dictionary = {}
var state: Dictionary = {}
var completed_part := 0
var error_text := ""


func begin(save_data: Dictionary, market_config: Dictionary, items: Dictionary) -> void:
	config = market_config.duplicate(true)
	item_catalog = items.duplicate(true)
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	state = lb.get("economy", {}).duplicate(true)
	completed_part = int(lb.get("opening_parts_completed", 0))
	if not state.has("gold"):
		state["gold"] = 0
	if not state.has("outlaw_victories"):
		state["outlaw_victories"] = 0
	state["gold"] = maxi(0, int(state.get("gold", 0)))
	error_text = ""


func wallet() -> int:
	return maxi(0, int(state.get("gold", 0)))


func market_unlocked() -> bool:
	return completed_part >= int(config.get("required_story_part", 6))


func merchants() -> Array:
	return config.get("merchants", []).duplicate(true)


func merchant(merchant_id: String) -> Dictionary:
	for entry in config.get("merchants", []):
		var data: Dictionary = entry
		if str(data.get("id", "")) == merchant_id:
			return data.duplicate(true)
	return {}


func offer_price(merchant_id: String, item_id: String) -> int:
	var shop: Dictionary = merchant(merchant_id)
	for offer in shop.get("offers", []):
		var entry: Dictionary = offer
		if str(entry.get("item_id", "")) == item_id:
			return maxi(0, int(entry.get("price", 0)))
	return -1


func resale_value(item_id: String) -> int:
	var items: Dictionary = item_catalog.get("items", {})
	var item: Dictionary = items.get(item_id, {})
	if item.is_empty():
		return 0
	return maxi(1, int(floor(float(item.get("value", 0)) * float(config.get("sell_rate", 0.5)))))


func award_outlaw_gold(amount: int) -> int:
	var earned := clampi(amount, 0, 1000)
	state["gold"] = wallet() + earned
	state["outlaw_victories"] = maxi(0, int(state.get("outlaw_victories", 0))) + 1
	return earned


func buy(merchant_id: String, item_id: String, inventory, quantity: int = 1) -> Dictionary:
	error_text = ""
	if not market_unlocked():
		error_text = "Cliffside's market opens after Part Six."
		return {"ok":false, "message":error_text}
	if quantity < 1 or quantity > 99:
		error_text = "Invalid quantity."
		return {"ok":false, "message":error_text}
	var price := offer_price(merchant_id, item_id)
	if price <= 0 or inventory.definition(item_id).is_empty():
		error_text = "This merchant doesn't carry that item."
		return {"ok":false, "message":error_text}
	var total: int = price * quantity
	if wallet() < total:
		error_text = "Not enough gold."
		return {"ok":false, "message":error_text}
	if not inventory.add_to_backpack(item_id, quantity):
		error_text = inventory.error_text
		return {"ok":false, "message":error_text}
	state["gold"] = wallet() - total
	return {"ok":true, "gold_spent":total, "message":"Bought %d × %s for %d gold." % [
		quantity, inventory.name_of(item_id), total]}


func sell(item_id: String, inventory, quantity: int = 1) -> Dictionary:
	error_text = ""
	if not market_unlocked():
		error_text = "Cliffside's market is still locked."
		return {"ok":false, "message":error_text}
	if quantity < 1 or quantity > 99:
		error_text = "Invalid quantity."
		return {"ok":false, "message":error_text}
	var price := resale_value(item_id)
	if price <= 0 or inventory.backpack_count(item_id) < quantity:
		error_text = "You don't have enough of that item in your backpack."
		return {"ok":false, "message":error_text}
	if not inventory.take_from_backpack(item_id, quantity):
		error_text = inventory.error_text
		return {"ok":false, "message":error_text}
	var total: int = price * quantity
	state["gold"] = wallet() + total
	return {"ok":true, "gold_earned":total, "message":"Sold %d × %s for %d gold." % [
		quantity, inventory.name_of(item_id), total]}


func write_to(save_data: Dictionary) -> void:
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	lb["economy"] = state.duplicate(true)
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns

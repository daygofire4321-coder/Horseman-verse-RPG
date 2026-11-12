extends "res://scripts/prototype_story_v13.gd"
## Prototype 014: Cliffside gold/market plus separate Asmodeus & Haniel daily
## routines, each containing story-gated, repeatable outlaw encounters.
## The authored Parts 1-6 battle outcomes and earlier forest days are untouched.

const EconomyEngine = preload("res://scripts/core/economy_engine.gd")
const MARKET_DATA := "res://data/shops/cliffside_market.json"
const ENCOUNTER_DATA := "res://data/encounters/cliffside_outlaws.json"

var economy_engine = null
var market_config: Dictionary = {}
var outlaw_data: Dictionary = {}
var market_origin := "title"
var market_message := ""
var live_outlaw_active := false
var live_outlaw_resolved := false
var live_outlaw_scenario: Dictionary = {}
var live_outlaw_pov := ""


func _economy_load() -> void:
	if market_config.is_empty():
		market_config = ContentStore.read_dictionary(MARKET_DATA)
	if economy_engine == null:
		economy_engine = EconomyEngine.new()
	economy_engine.begin(save_data, market_config, ContentStore.read_dictionary(ITEM_CATALOG))


func _outlaw_load() -> void:
	if outlaw_data.is_empty():
		outlaw_data = ContentStore.read_dictionary(ENCOUNTER_DATA)


func _is_cliffside_day() -> bool:
	return current_interlude_id.begins_with("cliffside_") and interlude_mode and _completed_story_part() >= 6


func _show_menu() -> void:
	# Retiring from a real encounter forfeits rewards but preserves wounds
	# and items already used. A daily action was spent before the fight began.
	if live_outlaw_active and not live_outlaw_resolved and party_battle != null:
		_finish_outlaw_encounter(true)
		return
	super._show_menu()
	if _completed_story_part() < 6:
		return
	var scroll: ScrollContainer = frontend_body.find_child("TitleMenuScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	var entry := _front_button(content, "CLIFFSIDE FREE TIME  •  Explore or Patrol for Gold",
		_cliffside_day_selector, 49.0)
	entry.name = "CliffsideFreeTime"
	var market := _front_button(content, "CLIFFSIDE MARKET  •  Buy & Sell",
		_open_market, 48.0)
	market.name = "OpenCliffsideMarket"


func _cliffside_day_selector() -> void:
	if _completed_story_part() < 6:
		_show_menu()
		return
	var content := _party_panel("CLIFFSIDE — ORDINARY DAYS", "Unlocked after Part Six  •  Neither routine advances the story")
	_front_label(content, "Explore Cliffside as Asmodeus, or patrol its streets with Haniel. Each has three actions per day and separate HP, EXP and free-time progress.", 16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var asmo := _front_button(content, "ASMODEUS — EXPLORE", Callable(self, "_enter_cliffside_day").bind("asmodeus"), 52.0)
	asmo.name = "ChooseCliffsideAsmodeus"
	var haniel := _front_button(content, "HANIEL — PATROL", Callable(self, "_enter_cliffside_day").bind("haniel"), 52.0)
	haniel.name = "ChooseCliffsideHaniel"
	_front_button(content, "GO TO CLIFFSIDE MARKET", _open_market, 47.0)
	_front_button(content, "BACK TO TITLE", _show_menu, 44.0)


func _enter_cliffside_day(character_id: String) -> void:
	if _completed_story_part() < 6 or not ["asmodeus", "haniel"].has(character_id):
		return
	_load_story_if_needed()
	live_outlaw_active = false
	live_outlaw_resolved = false
	last_activity_text = ""
	_enter_interlude("cliffside_" + character_id)


func _save_interlude() -> void:
	if not _is_cliffside_day():
		super._save_interlude()
		return
	# Optional free time after the current story finale must NEVER write
	# a story-cursor checkpoint; the existing authored finale remains intact.
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var states: Dictionary = lb.get("interludes", {})
	states[current_interlude_id] = interlude_engine.snapshot()
	lb["interludes"] = states
	var progression: Dictionary = lb.get("progression", {})
	var pov := str(current_profile.get("pov", "asmodeus"))
	var existing: Dictionary = progression.get(pov, {})
	existing.merge(interlude_engine.progression(), true)
	progression[pov] = existing
	lb["progression"] = progression
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns
	_inventory_persist()


func _draw_interlude() -> void:
	super._draw_interlude()
	if not _is_cliffside_day():
		return
	_economy_load()
	_set_area_background("market_street")
	var scroll: ScrollContainer = frontend_body.find_child("DailyActivitiesScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
	var hunt: Button = scroll.find_child("Daily_Hunt", true, false) as Button
	if hunt != null:
		hunt.text = "WILDLIFE HUNT  •  Unavailable inside Cliffside"
		hunt.disabled = true
		hunt.tooltip_text = "Use Explore or Patrol to challenge local outlaws."
	var b: Button = scroll.find_child("Daily_Bedtime", true, false) as Button
	if b != null:
		b.text = "GO TO BED  •  Ordinary tomorrow (story remains here)"
	_front_label(content, "WALLET: %d GOLD  •  Outlaw wins: %d" % [
		economy_engine.wallet(), int(economy_engine.state.get("outlaw_victories", 0))], 17, Color(0.94, 0.86, 0.61))
	var market := _front_button(content, "VISIT THE MARKET  •  Buy and sell (free)",
		Callable(self, "_open_market").bind("daily"), 44.0)
	market.name = "Daily_VisitMarket"
	var other := "haniel" if str(current_profile.get("pov", "")) == "asmodeus" else "asmodeus"
	var switch := _front_button(content, "PLAY %s'S DAILY ROUTINE" % other.to_upper(),
		Callable(self, "_enter_cliffside_day").bind(other), 43.0)
	switch.name = "Daily_SwitchPOV"


func _bedtime_question() -> void:
	if not _is_cliffside_day():
		super._bedtime_question()
		return
	var content := _party_panel("THE EVENING IN CLIFFSIDE", "The authored story currently ends after Part Six.")
	_front_label(content, "An ordinary tomorrow refills your three daily actions. The story will not advance until another chapter is implemented.", 16).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ordinary := _front_button(content, "AN ORDINARY DAY  •  Stay in Cliffside", _ordinary_tomorrow, 52.0)
	ordinary.name = "CliffsideOrdinaryTomorrow"
	_front_button(content, "NOT YET  •  Return to activities", _draw_interlude, 46.0)


func _start_hunt() -> void:
	if _is_cliffside_day():
		last_activity_text = "Cliffside's streets have no wildlife hunting grounds. Explore or Patrol to face outlaws instead."
		_draw_interlude()
		return
	super._start_hunt()


func _take_interlude_action(id: String) -> void:
	if _is_cliffside_day() and ["explore", "patrol"].has(id):
		var pov := str(current_profile.get("pov", ""))
		var required := "explore" if pov == "asmodeus" else "patrol"
		if id != required or interlude_engine == null or not interlude_engine.can_spend_action():
			return
		if int(interlude_engine.state.get("hp", 0)) <= 0:
			last_activity_text = "Recover before heading into another confrontation."
			_draw_interlude()
			return
		interlude_engine.spend(id)
		_save_interlude()  # Spend the daily action BEFORE entering combat.
		_start_outlaw_encounter()
		return
	if _is_cliffside_day() and id == "explore_safely":
		if not interlude_engine.can_spend_action():
			return
		interlude_engine.spend(id)
		last_activity_text = "Haniel watches families cross the town square, helps a lost child find home, and quietly learns a little more about ordinary human life."
		_save_interlude()
		_draw_interlude()
		return
	super._take_interlude_action(id)


func _start_outlaw_encounter(forced_id: String = "") -> void:
	if not _is_cliffside_day() or live_outlaw_active:
		return
	_outlaw_load()
	var pov: String = str(current_profile.get("pov", "asmodeus"))
	var candidates: Array = outlaw_data.get("scenarios", {}).get(pov, [])
	if candidates.is_empty():
		last_activity_text = "There are no available encounters here."
		_draw_interlude()
		return
	var chosen: Dictionary = candidates[randi_range(0, candidates.size() - 1)]
	if forced_id != "":
		for raw in candidates:
			var option: Dictionary = raw
			if str(option.get("id", "")) == forced_id:
				chosen = option
				break
	_party_load()
	var active_ids: Array = []
	# The protagonist of the selected routine always participates, even if
	# their normal party configuration has them currently on the bench.
	active_ids.append(pov)
	for id in party_engine.active:
		var name := str(id)
		if name != "" and name != pov and party_engine.is_unlocked(name) and active_ids.size() < 3:
			active_ids.append(name)
	var reserve_ids: Array = []
	for id in party_engine.unlocked:
		if not active_ids.has(id):
			reserve_ids.append(id)
	var sheets: Dictionary = {}
	for id in party_engine.unlocked:
		sheets[id] = party_engine.sheet(id, save_data)
	var pov_sheet: Dictionary = sheets.get(pov, {})
	pov_sheet["hp"] = int(interlude_engine.state.get("hp", pov_sheet.get("hp", 100)))
	pov_sheet["max_hp"] = int(interlude_engine.state.get("max_hp", pov_sheet.get("max_hp", 100)))
	sheets[pov] = pov_sheet
	party_battle_area = str(chosen.get("area", "cliffside_alley"))
	party_battle = PartyBattleEngine.new()
	party_battle.setup(active_ids, reserve_ids, sheets, chosen.get("enemies", []), selected_profile)
	live_outlaw_scenario = chosen.duplicate(true)
	live_outlaw_pov = pov
	live_outlaw_resolved = false
	live_outlaw_active = true
	party_battle_active = true
	party_battle.last_log = str(chosen.get("intro", "Outlaws block the way."))
	_party_battle_draw()


func _battle_panel(title_text: String) -> VBoxContainer:
	if not live_outlaw_active:
		return super._battle_panel(title_text)
	_set_area_background(party_battle_area)
	var content := _party_panel(title_text, str(live_outlaw_scenario.get("title", "Cliffside Encounter")) + "  •  Real daily encounter")
	_battle_roster_row(content)
	_front_label(content, str(party_battle.last_log), 15, Color(0.95, 0.84, 0.70)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return content


func _party_battle_draw() -> void:
	if live_outlaw_active and party_battle != null and party_battle.finished:
		_finish_outlaw_encounter(false)
		return
	super._party_battle_draw()
	if not live_outlaw_active or not party_battle_active:
		return
	var scroll: ScrollContainer = frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	for child in scroll.find_children("*", "Button", true, false):
		var btn: Button = child
		if btn.text.begins_with("LEAVE PRACTICE"):
			btn.text = "RETREAT  •  No gold or EXP"
			btn.name = "OutlawRetreat"
		elif btn.text.begins_with("SWITCH FIGHTER"):
			btn.tooltip_text = "Switching uses this ally's turn."
	if scroll.find_child("OutlawRetreat", true, false) == null:
		var content: VBoxContainer = scroll.get_child(0).get_child(0) as VBoxContainer
		var retreat := _front_button(content, "RETREAT  •  No gold or EXP", _retreat_outlaw, 43.0)
		retreat.name = "OutlawRetreat"


func _retreat_outlaw() -> void:
	if live_outlaw_active:
		_finish_outlaw_encounter(true)


func _finish_outlaw_encounter(retreated: bool) -> void:
	if not live_outlaw_active or live_outlaw_resolved or party_battle == null:
		return
	live_outlaw_resolved = true
	var won: bool = party_battle.finished and party_battle.victory and not retreated
	var campaigns: Dictionary = save_data.get("campaigns", {})
	var lb: Dictionary = campaigns.get("love_beyond", {})
	var progression: Dictionary = lb.get("progression", {})
	for unit in party_battle.allies + party_battle.reserves:
		var data: Dictionary = unit
		var id: String = str(data.get("id", ""))
		if id == "":
			continue
		var hp: int = maxi(1, int(data.get("hp", 1)))
		if id == live_outlaw_pov:
			interlude_engine.state["hp"] = mini(hp, int(interlude_engine.state.get("max_hp", hp)))
		else:
			var prior: Dictionary = progression.get(id, {})
			prior["hp"] = mini(hp, maxi(1, int(data.get("max_hp", hp))))
			prior["max_hp"] = maxi(1, int(data.get("max_hp", hp)))
			progression[id] = prior
	lb["progression"] = progression
	campaigns["love_beyond"] = lb
	save_data["campaigns"] = campaigns

	var line: String = ""
	if won:
		_economy_load()
		var gold := randi_range(int(live_outlaw_scenario.get("gold_min", 10)), int(live_outlaw_scenario.get("gold_max", 20)))
		economy_engine.award_outlaw_gold(gold)
		economy_engine.write_to(save_data)
		var xp_amount := maxi(0, int(live_outlaw_scenario.get("exp", 15)))
		var xp_message: String = interlude_engine.earn_hunt_exp(xp_amount)
		line = "%s — The outlaws flee. You earned %d gold and %s." % [
			str(live_outlaw_scenario.get("title", "Cliffside Encounter")), gold, xp_message]
	elif retreated:
		line = "Retreated from %s. Your wounds and used food remain; no gold or EXP was awarded." % str(live_outlaw_scenario.get("title", "the encounter"))
	else:
		line = "The outlaws drove the party back. You escape with 1 HP if defeated. No gold or EXP awarded."
	live_outlaw_active = false
	party_battle_active = false
	live_outlaw_scenario = {}
	party_battle = null
	last_activity_text = line
	_save_interlude()
	_draw_interlude()


func _party_battle_food_menu() -> void:
	super._party_battle_food_menu()
	if not live_outlaw_active:
		return
	var scroll: ScrollContainer = frontend_body.find_child("PartyPanelScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	for child in scroll.find_children("*", "Label", true, false):
		var lbl: Label = child
		if lbl.text.begins_with("Food heals a living"):
			lbl.text = "Real daily encounter: food is consumed permanently and using it costs a fighter's turn."


func _party_battle_use_food(slot_index: int, target_index: int) -> void:
	if not live_outlaw_active:
		super._party_battle_use_food(slot_index, target_index)
		return
	if party_battle == null or party_battle.finished:
		return
	var actor: Dictionary = party_battle.current_actor()
	var actor_id := str(actor.get("id", ""))
	var items: Array = actor.get("items", [])
	var id := ""
	if slot_index >= 0 and slot_index < items.size():
		id = str(items[slot_index].get("id", ""))
	var result: Dictionary = party_battle.use_food(slot_index, target_index)
	if bool(result.get("ok", false)):
		_party_load()
		_inventory_load()
		if inventory_engine.consume_battle_food(actor_id, slot_index, id, party_engine.unlocked):
			inventory_engine.write_to(save_data)
			_inventory_persist()  # Permanent cost even if the player retreats.
	else:
		party_battle.last_log = str(result.get("message", "Unable to use food."))
	_party_battle_draw()


func _open_market(origin: String = "title") -> void:
	if _completed_story_part() < 6:
		return
	market_origin = origin
	market_message = ""
	_market_menu()


func _market_menu() -> void:
	_economy_load()
	_inventory_load()
	_set_area_background("market_street")
	var content := _party_panel("CLIFFSIDE MARKET", "Open after Part Six  •  Buying and selling cost no daily actions")
	_front_label(content, "YOUR WALLET: %d GOLD" % economy_engine.wallet(), 21, Color(0.95, 0.88, 0.65))
	if market_message != "":
		_front_label(content, market_message, 15, Color(0.94, 0.85, 0.70)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for entry in economy_engine.merchants():
		var shop: Dictionary = entry
		var merchant_id := str(shop.get("id", ""))
		_front_label(content, str(shop.get("name", "Merchant")) + " — " + str(shop.get("tagline", "")), 17)
		var buy := _front_button(content, "BUY FROM " + str(shop.get("name", "")).to_upper(),
			Callable(self, "_market_buy_menu").bind(merchant_id), 46.0)
		buy.name = "MarketMerchant_" + merchant_id
	var sell := _front_button(content, "SELL FROM SHARED BACKPACK", _market_sell_menu, 47.0)
	sell.name = "MarketSell"
	_front_button(content, "BACK", _market_close, 43.0)


func _market_buy_menu(merchant_id: String) -> void:
	_economy_load()
	_inventory_load()
	var merchant: Dictionary = economy_engine.merchant(merchant_id)
	if merchant.is_empty():
		_market_menu()
		return
	_set_area_background("market_street")
	var content := _party_panel(str(merchant.get("name", "Market Merchant")).to_upper(), "Wallet: %d gold  •  Select an item to purchase" % economy_engine.wallet())
	for offered in merchant.get("offers", []):
		var data: Dictionary = offered
		var id := str(data.get("item_id", ""))
		var item: Dictionary = inventory_engine.definition(id)
		var price: int = economy_engine.offer_price(merchant_id, id)
		var button := _front_button(content, "%s  •  %d GOLD" % [str(item.get("name", id)), price],
			Callable(self, "_market_buy").bind(merchant_id, id), 46.0)
		button.name = "MarketBuy_" + id
		button.disabled = price <= 0 or economy_engine.wallet() < price
		_front_label(content, str(item.get("description", "")), 13, Color(0.78, 0.86, 0.95)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "BACK TO MARKET", _market_menu, 44.0)


func _market_sell_menu() -> void:
	_economy_load()
	_inventory_load()
	_set_area_background("market_street")
	var content := _party_panel("SELL FROM YOUR BACKPACK", "Gold: %d  •  Equipped items must be unequipped first." % economy_engine.wallet())
	if inventory_engine.all_backpack_items().is_empty():
		_front_label(content, "The backpack is empty.", 16)
	for id in inventory_engine.all_backpack_items():
		var unit_price: int = economy_engine.resale_value(id)
		var button := _front_button(content, "%s ×%d  •  SELL ONE FOR %d GOLD" % [
			inventory_engine.name_of(id), inventory_engine.backpack_count(id), unit_price],
			Callable(self, "_market_sell").bind(id), 46.0)
		button.name = "MarketSell_" + id
		button.disabled = unit_price <= 0
	_front_button(content, "BACK TO MARKET", _market_menu, 44.0)


func _market_buy(merchant_id: String, item_id: String) -> void:
	_economy_load()
	_inventory_load()
	var result: Dictionary = economy_engine.buy(merchant_id, item_id, inventory_engine)
	market_message = str(result.get("message", "Purchase unavailable."))
	if bool(result.get("ok", false)):
		economy_engine.write_to(save_data)
		inventory_engine.write_to(save_data)
		_inventory_persist()
	_market_menu()


func _market_sell(item_id: String) -> void:
	_economy_load()
	_inventory_load()
	var result: Dictionary = economy_engine.sell(item_id, inventory_engine)
	market_message = str(result.get("message", "Sale unavailable."))
	if bool(result.get("ok", false)):
		economy_engine.write_to(save_data)
		inventory_engine.write_to(save_data)
		_inventory_persist()
	_market_menu()


func _market_close() -> void:
	if market_origin == "daily" and _is_cliffside_day():
		_draw_interlude()
	else:
		_show_menu()

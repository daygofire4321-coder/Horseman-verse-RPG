extends "res://scripts/prototype_story_v14.gd"
## Prototype 015 — Campaign hub and global navy/gold UI language.
## The existing Love Beyond game stays under its own campaign menu.
## Blades is an intentionally disabled, data-defined Coming Soon campaign.
## All save keys, author-written story and previously playable features persist.

const CAMPAIGN_REGISTRY := "res://data/campaigns/registry.json"
const CAMPAIGN_TITLE_IMAGE := "res://assets/paleverse/campaign_title.webp"

const UI_NAVY := Color(0.028, 0.044, 0.083, 0.955)
const UI_GOLD := Color(0.82, 0.69, 0.42, 0.91)
const UI_ICE := Color(0.73, 0.86, 0.98, 1.0)
const UI_TEXT := Color(0.95, 0.94, 0.91, 1.0)

var campaign_registry: Dictionary = {}
var selected_campaign := ""
var return_to_love_adventure := false


func _ready() -> void:
	super._ready()
	_polish_story_dialogue()


func _polish_story_dialogue() -> void:
	if not is_instance_valid(speaker):
		return
	var text_stack: Node = speaker.get_parent()
	if text_stack == null or not (text_stack.get_parent() is PanelContainer):
		return
	var panel: PanelContainer = text_stack.get_parent() as PanelContainer
	var style := _panel_style(false)
	style.bg_color = Color(0.018, 0.032, 0.070, 0.93)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	speaker.add_theme_color_override("font_color", UI_GOLD)
	message.add_theme_color_override("font_color", UI_TEXT)


func _panel_style(title_panel: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.041, 0.081, 0.85) if title_panel else UI_NAVY
	style.border_color = UI_GOLD if title_panel else Color(0.56, 0.68, 0.83, 0.77)
	style.set_border_width_all(2 if title_panel else 1)
	style.set_corner_radius_all(18 if title_panel else 12)
	style.set_content_margin_all(20 if title_panel else 18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8 if title_panel else 4
	return style


func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(8)
	return style


func _polish_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
	button.add_theme_stylebox_override("normal", _button_style(
		Color(0.085, 0.125, 0.19, 0.94), Color(0.41, 0.55, 0.69, 0.72)))
	button.add_theme_stylebox_override("hover", _button_style(
		Color(0.18, 0.22, 0.28, 0.98), UI_GOLD))
	button.add_theme_stylebox_override("pressed", _button_style(
		Color(0.25, 0.21, 0.16, 0.98), UI_GOLD))
	button.add_theme_stylebox_override("disabled", _button_style(
		Color(0.07, 0.09, 0.125, 0.82), Color(0.24, 0.29, 0.36, 0.5)))
	button.add_theme_stylebox_override("focus", _button_style(
		Color(0.0, 0.0, 0.0, 0.0), Color(0.75, 0.86, 0.99, 0.9)))
	button.add_theme_color_override("font_color", UI_TEXT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.69))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.93, 0.76))
	button.add_theme_color_override("font_disabled_color", Color(0.49, 0.55, 0.61))
	button.add_theme_color_override("font_focus_color", UI_TEXT)
	button.add_theme_font_size_override("font_size", 16)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _front_panel() -> VBoxContainer:
	var content: VBoxContainer = super._front_panel()
	var panel: PanelContainer = content.get_parent() as PanelContainer
	panel.add_theme_stylebox_override("panel", _panel_style())
	var screen_width: float = get_viewport_rect().size.x
	var normal_width := minf(785.0, maxf(320.0, screen_width - 32.0))
	frontend_body.custom_minimum_size = Vector2(normal_width, 0)
	panel.custom_minimum_size.x = normal_width
	return content


func _front_button(parent: Node, value: String, action: Callable, height: float = 54.0) -> Button:
	var button: Button = super._front_button(parent, value, action, height)
	_polish_button(button)
	return button


func _button(label_text: String, callback: Callable) -> void:
	super._button(label_text, callback)
	if is_instance_valid(action_row) and action_row.get_child_count() > 0:
		var button: Button = action_row.get_child(action_row.get_child_count() - 1) as Button
		if button != null:
			_polish_button(button)


func _show_menu() -> void:
	# Existing story/battle calls still flow through the historical title hook.
	# When fleeing a real patrol, preserve the old retreat logic and return to
	# that ordinary day instead of overriding it with the campaign selector.
	var was_live := live_outlaw_active and not live_outlaw_resolved and party_battle != null
	super._show_menu()
	if was_live:
		return
	selected_campaign = ""
	return_to_love_adventure = false
	_show_campaign_select()


func _read_campaign_registry() -> void:
	if campaign_registry.is_empty():
		campaign_registry = ContentStore.read_dictionary(CAMPAIGN_REGISTRY)


func _campaign_definition(id: String) -> Dictionary:
	_read_campaign_registry()
	for raw in campaign_registry.get("campaigns", []):
		var record: Dictionary = raw
		if str(record.get("id", "")) == id:
			return record
	return {}


func _title_backdrop() -> void:
	# Optional user-supplied title art. Without it, the existing title art
	# remains visible. No image pack is required to play this build.
	if ResourceLoader.exists(CAMPAIGN_TITLE_IMAGE):
		scene_image.texture = load(CAMPAIGN_TITLE_IMAGE)
		scene_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		_background("storm_clash.jpg")


func _prepare_campaign_screen() -> void:
	_ensure_layers()
	_hide_pixel_stage()
	_clear_buttons()
	_clear_frontend()
	frontend.show()
	portraits.hide()
	if is_instance_valid(boss_hud):
		boss_hud.hide()
	_set_hp_visible(false)
	heading.text = ""
	subheading.text = ""
	speaker.text = ""
	message.text = ""
	_title_backdrop()
	# Light enough to keep the supplied characters visible while the right-
	# aligned translucent card maintains legibility over the storm sky.
	if frontend.get_child_count() > 0 and frontend.get_child(0) is ColorRect:
		var veil: ColorRect = frontend.get_child(0) as ColorRect
		veil.color = Color(0.016, 0.023, 0.049, 0.27)


func _title_panel(header: String, subtitle: String) -> VBoxContainer:
	_prepare_campaign_screen()
	var screen: Vector2 = get_viewport_rect().size
	var safe_width: float = maxf(340.0, screen.x - 28.0)
	var safe_height: float = maxf(265.0, screen.y - 24.0)
	frontend_body.custom_minimum_size = Vector2(safe_width, 0)
	var scroll := ScrollContainer.new()
	scroll.name = "CampaignMenuScroll"
	scroll.custom_minimum_size = Vector2(safe_width, minf(640.0, safe_height))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	frontend_body.add_child(scroll)
	var layout := HBoxContainer.new()
	layout.name = "CampaignMenuLayout"
	layout.custom_minimum_size.x = safe_width - 10.0
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.alignment = BoxContainer.ALIGNMENT_END
	scroll.add_child(layout)
	var art_space := Control.new()
	art_space.name = "TitleArtSpace"
	art_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(art_space)
	var card := PanelContainer.new()
	card.name = "CampaignMenuCard"
	card.custom_minimum_size.x = minf(500.0, maxf(320.0, safe_width * 0.76))
	card.size_flags_horizontal = Control.SIZE_SHRINK_END
	card.add_theme_stylebox_override("panel", _panel_style(true))
	layout.add_child(card)
	var content := VBoxContainer.new()
	content.name = "CampaignMenuContent"
	content.add_theme_constant_override("separation", 11)
	card.add_child(content)
	var eyebrow := _front_label(content, "THE PALE HORSEMAN", 17, UI_GOLD)
	eyebrow.name = "CampaignBrand"
	var title_label := _front_label(content, header, 27, UI_TEXT)
	title_label.name = "CampaignPageTitle"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var subtitle_label := _front_label(content, subtitle, 15, UI_ICE)
	subtitle_label.name = "CampaignPageSubtitle"
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var line := HSeparator.new()
	line.add_theme_color_override("separator", Color(0.73, 0.61, 0.41, 0.7))
	content.add_child(line)
	return content


func _show_campaign_select() -> void:
	_read_campaign_registry()
	var content := _title_panel("SELECT CAMPAIGN", "Choose a story from the Pale Horseman universe.")
	for raw in campaign_registry.get("campaigns", []):
		var record: Dictionary = raw
		var id := str(record.get("id", ""))
		var playable := str(record.get("status", "")) == "playable" and id == "love_beyond"
		var title_text := str(record.get("title", id)).to_upper()
		var callback: Callable = Callable(self, "_open_campaign").bind(id)
		var button := _front_button(content, title_text, callback, 70.0)
		button.name = "CampaignChoice_" + id
		button.disabled = not playable
		button.tooltip_text = "Open this campaign." if playable else "Coming soon — this campaign isn't playable yet."
		var sub_text := "PLAYABLE  •  " if playable else "COMING SOON  •  "
		var note := _front_label(content, sub_text + str(record.get("subtitle", "")), 13,
			Color(0.90, 0.79, 0.54) if playable else Color(0.70, 0.75, 0.83))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_label(content, "Every campaign will have its own story and save progress.", 13, Color(0.75, 0.81, 0.88)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _open_campaign(id: String) -> void:
	var record: Dictionary = _campaign_definition(id)
	if str(record.get("status", "")) != "playable":
		return
	if id != "love_beyond":
		return
	selected_campaign = id
	_show_love_campaign()


func _show_love_campaign() -> void:
	selected_campaign = "love_beyond"
	var content := _title_panel("LOVE BEYOND", "Heaven or Hell  •  Choose your next adventure")
	_front_label(content, "An angel, a demon, and the lives they choose.", 15, Color(0.89, 0.90, 0.93))
	var continue_button := _front_button(content, "CONTINUE SAVED ADVENTURE", _resume_adventure, 49.0)
	continue_button.name = "LoveContinue"
	continue_button.disabled = not _has_resumable_interlude()
	continue_button.tooltip_text = "No active interlude checkpoint. You can start the story or visit unlocked free time." if continue_button.disabled else "Resume the last saved story interlude."
	var start := _front_button(content, "BEGIN THE STORY", _start_dialogue, 52.0)
	start.name = "LoveBegin"
	var adventure := _front_button(content, "ADVENTURE  •  PARTY, INVENTORY & TOWN", _show_love_adventure, 50.0)
	adventure.name = "LoveAdventure"
	var extras := _front_button(content, "PRACTICE & EXTRAS", _show_love_extras, 48.0)
	extras.name = "LoveExtras"
	_front_button(content, "BACK TO CAMPAIGN SELECT", _show_campaign_select, 45.0)


func _show_love_adventure() -> void:
	var content := _title_panel("YOUR ADVENTURE", "Manage your Love Beyond party, or visit unlocked locations.")
	var party_button := _front_button(content, "PARTY & CHARACTER SHEETS",
		_open_party_from_love, 49.0)
	party_button.name = "LoveParty"
	var inventory_button := _front_button(content, "SHARED BACKPACK & EQUIPMENT", _open_inventory_from_love, 48.0)
	inventory_button.name = "LoveInventory"
	var town := _front_button(content, "CLIFFSIDE FREE TIME  •  EXPLORE / PATROL",
		_cliffside_day_selector, 48.0)
	town.name = "LoveCliffside"
	town.disabled = _completed_story_part() < 6
	var market := _front_button(content, "CLIFFSIDE MARKET  •  BUY / SELL",
		Callable(self, "_open_market").bind("love_adventure"), 48.0)
	market.name = "LoveMarket"
	market.disabled = _completed_story_part() < 6
	if _completed_story_part() < 6:
		_front_label(content, "Cliffside unlocks after Part Six.", 14, Color(0.79, 0.83, 0.92))
	_front_button(content, "BACK TO LOVE BEYOND", _show_love_campaign, 44.0)


func _show_love_extras() -> void:
	var content := _title_panel("PRACTICE & EXTRAS", "Gameplay tests and art galleries live here, not on the main title.")
	var battle := _front_button(content, "THREE-CHARACTER BATTLE PRACTICE",
		_party_battle_select_arena, 47.0)
	battle.name = "LoveBattlePractice"
	var duel := _front_button(content, "QUICK DUEL  •  HANIEL VS ASMODEUS", _choose_fighter, 47.0)
	duel.name = "LoveQuickDuel"
	var locations := _front_button(content, "LOCATION GALLERY",
		Callable(self, "_show_location_gallery").bind(0), 45.0)
	locations.name = "LoveLocationGallery"
	var sprites := _front_button(content, "CHARACTER SPRITE GALLERY",
		Callable(self, "_show_sprite_gallery").bind(0), 45.0)
	sprites.name = "LoveSpriteGallery"
	var about := _front_button(content, "ABOUT THIS BUILD", _show_about, 44.0)
	about.name = "LoveAbout"
	_front_button(content, "BACK TO LOVE BEYOND", _show_love_campaign, 44.0)


func _show_about() -> void:
	# Replace the old Prototype 002 description with a current overview.
	var content := _title_panel("ABOUT THE GAME", "Prototype 015  •  Campaign hub and UI visual pass")
	_front_label(content, "LOVE BEYOND HEAVEN OR HELL", 19, UI_GOLD)
	_front_label(content,
		"Playable story, free-time routines, training, three-person practice combat, equipment, outlaw encounters, gold, and Cliffside market.",
		15, UI_TEXT).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_label(content,
		"BLADES OF COURAGE AND FEROCITY is coming soon. Its campaign remains unavailable and no Blades save is created.",
		15, UI_ICE).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_label(content,
		"UI panels use deep navy, gold and pale blue. Add your supplied title illustration to assets/paleverse/campaign_title.webp.",
		14, Color(0.78, 0.83, 0.88)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_button(content, "BACK TO EXTRAS", _show_love_extras, 45.0)



func _open_party_from_love() -> void:
	return_to_love_adventure = true
	_show_party_menu(false)


func _close_party_menu() -> void:
	if return_to_love_adventure and not party_return_to_daily:
		return_to_love_adventure = false
		_show_love_adventure()
	else:
		return_to_love_adventure = false
		super._close_party_menu()


func _open_inventory_from_love() -> void:
	_open_inventory("", "love_adventure")


func _inventory_close() -> void:
	if inventory_origin == "love_adventure":
		_show_love_adventure()
	else:
		super._inventory_close()


func _market_close() -> void:
	if market_origin == "love_adventure":
		_show_love_adventure()
	else:
		super._market_close()

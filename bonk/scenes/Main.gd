extends Control

# Navigation
var _current_screen: String = "expedition"
var _screens: Dictionary = {}
var _nav_buttons: Dictionary = {}

# Expedition screen
var monster_name_label: Label
var monster_hp_label: Label
var monster_hp_bar: ProgressBar
var player_hp_label: Label
var player_hp_bar: ProgressBar
var combat_log: RichTextLabel
var action_button: Button

# Character screen
var stats_label: Label
var inventory_label: Label
var gear_label: Label
var _equip_container: VBoxContainer
var _unequip_container: VBoxContainer

# Bonkery screen
var craft_container: VBoxContainer
var _building_label: Label

# Thinkery screen
var _research_container: VBoxContainer
var _research_status_label: Label

var _recipes: Array[CraftingRecipe] = []
var _log_lines: Array[String] = []
const LOG_MAX := 8

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Screen container
	var screen_container := MarginContainer.new()
	screen_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		screen_container.add_theme_constant_override("margin_" + side, 16)
	root.add_child(screen_container)

	# Build screens
	_build_expedition_screen(screen_container)
	_build_character_screen(screen_container)
	_build_tribe_screen(screen_container)
	_build_bonkery_screen(screen_container)
	_build_thinkery_screen(screen_container)

	# Bottom navigation
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 0)
	root.add_child(nav)

	for screen_id in ["expedition", "character", "tribe"]:
		var label := {"expedition": "⚔ Expedition", "character": "👤 Character", "tribe": "🏕 Tribe"}
		var btn := Button.new()
		btn.text = label[screen_id]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_navigate.bind(screen_id))
		nav.add_child(btn)
		_nav_buttons[screen_id] = btn

	# Connect signals
	EventBus.player_hit_monster.connect(_on_player_hit)
	EventBus.player_missed.connect(_on_player_missed)
	EventBus.monster_hit_player.connect(_on_monster_hit)
	EventBus.player_blocked.connect(_on_player_blocked)
	EventBus.monster_missed.connect(_on_monster_missed)
	EventBus.monster_died.connect(_on_monster_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.item_obtained.connect(_on_item_obtained)
	EventBus.item_removed.connect(func(_i, _q): _refresh_inventory())
	EventBus.expedition_ended.connect(_on_expedition_ended)
	EventBus.stat_leveled_up.connect(_on_stat_leveled_up)
	EventBus.stat_xp_gained.connect(func(_s, _a): _refresh_stats())
	EventBus.item_obtained.connect(func(_i, _q): _refresh_inventory(); _refresh_craft_ui())
	EventBus.item_crafted.connect(func(_r, _i): _refresh_inventory(); _refresh_gear(); _refresh_craft_ui())
	EventBus.building_upgrade_completed.connect(func(_b, _l): _refresh_buildings(); _refresh_craft_ui())
	EventBus.research_completed.connect(func(_r): _refresh_research_ui(); _log("[color=cyan]Research complete![/color]"))
	EventBus.content_unlocked.connect(func(id): _log("[color=cyan]Unlocked: %s[/color]" % id))
	EventBus.offline_progress_applied.connect(_on_offline_progress)

	_load_recipes()
	_refresh_all()
	_navigate("expedition")

	if ExpeditionManager.active and ExpeditionManager.current_monster:
		var monster := ExpeditionManager.current_monster
		monster_name_label.text = monster.name
		monster_hp_bar.max_value = monster.hp
		monster_hp_bar.value = ExpeditionManager._monster_hp
		action_button.text = "Recall"

	if not GameManager.pending_offline_summary.is_empty():
		var s := GameManager.pending_offline_summary
		_on_offline_progress(s["elapsed"], s)
		GameManager.pending_offline_summary = {}

# --- Screen builders ---

func _build_expedition_screen(parent: Control) -> void:
	var screen := _make_scroll_screen("expedition", parent)

	monster_name_label = Label.new()
	monster_name_label.text = "No monster"
	monster_name_label.add_theme_font_size_override("font_size", 22)
	screen.add_child(monster_name_label)

	monster_hp_bar = ProgressBar.new()
	monster_hp_bar.min_value = 0
	monster_hp_bar.custom_minimum_size.y = 20
	screen.add_child(monster_hp_bar)

	monster_hp_label = Label.new()
	screen.add_child(monster_hp_label)

	screen.add_child(HSeparator.new())

	var player_title := Label.new()
	player_title.text = "You"
	player_title.add_theme_font_size_override("font_size", 22)
	screen.add_child(player_title)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.min_value = 0
	player_hp_bar.custom_minimum_size.y = 20
	screen.add_child(player_hp_bar)

	player_hp_label = Label.new()
	screen.add_child(player_hp_label)

	screen.add_child(HSeparator.new())

	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.fit_content = true
	combat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screen.add_child(combat_log)

	screen.add_child(HSeparator.new())

	action_button = Button.new()
	action_button.text = "Start Expedition"
	action_button.custom_minimum_size.y = 48
	action_button.pressed.connect(_on_action_pressed)
	screen.add_child(action_button)

func _build_character_screen(parent: Control) -> void:
	var screen := _make_scroll_screen("character", parent)

	var stats_title := Label.new()
	stats_title.text = "Stats"
	stats_title.add_theme_font_size_override("font_size", 18)
	screen.add_child(stats_title)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 13)
	screen.add_child(stats_label)

	screen.add_child(HSeparator.new())

	var gear_title := Label.new()
	gear_title.text = "Gear"
	gear_title.add_theme_font_size_override("font_size", 18)
	screen.add_child(gear_title)

	gear_label = Label.new()
	gear_label.add_theme_font_size_override("font_size", 13)
	screen.add_child(gear_label)

	_unequip_container = VBoxContainer.new()
	screen.add_child(_unequip_container)

	screen.add_child(HSeparator.new())

	var inv_title := Label.new()
	inv_title.text = "Inventory"
	inv_title.add_theme_font_size_override("font_size", 18)
	screen.add_child(inv_title)

	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 13)
	screen.add_child(inventory_label)

	_equip_container = VBoxContainer.new()
	screen.add_child(_equip_container)

func _build_tribe_screen(parent: Control) -> void:
	var screen := _make_scroll_screen("tribe", parent)

	var title := Label.new()
	title.text = "The Tribe"
	title.add_theme_font_size_override("font_size", 22)
	screen.add_child(title)

	screen.add_child(HSeparator.new())

	for building in [["bonkery", "Bonkery"], ["thinkery", "Thinkery"]]:
		var btn := Button.new()
		btn.text = building[1]
		btn.custom_minimum_size.y = 48
		btn.pressed.connect(_navigate.bind(building[0]))
		screen.add_child(btn)

func _build_bonkery_screen(parent: Control) -> void:
	var screen := _make_scroll_screen("bonkery", parent)

	var back := _make_back_button()
	screen.add_child(back)

	var title := Label.new()
	title.text = "Bonkery"
	title.add_theme_font_size_override("font_size", 22)
	screen.add_child(title)

	screen.add_child(HSeparator.new())

	_building_label = Label.new()
	_building_label.add_theme_font_size_override("font_size", 13)
	screen.add_child(_building_label)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "Upgrade Bonkery"
	upgrade_btn.pressed.connect(_on_upgrade_bonkery)
	screen.add_child(upgrade_btn)

	screen.add_child(HSeparator.new())

	var craft_title := Label.new()
	craft_title.text = "Crafting"
	craft_title.add_theme_font_size_override("font_size", 16)
	screen.add_child(craft_title)

	craft_container = VBoxContainer.new()
	screen.add_child(craft_container)

func _build_thinkery_screen(parent: Control) -> void:
	var screen := _make_scroll_screen("thinkery", parent)

	var back := _make_back_button()
	screen.add_child(back)

	var title := Label.new()
	title.text = "Thinkery"
	title.add_theme_font_size_override("font_size", 22)
	screen.add_child(title)

	screen.add_child(HSeparator.new())

	_research_status_label = Label.new()
	_research_status_label.add_theme_font_size_override("font_size", 13)
	screen.add_child(_research_status_label)

	_research_container = VBoxContainer.new()
	_research_container.add_theme_constant_override("separation", 8)
	screen.add_child(_research_container)

# --- Helpers ---

func _make_scroll_screen(id: String, parent: Control) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.visible = false
	parent.add_child(scroll)
	_screens[id] = scroll

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	scroll.add_child(inner)
	return inner

func _make_back_button() -> Button:
	var btn := Button.new()
	btn.text = "← Tribe"
	btn.pressed.connect(_navigate.bind("tribe"))
	return btn

func _navigate(screen_id: String) -> void:
	for id in _screens:
		_screens[id].visible = (id == screen_id)
	_current_screen = screen_id
	if screen_id == "bonkery":
		_refresh_buildings()
		_refresh_craft_ui()
	elif screen_id == "thinkery":
		_refresh_research_ui()
	elif screen_id == "character":
		_refresh_stats()
		_refresh_gear()
		_refresh_inventory()

# --- Process ---

func _process(_delta: float) -> void:
	if ExpeditionManager.active:
		_refresh_player_hp()
		_refresh_monster_hp()
	if ResearchManager.active_research_id != "" and _current_screen == "thinkery":
		var secs := ResearchManager.time_remaining()
		_research_status_label.text = "Researching: %s  (%.0fs left)" % [ResearchManager.active_research_id, secs]

# --- Expedition ---

func _on_action_pressed() -> void:
	if ExpeditionManager.active:
		ExpeditionManager.recall()
		action_button.text = "Start Expedition"
	else:
		var monster := load("res://data/test_monster.tres") as MonsterData
		ExpeditionManager.start("test_zone", monster)
		monster_name_label.text = monster.name
		monster_hp_bar.max_value = monster.hp
		monster_hp_bar.value = monster.hp
		monster_hp_label.text = "%d / %d" % [monster.hp, monster.hp]
		action_button.text = "Recall"
		_log("--- Expedition started ---")

func _refresh_player_hp() -> void:
	var hp := CharacterManager.current_hp
	var max_hp := CharacterManager.max_hp
	player_hp_bar.max_value = max_hp
	player_hp_bar.value = hp
	player_hp_label.text = "%d / %d HP" % [hp, max_hp]

func _refresh_monster_hp() -> void:
	var hp := ExpeditionManager._monster_hp
	var max_hp := ExpeditionManager.current_monster.hp if ExpeditionManager.current_monster else 1
	monster_hp_bar.value = maxi(0, hp)
	monster_hp_label.text = "%d / %d" % [maxi(0, hp), max_hp]

func _on_player_hit(damage: int, _type: int, multiplier: float) -> void:
	if multiplier > 1.0:
		_log("[color=yellow]You hit for %d (WEAK!)[/color]" % damage)
	elif multiplier < 1.0:
		_log("[color=gray]You hit for %d (resisted)[/color]" % damage)
	else:
		_log("You hit for %d" % damage)

func _on_player_missed() -> void:
	_log("[color=gray]You missed.[/color]")

func _on_monster_hit(damage: int) -> void:
	_log("[color=red]Monster hits you for %d[/color]" % damage)

func _on_player_blocked(_damage: int) -> void:
	_log("[color=cyan]You blocked![/color]")

func _on_monster_missed() -> void:
	_log("[color=gray]Monster missed.[/color]")

func _on_monster_died(_monster: MonsterData) -> void:
	_log("[color=green]Monster defeated![/color]")

func _on_player_died() -> void:
	_log("[color=red]You died.[/color]")
	action_button.text = "Start Expedition"

func _on_item_obtained(item: ItemData, quantity: int) -> void:
	_log("[color=gold]Drop: %s x%d[/color]" % [item.name, quantity])

func _on_expedition_ended(_result: Dictionary) -> void:
	action_button.text = "Start Expedition"

func _log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > LOG_MAX:
		_log_lines = _log_lines.slice(_log_lines.size() - LOG_MAX)
	combat_log.text = "\n".join(_log_lines)

# --- Character ---

func _refresh_all() -> void:
	_refresh_stats()
	_refresh_gear()
	_refresh_inventory()
	_refresh_player_hp()

func _refresh_stats() -> void:
	var lines := []
	for stat in ["hp", "strength", "defense", "speed", "accuracy"]:
		var level := CharacterManager.get_level(stat)
		var xp: float = CharacterManager.stats[stat]["xp"]
		var needed := CharacterManager.xp_for_level(level + 1)
		lines.append("%s: %d  (%.0f / %.0f xp)" % [stat.capitalize(), level, xp, needed])
	stats_label.text = "\n".join(lines)

func _on_stat_leveled_up(stat_name: String, new_level: int) -> void:
	_log("[color=cyan]%s leveled up to %d![/color]" % [stat_name.capitalize(), new_level])
	_refresh_stats()

func _refresh_gear() -> void:
	var main := CharacterManager.equipped_main_hand
	var off := CharacterManager.equipped_off_hand
	gear_label.text = "Main hand: %s\nOff hand:  %s" % [main.name if main else "none", off.name if off else "none"]
	if _unequip_container:
		for child in _unequip_container.get_children():
			child.queue_free()
		if main:
			var btn := Button.new()
			btn.text = "Unequip %s" % main.name
			btn.pressed.connect(func(): CharacterManager.unequip(GearData.Slot.MAIN_HAND); _refresh_gear(); _refresh_stats())
			_unequip_container.add_child(btn)
		if off:
			var btn := Button.new()
			btn.text = "Unequip %s" % off.name
			btn.pressed.connect(func(): CharacterManager.unequip(GearData.Slot.OFF_HAND); _refresh_gear(); _refresh_stats())
			_unequip_container.add_child(btn)

func _refresh_inventory() -> void:
	var all := InventoryManager.get_all_items()
	if all.is_empty():
		inventory_label.text = "Empty"
		if _equip_container:
			for child in _equip_container.get_children():
				child.queue_free()
		return
	var lines := []
	for entry in all:
		lines.append("%s x%d" % [entry["data"].name, entry["quantity"]])
	inventory_label.text = "\n".join(lines)
	_rebuild_equip_buttons()

func _rebuild_equip_buttons() -> void:
	if _equip_container == null:
		return
	for child in _equip_container.get_children():
		child.queue_free()
	for entry in InventoryManager.get_all_items():
		var item: ItemData = entry["data"]
		if not item is GearData:
			continue
		var gear := item as GearData
		var btn := Button.new()
		btn.text = "Equip %s" % gear.name
		btn.pressed.connect(_on_equip_pressed.bind(gear))
		_equip_container.add_child(btn)

func _on_equip_pressed(gear: GearData) -> void:
	CharacterManager.equip(gear)
	_refresh_gear()
	_refresh_stats()

# --- Bonkery ---

func _refresh_buildings() -> void:
	var level := CityManager.get_level("bonkery")
	var upgrading := CityManager.is_upgrading("bonkery")
	_building_label.text = "Bonkery: Level %d%s" % [level, "  (upgrading...)" if upgrading else ""]

func _on_upgrade_bonkery() -> void:
	var data := load("res://data/buildings/bonkery.tres") as BuildingData
	if not data:
		return
	var cost: Array[CraftingIngredient] = []
	if CityManager.start_upgrade("bonkery", data, cost):
		_log("[color=lime]Bonkery upgrading![/color]")
		_refresh_buildings()

func _load_recipes() -> void:
	var dir := DirAccess.open("res://data/recipes/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://data/recipes/" + file_name)
			if res is CraftingRecipe:
				_recipes.append(res)
		file_name = dir.get_next()

func _refresh_craft_ui() -> void:
	if not craft_container:
		return
	for child in craft_container.get_children():
		child.queue_free()
	for recipe in _recipes:
		var can := CraftingManager.can_craft(recipe)
		var row := HBoxContainer.new()
		var label := Label.new()
		var ingredient_text := ""
		for ing in recipe.ingredients:
			var have := InventoryManager.get_quantity(ing.item.id)
			ingredient_text += "%s %d/%d  " % [ing.item.name, have, ing.quantity]
		label.text = "%s  ←  %s" % [recipe.result_item.name, ingredient_text.strip_edges()]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 12)
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Craft"
		btn.disabled = not can
		btn.pressed.connect(_on_craft_pressed.bind(recipe))
		row.add_child(btn)
		craft_container.add_child(row)

func _on_craft_pressed(recipe: CraftingRecipe) -> void:
	if CraftingManager.craft(recipe):
		_log("[color=lime]Crafted: %s[/color]" % recipe.result_item.name)

# --- Thinkery ---

func _refresh_research_ui() -> void:
	if not _research_container:
		return
	for child in _research_container.get_children():
		child.queue_free()
	if ResearchManager.active_research_id != "":
		var secs := ResearchManager.time_remaining()
		_research_status_label.text = "Researching: %s  (%.0fs left)" % [ResearchManager.active_research_id, secs]
	else:
		_research_status_label.text = "Idle"
	var all := ResourceRegistry.get_all_research()
	var available := ResearchManager.get_available(all)
	for data in available:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "%s  (%ds)" % [data.title, int(data.duration_seconds)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Research"
		btn.disabled = ResearchManager.active_research_id != ""
		btn.pressed.connect(_on_research_pressed.bind(data))
		row.add_child(btn)
		_research_container.add_child(row)
	for data in all:
		if not ResearchManager.is_completed(data.id):
			continue
		var done_label := Label.new()
		done_label.text = "✓ %s" % data.title
		_research_container.add_child(done_label)

func _on_research_pressed(data: ResearchData) -> void:
	if ResearchManager.start(data):
		_refresh_research_ui()
	else:
		_log("[color=gray]Cannot start research.[/color]")

# --- Offline progress ---

func _on_offline_progress(elapsed: float, summary: Dictionary) -> void:
	var mins := int(elapsed / 60)
	_log("[color=gold]--- Offline: %dm, %d kills ---[/color]" % [mins, summary["kills"]])
	for item_name in summary["drops"]:
		_log("[color=gold]  %s x%d[/color]" % [item_name, summary["drops"][item_name]])
	_refresh_inventory()
	_refresh_stats()

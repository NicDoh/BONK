extends Control

var monster_name_label: Label
var monster_hp_label: Label
var monster_hp_bar: ProgressBar

var player_hp_label: Label
var player_hp_bar: ProgressBar

var combat_log: RichTextLabel
var action_button: Button
var stats_label: Label
var inventory_label: Label
var gear_label: Label
var craft_container: VBoxContainer

var _recipes: Array[CraftingRecipe] = []

var _log_lines: Array[String] = []
const LOG_MAX := 6

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Outer layout: scrollable content + fixed button at bottom
	var outer := VBoxContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 12)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(inner)

	# Monster section
	monster_name_label = Label.new()
	monster_name_label.text = "No monster"
	monster_name_label.add_theme_font_size_override("font_size", 20)
	inner.add_child(monster_name_label)

	monster_hp_bar = ProgressBar.new()
	monster_hp_bar.min_value = 0
	monster_hp_bar.value = 0
	monster_hp_bar.custom_minimum_size.y = 20
	inner.add_child(monster_hp_bar)

	monster_hp_label = Label.new()
	monster_hp_label.text = ""
	inner.add_child(monster_hp_label)

	inner.add_child(HSeparator.new())

	# Player section
	var player_title := Label.new()
	player_title.text = "You"
	player_title.add_theme_font_size_override("font_size", 20)
	inner.add_child(player_title)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.min_value = 0
	player_hp_bar.custom_minimum_size.y = 20
	inner.add_child(player_hp_bar)

	player_hp_label = Label.new()
	inner.add_child(player_hp_label)

	inner.add_child(HSeparator.new())

	# Stats
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 12)
	inner.add_child(stats_label)
	_refresh_stats()

	inner.add_child(HSeparator.new())

	# Inventory
	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 12)
	inner.add_child(inventory_label)
	_refresh_inventory()

	inner.add_child(HSeparator.new())

	# Gear
	gear_label = Label.new()
	gear_label.add_theme_font_size_override("font_size", 12)
	inner.add_child(gear_label)

	_equip_container = VBoxContainer.new()
	_equip_container.add_theme_constant_override("separation", 4)
	inner.add_child(_equip_container)

	_unequip_container = VBoxContainer.new()
	_unequip_container.add_theme_constant_override("separation", 4)
	inner.add_child(_unequip_container)

	_refresh_gear()

	inner.add_child(HSeparator.new())

	# Crafting
	var craft_title := Label.new()
	craft_title.text = "Bonkery"
	craft_title.add_theme_font_size_override("font_size", 16)
	inner.add_child(craft_title)

	craft_container = VBoxContainer.new()
	craft_container.add_theme_constant_override("separation", 6)
	inner.add_child(craft_container)
	_load_recipes()
	_refresh_craft_ui()

	inner.add_child(HSeparator.new())

	# Combat log
	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.fit_content = true
	combat_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(combat_log)

	# Fixed button at bottom
	var btn_margin := MarginContainer.new()
	for side in ["left", "right", "bottom"]:
		btn_margin.add_theme_constant_override("margin_" + side, 16)
	btn_margin.add_theme_constant_override("margin_top", 8)
	outer.add_child(btn_margin)

	action_button = Button.new()
	action_button.text = "Start Expedition"
	action_button.custom_minimum_size.y = 48
	action_button.pressed.connect(_on_action_pressed)
	btn_margin.add_child(action_button)

	# Connect signals
	EventBus.player_hit_monster.connect(_on_player_hit)
	EventBus.player_missed.connect(_on_player_missed)
	EventBus.monster_hit_player.connect(_on_monster_hit)
	EventBus.player_blocked.connect(_on_player_blocked)
	EventBus.monster_missed.connect(_on_monster_missed)
	EventBus.monster_died.connect(_on_monster_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.item_obtained.connect(_on_item_obtained)
	EventBus.expedition_ended.connect(_on_expedition_ended)
	EventBus.stat_leveled_up.connect(_on_stat_leveled_up)
	EventBus.stat_xp_gained.connect(func(_s, _a): _refresh_stats())
	EventBus.item_obtained.connect(func(_i, _q): _refresh_inventory(); _refresh_craft_ui())
	EventBus.item_removed.connect(func(_i, _q): _refresh_inventory(); _refresh_craft_ui())
	EventBus.item_crafted.connect(func(_r, _i): _refresh_inventory(); _refresh_gear(); _refresh_craft_ui())

	_refresh_player_hp()

func _process(_delta: float) -> void:
	if ExpeditionManager.active:
		_refresh_player_hp()
		_refresh_monster_hp()

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

func _on_stat_leveled_up(stat_name: String, new_level: int) -> void:
	_log("[color=cyan]%s leveled up to %d![/color]" % [stat_name.capitalize(), new_level])
	_refresh_stats()

func _refresh_stats() -> void:
	var lines := []
	for stat in ["hp", "strength", "defense", "speed", "accuracy"]:
		var level := CharacterManager.get_level(stat)
		var xp: float = CharacterManager.stats[stat]["xp"]
		var needed := CharacterManager.xp_for_level(level + 1)
		lines.append("%s: %d  (%.0f / %.0f xp)" % [stat.capitalize(), level, xp, needed])
	stats_label.text = "\n".join(lines)

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

func _refresh_gear() -> void:
	var main := CharacterManager.equipped_main_hand
	var off := CharacterManager.equipped_off_hand
	var lines := ["Gear:"]
	lines.append("  Main hand: %s" % (main.name if main else "none"))
	lines.append("  Off hand:  %s" % (off.name if off else "none"))
	gear_label.text = "\n".join(lines)
	if _unequip_container:
		_rebuild_unequip_buttons(_unequip_container)
	_rebuild_equip_buttons()

func _rebuild_unequip_buttons(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()
	var main := CharacterManager.equipped_main_hand
	var off := CharacterManager.equipped_off_hand
	if main:
		var btn := Button.new()
		btn.text = "Unequip %s" % main.name
		btn.pressed.connect(func(): CharacterManager.unequip(GearData.Slot.MAIN_HAND); _refresh_gear(); _refresh_stats())
		container.add_child(btn)
	if off:
		var btn := Button.new()
		btn.text = "Unequip %s" % off.name
		btn.pressed.connect(func(): CharacterManager.unequip(GearData.Slot.OFF_HAND); _refresh_gear(); _refresh_stats())
		container.add_child(btn)

func _refresh_inventory() -> void:
	var all := InventoryManager.get_all_items()
	if all.is_empty():
		inventory_label.text = "Inventory: empty"
		return
	var lines := ["Inventory:"]
	for entry in all:
		var item: ItemData = entry["data"]
		var line := "  %s x%d" % [item.name, entry["quantity"]]
		if item is GearData:
			line += "  [equip →]"
		lines.append(line)
	inventory_label.text = "\n".join(lines)
	# Equip buttons — rebuild below gear label would be complex, use a simple approach:
	# If player has bone_club and it's not equipped, show equip option in gear section
	_rebuild_equip_buttons()

var _equip_container: VBoxContainer = null
var _unequip_container: VBoxContainer = null

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

func _log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > LOG_MAX:
		_log_lines = _log_lines.slice(_log_lines.size() - LOG_MAX)
	combat_log.text = "\n".join(_log_lines)

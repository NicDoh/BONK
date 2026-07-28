class_name CharacterScreen
extends ScrollContainer

var _stats_label: Label
var _gear_label: Label
var _unequip_container: VBoxContainer
var _inventory_label: Label
var _equip_container: VBoxContainer

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	add_child(inner)

	var stats_title := Label.new()
	stats_title.text = "Stats"
	stats_title.add_theme_font_size_override("font_size", 18)
	inner.add_child(stats_title)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 13)
	inner.add_child(_stats_label)

	inner.add_child(HSeparator.new())

	var gear_title := Label.new()
	gear_title.text = "Gear"
	gear_title.add_theme_font_size_override("font_size", 18)
	inner.add_child(gear_title)

	_gear_label = Label.new()
	_gear_label.add_theme_font_size_override("font_size", 13)
	inner.add_child(_gear_label)

	_unequip_container = VBoxContainer.new()
	inner.add_child(_unequip_container)

	inner.add_child(HSeparator.new())

	var inv_title := Label.new()
	inv_title.text = "Inventory"
	inv_title.add_theme_font_size_override("font_size", 18)
	inner.add_child(inv_title)

	_inventory_label = Label.new()
	_inventory_label.add_theme_font_size_override("font_size", 13)
	inner.add_child(_inventory_label)

	_equip_container = VBoxContainer.new()
	inner.add_child(_equip_container)

	EventBus.stat_leveled_up.connect(func(_s, _l): refresh())
	EventBus.stat_xp_gained.connect(func(_s, _a): _refresh_stats())
	EventBus.item_obtained.connect(func(_i, _q): _refresh_inventory())
	EventBus.item_removed.connect(func(_i, _q): _refresh_inventory())
	EventBus.item_crafted.connect(func(_r, _i): _refresh_inventory(); _refresh_gear())

func refresh() -> void:
	_refresh_stats()
	_refresh_gear()
	_refresh_inventory()

func _refresh_stats() -> void:
	var lines := []
	for stat in ["hp", "strength", "defense", "speed", "accuracy"]:
		var level := CharacterManager.get_level(stat)
		var xp: float = CharacterManager.stats[stat]["xp"]
		var needed := CharacterManager.xp_for_level(level + 1)
		lines.append("%s: %d  (%.0f / %.0f xp)" % [stat.capitalize(), level, xp, needed])
	_stats_label.text = "\n".join(lines)

func _refresh_gear() -> void:
	var main := CharacterManager.equipped_main_hand
	var off := CharacterManager.equipped_off_hand
	_gear_label.text = "Main hand: %s\nOff hand:  %s" % [main.name if main else "none", off.name if off else "none"]
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
		_inventory_label.text = "Empty"
		for child in _equip_container.get_children():
			child.queue_free()
		return
	var lines := []
	for entry in all:
		lines.append("%s x%d" % [entry["data"].name, entry["quantity"]])
	_inventory_label.text = "\n".join(lines)
	_rebuild_equip_buttons()

func _rebuild_equip_buttons() -> void:
	for child in _equip_container.get_children():
		child.queue_free()
	for entry in InventoryManager.get_all_items():
		var item: ItemData = entry["data"]
		if not item is GearData:
			continue
		var gear := item as GearData
		var btn := Button.new()
		btn.text = "Equip %s" % gear.name
		btn.pressed.connect(func(): CharacterManager.equip(gear); _refresh_gear(); _refresh_stats())
		_equip_container.add_child(btn)

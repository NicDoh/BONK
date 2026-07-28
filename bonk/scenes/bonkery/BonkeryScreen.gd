class_name BonkeryScreen
extends ScrollContainer

signal navigate_to(screen_id: String)

var _building_label: Label
var _craft_container: VBoxContainer
var _recipes: Array[CraftingRecipe] = []

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	add_child(inner)

	var back := Button.new()
	back.text = "← Tribe"
	back.pressed.connect(navigate_to.emit.bind("tribe"))
	inner.add_child(back)

	var title := Label.new()
	title.text = "Bonkery"
	title.add_theme_font_size_override("font_size", 22)
	inner.add_child(title)

	inner.add_child(HSeparator.new())

	_building_label = Label.new()
	_building_label.add_theme_font_size_override("font_size", 13)
	inner.add_child(_building_label)

	var upgrade_btn := Button.new()
	upgrade_btn.text = "Upgrade Bonkery"
	upgrade_btn.pressed.connect(_on_upgrade_bonkery)
	inner.add_child(upgrade_btn)

	inner.add_child(HSeparator.new())

	var craft_title := Label.new()
	craft_title.text = "Crafting"
	craft_title.add_theme_font_size_override("font_size", 16)
	inner.add_child(craft_title)

	_craft_container = VBoxContainer.new()
	inner.add_child(_craft_container)

	EventBus.item_obtained.connect(func(_i, _q): _refresh_craft_ui())
	EventBus.item_removed.connect(func(_i, _q): _refresh_craft_ui())
	EventBus.item_crafted.connect(func(_r, _i): _refresh_craft_ui())
	EventBus.building_upgrade_completed.connect(func(_b, _l): _refresh_building(); _refresh_craft_ui())

	_load_recipes()

func refresh() -> void:
	_refresh_building()
	_refresh_craft_ui()

func _refresh_building() -> void:
	var level := CityManager.get_level("bonkery")
	var upgrading := CityManager.is_upgrading("bonkery")
	_building_label.text = "Bonkery: Level %d%s" % [level, "  (upgrading...)" if upgrading else ""]

func _on_upgrade_bonkery() -> void:
	var data := load("res://data/buildings/bonkery.tres") as BuildingData
	if not data:
		return
	var cost: Array[CraftingIngredient] = []
	CityManager.start_upgrade("bonkery", data, cost)
	_refresh_building()

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
	for child in _craft_container.get_children():
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
		_craft_container.add_child(row)

func _on_craft_pressed(recipe: CraftingRecipe) -> void:
	CraftingManager.craft(recipe)

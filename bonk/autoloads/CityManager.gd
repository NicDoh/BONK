extends Node

# { building_id: current_level }
var building_levels: Dictionary = {}

# { building_id: { "finish_time": float, "level": int } }
var upgrades_in_progress: Dictionary = {}

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	for building_id in upgrades_in_progress.keys():
		var upgrade: Dictionary = upgrades_in_progress[building_id]
		if now >= upgrade["finish_time"]:
			upgrades_in_progress.erase(building_id)
			building_levels[building_id] = upgrade["level"]
			EventBus.building_upgrade_completed.emit(building_id, upgrade["level"])

func get_level(building_id: String) -> int:
	return building_levels.get(building_id, 0)

func is_upgrading(building_id: String) -> bool:
	return upgrades_in_progress.has(building_id)

func start_upgrade(building_id: String, data: BuildingData, cost: Array[CraftingIngredient]) -> bool:
	var current_level := get_level(building_id)
	if current_level >= data.max_level:
		return false
	if is_upgrading(building_id):
		return false
	for ingredient in cost:
		if not InventoryManager.has_item(ingredient.item.id, ingredient.quantity):
			return false
	for ingredient in cost:
		InventoryManager.remove_item(ingredient.item, ingredient.quantity)
	var new_level := current_level + 1
	var duration: float = data.upgrade_durations[current_level] if current_level < data.upgrade_durations.size() else 60.0
	upgrades_in_progress[building_id] = {
		"finish_time": Time.get_unix_time_from_system() + duration,
		"level": new_level,
	}
	EventBus.building_upgrade_started.emit(building_id, new_level)
	return true

func serialize() -> Dictionary:
	return {
		"building_levels": building_levels.duplicate(),
		"upgrades_in_progress": upgrades_in_progress.duplicate(true),
	}

func deserialize(data: Dictionary) -> void:
	building_levels = data.get("building_levels", {})
	upgrades_in_progress = data.get("upgrades_in_progress", {})

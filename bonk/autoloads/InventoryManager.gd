extends Node

const INVENTORY_CAP: int = 500

# { slot_id: { "item_id": String, "quantity": int, "metadata": Dictionary } }
var items: Dictionary = {}

func add_item(item: ItemData, quantity: int = 1) -> bool:
	if is_full():
		EventBus.inventory_full.emit()
		return false

	if item.stackable:
		if items.has(item.id):
			var current: int = items[item.id]["quantity"]
			var space: int = item.max_stack - current
			var added: int = mini(quantity, space)
			items[item.id]["quantity"] += added
			if added > 0:
				EventBus.item_obtained.emit(item, added)
			return added == quantity
		else:
			items[item.id] = {"item_id": item.id, "quantity": mini(quantity, item.max_stack), "metadata": {}}
			EventBus.item_obtained.emit(item, items[item.id]["quantity"])
			return true
	else:
		var added := 0
		for i in quantity:
			if is_full():
				break
			var slot_id := item.id + "_" + str(Time.get_ticks_msec()) + "_" + str(i)
			items[slot_id] = {"item_id": item.id, "quantity": 1, "metadata": {}}
			added += 1
		if added > 0:
			EventBus.item_obtained.emit(item, added)
		return added == quantity

func remove_item(item: ItemData, quantity: int = 1) -> bool:
	if not has_item(item.id, quantity):
		return false
	items[item.id]["quantity"] -= quantity
	if items[item.id]["quantity"] <= 0:
		items.erase(item.id)
	EventBus.item_removed.emit(item, quantity)
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	return items.has(item_id) and items[item_id]["quantity"] >= quantity

func get_quantity(item_id: String) -> int:
	if items.has(item_id):
		return items[item_id]["quantity"]
	return 0

func get_metadata(slot_id: String) -> Dictionary:
	if items.has(slot_id):
		return items[slot_id]["metadata"]
	return {}

func set_metadata(slot_id: String, key: String, value) -> void:
	if items.has(slot_id):
		items[slot_id]["metadata"][key] = value

func is_full() -> bool:
	return items.size() >= INVENTORY_CAP

func get_all_items() -> Array:
	var result := []
	for slot_id in items:
		var slot: Dictionary = items[slot_id]
		var data := ResourceRegistry.find_item(slot["item_id"])
		if data:
			result.append({"slot_id": slot_id, "data": data, "quantity": slot["quantity"], "metadata": slot["metadata"]})
	return result

func serialize() -> Dictionary:
	var data := {}
	for slot_id in items:
		var slot: Dictionary = items[slot_id]
		data[slot_id] = {
			"item_id": slot["item_id"],
			"quantity": slot["quantity"],
			"metadata": slot["metadata"],
		}
	return data

func deserialize(data: Dictionary) -> void:
	items.clear()
	for slot_id in data:
		var entry: Dictionary = data[slot_id]
		items[slot_id] = {
			"item_id": entry["item_id"],
			"quantity": entry["quantity"],
			"metadata": entry.get("metadata", {}),
		}

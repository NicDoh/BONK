extends Node

const INVENTORY_CAP: int = 500

# { item_id: { "data": ItemData, "quantity": int } }
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
			items[item.id] = {"data": item, "quantity": mini(quantity, item.max_stack)}
			EventBus.item_obtained.emit(item, items[item.id]["quantity"])
			return true
	else:
		var added := 0
		for i in quantity:
			if is_full():
				break
			var slot_id := item.id + "_" + str(Time.get_ticks_msec()) + "_" + str(i)
			items[slot_id] = {"data": item, "quantity": 1}
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

func is_full() -> bool:
	return items.size() >= INVENTORY_CAP

func get_all_items() -> Array:
	return items.values()

func serialize() -> Dictionary:
	var data := {}
	for slot_id in items:
		var entry = items[slot_id]
		data[slot_id] = {
			"item_id": entry["data"].id,
			"quantity": entry["quantity"],
		}
	return data

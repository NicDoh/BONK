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

func deserialize(data: Dictionary) -> void:
	items.clear()
	for slot_id in data:
		var entry: Dictionary = data[slot_id]
		var item := _find_item_by_id(entry["item_id"])
		if item:
			items[slot_id] = {"data": item, "quantity": entry["quantity"]}

func _find_item_by_id(item_id: String) -> ItemData:
	var dir := DirAccess.open("res://data/")
	if not dir:
		return null
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load("res://data/" + file_name)
			if res is ItemData and res.id == item_id:
				return res
		file_name = dir.get_next()
	return null

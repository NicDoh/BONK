extends Node

var items: Dictionary = {}
var gear: Dictionary = {}

func _ready() -> void:
	_load_directory("res://data/items/", items)
	_load_directory("res://data/gear/", gear)

func _load_directory(path: String, registry: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if res is ItemData:
				registry[res.id] = res
		file_name = dir.get_next()

func find_item(item_id: String) -> ItemData:
	if items.has(item_id):
		return items[item_id]
	if gear.has(item_id):
		return gear[item_id]
	return null

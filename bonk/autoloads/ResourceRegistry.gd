extends Node

var items: Dictionary = {}
var gear: Dictionary = {}
var research: Dictionary = {}

func _ready() -> void:
	_load_directory("res://data/items/", items, ItemData)
	_load_directory("res://data/gear/", gear, ItemData)
	_load_directory("res://data/research/", research, ResearchData)

func _load_directory(path: String, registry: Dictionary, type) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if is_instance_of(res, type):
				registry[res.id] = res
		file_name = dir.get_next()

func find_item(item_id: String) -> ItemData:
	if items.has(item_id):
		return items[item_id]
	if gear.has(item_id):
		return gear[item_id]
	return null

func find_research(research_id: String) -> ResearchData:
	return research.get(research_id, null)

func get_all_research() -> Array:
	return research.values()

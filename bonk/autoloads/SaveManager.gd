extends Node

const SAVE_PATH := "user://save.json"

func save() -> void:
	var data := {
		"character": CharacterManager.serialize(),
		"inventory": InventoryManager.serialize(),
		"expedition": ExpeditionManager.serialize(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("SaveManager: failed to parse save file")
		return
	var data: Dictionary = json.get_data()
	if data.has("character"):
		CharacterManager.deserialize(data["character"])
	if data.has("inventory"):
		InventoryManager.deserialize(data["inventory"])

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

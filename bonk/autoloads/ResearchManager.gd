extends Node

var completed: Array[String] = []
var active_research_id: String = ""
var active_finish_time: float = 0.0

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if active_research_id == "":
		return
	if Time.get_unix_time_from_system() >= active_finish_time:
		_complete_active()

func start(data: ResearchData) -> bool:
	if active_research_id != "":
		return false
	if not GameManager.is_player_free():
		return false
	if is_completed(data.id):
		return false
	if not _prerequisites_met(data):
		return false
	for ingredient in data.cost_resources:
		if not InventoryManager.has_item(ingredient.item.id, ingredient.quantity):
			return false
	for ingredient in data.cost_resources:
		InventoryManager.remove_item(ingredient.item, ingredient.quantity)
	active_research_id = data.id
	active_finish_time = Time.get_unix_time_from_system() + data.duration_seconds
	EventBus.research_started.emit(data)
	return true

func _complete_active() -> void:
	var data := ResourceRegistry.find_research(active_research_id)
	active_research_id = ""
	active_finish_time = 0.0
	if not data:
		return
	completed.append(data.id)
	for unlock_id in data.unlocks:
		EventBus.content_unlocked.emit(unlock_id)
	EventBus.research_completed.emit(data)

func is_completed(research_id: String) -> bool:
	return completed.has(research_id)

func is_unlocked(unlock_id: String) -> bool:
	for res_id in completed:
		var data := ResourceRegistry.find_research(res_id)
		if data and data.unlocks.has(unlock_id):
			return true
	return false

func get_available(all_research: Array) -> Array:
	var available := []
	for data in all_research:
		if is_completed(data.id):
			continue
		if not _prerequisites_met(data):
			continue
		if not _visible(data):
			continue
		available.append(data)
	return available

func _prerequisites_met(data: ResearchData) -> bool:
	for prereq in data.prerequisites:
		if not is_completed(prereq):
			return false
	return true

func _visible(data: ResearchData) -> bool:
	if data.visible_conditions.is_empty():
		return true
	for condition in data.visible_conditions:
		if is_unlocked(condition) or is_completed(condition):
			return true
	return false

func time_remaining() -> float:
	if active_research_id == "":
		return 0.0
	return maxf(0.0, active_finish_time - Time.get_unix_time_from_system())

func serialize() -> Dictionary:
	return {
		"completed": completed.duplicate(),
		"active_research_id": active_research_id,
		"active_finish_time": active_finish_time,
	}

func deserialize(data: Dictionary) -> void:
	completed.clear()
	for item in data.get("completed", []):
		completed.append(str(item))
	active_research_id = data.get("active_research_id", "")
	active_finish_time = data.get("active_finish_time", 0.0)

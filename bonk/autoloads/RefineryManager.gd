extends Node

var _queue: Array = []  # Array of {recipe: RefinementRecipe, batches: int}
var _timer: float = 0.0

func _process(delta: float) -> void:
	if _queue.is_empty():
		return
	_timer += delta
	var entry: Dictionary = _queue[0]
	if _timer >= entry.recipe.duration:
		_timer -= entry.recipe.duration
		InventoryManager.add_item(entry.recipe.output_item, entry.recipe.output_quantity)
		EventBus.refinement_completed.emit(entry.recipe)
		entry.batches -= 1
		if entry.batches <= 0:
			_queue.pop_front()

func add_to_queue(recipe: RefinementRecipe, batches: int) -> void:
	var possible := max_batchable(recipe)
	var actual := mini(batches, possible)
	if actual <= 0:
		return
	for ing in recipe.inputs:
		InventoryManager.remove_item(ing.item, ing.quantity * actual)
	_queue.append({"recipe": recipe, "batches": actual})
	EventBus.refinement_queued.emit(recipe, actual)

func max_batchable(recipe: RefinementRecipe) -> int:
	if recipe.tool_item and InventoryManager.get_quantity(recipe.tool_item.id) <= 0:
		return 0
	var min_batches := 9999999
	for ing in recipe.inputs:
		var possible := InventoryManager.get_quantity(ing.item.id) / ing.quantity
		min_batches = mini(min_batches, possible)
	return min_batches if not recipe.inputs.is_empty() else 0

func is_available(recipe: RefinementRecipe) -> bool:
	if recipe.required_unlock != "":
		return ResearchManager.is_unlocked(recipe.required_unlock)
	return true

func get_active_recipe() -> RefinementRecipe:
	return _queue[0].recipe if not _queue.is_empty() else null

func get_active_batches_remaining() -> int:
	return _queue[0].batches if not _queue.is_empty() else 0

func time_remaining() -> float:
	if _queue.is_empty():
		return 0.0
	return _queue[0].recipe.duration - _timer

func serialize() -> Dictionary:
	var q := []
	for entry in _queue:
		q.append({"recipe_path": entry.recipe.resource_path, "batches": entry.batches})
	return {"queue": q, "timer": _timer}

func deserialize(data: Dictionary) -> void:
	_timer = data.get("timer", 0.0)
	_queue = []
	for entry in data.get("queue", []):
		var recipe := load(entry.recipe_path) as RefinementRecipe
		if recipe:
			_queue.append({"recipe": recipe, "batches": entry.batches})

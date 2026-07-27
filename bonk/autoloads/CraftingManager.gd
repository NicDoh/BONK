extends Node

func can_craft(recipe: CraftingRecipe) -> bool:
	for ingredient in recipe.ingredients:
		if not InventoryManager.has_item(ingredient.item.id, ingredient.quantity):
			return false
	var building_level := CityManager.get_level("bonkery")
	return building_level >= recipe.required_building_level

func craft(recipe: CraftingRecipe) -> bool:
	if not can_craft(recipe):
		return false
	for ingredient in recipe.ingredients:
		InventoryManager.remove_item(ingredient.item, ingredient.quantity)
	InventoryManager.add_item(recipe.result_item, recipe.result_quantity)
	EventBus.item_crafted.emit(recipe.id, recipe.result_item)
	return true

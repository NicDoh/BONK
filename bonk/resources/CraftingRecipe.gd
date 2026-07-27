class_name CraftingRecipe
extends Resource

@export var id: String = ""
@export var result_item: ItemData
@export var result_quantity: int = 1
@export var ingredients: Array[CraftingIngredient] = []
@export var required_building_level: int = 1

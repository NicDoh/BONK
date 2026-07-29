class_name RefinementRecipe
extends Resource

@export var id: String = ""
@export var inputs: Array[CraftingIngredient] = []
@export var tool_item: ItemData = null  # reusable, not consumed
@export var output_item: ItemData = null
@export var output_quantity: int = 1
@export var duration: float = 5.0
@export var required_unlock: String = ""

class_name ResearchData
extends Resource

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var category: String = ""

@export var cost_resources: Array[CraftingIngredient] = []
@export var duration_seconds: float = 60.0

@export var prerequisites: Array[String] = []
@export var visible_conditions: Array[String] = []
@export var unlocks: Array[String] = []

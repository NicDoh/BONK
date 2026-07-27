class_name BuildingData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var max_level: int = 5

@export var upgrade_costs: Array[Array] = []
@export var upgrade_durations: Array[float] = []

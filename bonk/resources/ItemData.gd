class_name ItemData
extends Resource

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var stackable: bool = true
@export var max_stack: int = 9999

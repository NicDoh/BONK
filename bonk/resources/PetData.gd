class_name PetData
extends Resource

enum DamageType { BLUNT, SLASH, PIERCE, FIRE, POISON, SPIRIT }
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: String = ""
@export var name: String = ""
@export var portrait: Texture2D
@export var rarity: Rarity = Rarity.RARE

@export var base_strength: int = 1
@export var base_speed: int = 1
@export var damage_type: DamageType = DamageType.BLUNT

@export var passive_bonus_type: String = ""
@export var passive_bonus_value: float = 0.0

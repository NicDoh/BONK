class_name GearData
extends ItemData

enum Slot { MAIN_HAND, OFF_HAND, HEAD, BODY, LEGS, FEET, AMULET, RING }
enum DamageType { BLUNT, SLASH, PIERCE, FIRE, POISON, SPIRIT }

@export var tier: int = 0
@export var slot: Slot = Slot.MAIN_HAND
@export var two_handed: bool = false
@export var damage_type: DamageType = DamageType.BLUNT

@export var bonus_hp: int = 0
@export var bonus_strength: int = 0
@export var bonus_defense: int = 0
@export var bonus_speed: int = 0
@export var bonus_accuracy: int = 0
@export var bonus_drop_chance: float = 0.0

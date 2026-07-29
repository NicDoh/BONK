class_name GearData
extends ItemData

enum Slot { WEAPON, SHIELD, HEAD, BODY, LEGS, BOOTS, GLOVES, AMULET, CHARM, CAPE, QUIVER }
enum DamageType { BLUNT, SLASH, PIERCE, FIRE, POISON, SPIRIT }

@export var tier: int = 0
@export var slot: Slot = Slot.WEAPON
@export var two_handed: bool = false
@export var damage_type: DamageType = DamageType.BLUNT

@export var bonus_hp: int = 0
@export var bonus_strength: int = 0
@export var bonus_defense: int = 0
@export var bonus_speed: int = 0
@export var bonus_accuracy: int = 0
@export var bonus_drop_chance: float = 0.0

# Damage type resistances: 0.0 = neutral, 0.5 = half damage, -0.5 = vulnerable
@export var resistance_blunt: float = 0.0
@export var resistance_slash: float = 0.0
@export var resistance_pierce: float = 0.0
@export var resistance_fire: float = 0.0
@export var resistance_poison: float = 0.0
@export var resistance_spirit: float = 0.0

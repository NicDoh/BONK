class_name GearData
extends ItemData

enum Slot { WEAPON, SHIELD, HEAD, BODY, LEGS, BOOTS, GLOVES, AMULET, CHARM, CAPE, QUIVER }
enum DamageType { BLUNT, SLASH, PIERCE, FIRE, POISON, SPIRIT }

@export var tier: int = 0
@export var slot: Slot = Slot.WEAPON
@export var two_handed: bool = false
@export var damage_type: DamageType = DamageType.BLUNT

# Weapon stats
@export var damage: int = 0
@export var attack_interval: float = 2.0

# All gear
@export var defense: int = 0
@export var bonus_hp: int = 0
@export var speed_modifier: float = 0.0
@export var accuracy_bonus: int = 0
@export var bonus_drop_chance: float = 0.0

# Resistances: keys are lowercase damage type names ("blunt", "slash", etc.)
# Positive = damage reduction, negative = vulnerability. Range: -1.0 to 0.9
@export var resistances: Dictionary = {}

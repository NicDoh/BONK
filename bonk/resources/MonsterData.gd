class_name MonsterData
extends Resource

enum DamageType { BLUNT, SLASH, PIERCE, FIRE, POISON, SPIRIT }

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var portrait: Texture2D
@export var is_boss: bool = false

@export var hp: int = 10
@export var strength: int = 1
@export var defense: int = 0
@export var speed: int = 1
@export var accuracy: int = 10

@export var attack_damage_type: DamageType = DamageType.BLUNT

# Damage multipliers: 0.0 = immune, 0.5 = resistant, 1.0 = neutral, 1.5 = weak
@export var multiplier_blunt: float = 1.0
@export var multiplier_slash: float = 1.0
@export var multiplier_pierce: float = 1.0
@export var multiplier_fire: float = 1.0
@export var multiplier_poison: float = 1.0
@export var multiplier_spirit: float = 1.0

@export var drops_guaranteed: Array[DropEntry] = []
@export var drops_common: Array[DropEntry] = []
@export var rare_table_chance: float = 0.0
@export var drops_rare: Array[DropEntry] = []
@export var ultra_rare_table_chance: float = 0.0
@export var drops_ultra_rare: Array[DropEntry] = []

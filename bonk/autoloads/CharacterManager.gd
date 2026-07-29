extends Node

const XP_PER_LEVEL_BASE: float = 100.0
const XP_SCALING: float = 1.15

var stats: Dictionary = {
	"hp":       {"level": 1, "xp": 0.0},
	"strength": {"level": 1, "xp": 0.0},
	"defense":  {"level": 1, "xp": 0.0},
	"speed":    {"level": 1, "xp": 0.0},
	"accuracy": {"level": 1, "xp": 0.0},
}

var current_hp: int = 0
var max_hp: int = 0

var equipped: Dictionary = {}  # GearData.Slot (int) → GearData

func _ready() -> void:
	recalculate_max_hp()
	current_hp = max_hp

func gain_xp(stat_name: String, amount: float) -> void:
	if not stats.has(stat_name):
		return
	stats[stat_name]["xp"] += amount
	EventBus.stat_xp_gained.emit(stat_name, amount)
	_check_level_up(stat_name)

func _check_level_up(stat_name: String) -> void:
	var stat: Dictionary = stats[stat_name]
	var needed := xp_for_level(stat["level"] + 1)
	while stat["xp"] >= needed:
		stat["xp"] -= needed
		stat["level"] += 1
		EventBus.stat_leveled_up.emit(stat_name, stat["level"])
		recalculate_max_hp()
		needed = xp_for_level(stat["level"] + 1)

func xp_for_level(level: int) -> float:
	return XP_PER_LEVEL_BASE * pow(XP_SCALING, level - 1)

func get_level(stat_name: String) -> int:
	return stats[stat_name]["level"]

func get_equipped(slot: GearData.Slot) -> GearData:
	return equipped.get(slot, null)

func get_effective_stat(stat_name: String) -> int:
	var base := get_level(stat_name)
	var bonus := 0
	for gear in equipped.values():
		match stat_name:
			"strength": bonus += gear.bonus_strength
			"speed":    bonus += gear.bonus_speed
			"accuracy": bonus += gear.bonus_accuracy
			"hp":       bonus += gear.bonus_hp
			"defense":  bonus += gear.bonus_defense
	return base + bonus

func recalculate_max_hp() -> void:
	max_hp = get_effective_stat("hp") * 10
	current_hp = mini(current_hp, max_hp)

func take_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)

func heal_to_full() -> void:
	current_hp = max_hp

func is_alive() -> bool:
	return current_hp > 0

func equip(gear: GearData) -> void:
	equipped[gear.slot] = gear
	recalculate_max_hp()

func unequip(slot: GearData.Slot) -> void:
	equipped.erase(slot)
	recalculate_max_hp()

func get_resistance(damage_type: GearData.DamageType) -> float:
	var total := 0.0
	for gear in equipped.values():
		match damage_type:
			GearData.DamageType.BLUNT:   total += gear.resistance_blunt
			GearData.DamageType.SLASH:   total += gear.resistance_slash
			GearData.DamageType.PIERCE:  total += gear.resistance_pierce
			GearData.DamageType.FIRE:    total += gear.resistance_fire
			GearData.DamageType.POISON:  total += gear.resistance_poison
			GearData.DamageType.SPIRIT:  total += gear.resistance_spirit
	return clampf(total, -1.0, 0.9)

func get_total_drop_bonus() -> float:
	var bonus := 0.0
	for gear in equipped.values():
		bonus += gear.bonus_drop_chance
	return bonus

func serialize() -> Dictionary:
	var equipped_data := {}
	for slot in equipped:
		equipped_data[str(slot)] = equipped[slot].id
	return {
		"stats": stats.duplicate(true),
		"current_hp": current_hp,
		"equipped": equipped_data,
	}

func deserialize(data: Dictionary) -> void:
	stats = data["stats"]
	current_hp = data["current_hp"]
	equipped = {}
	for slot_str in data.get("equipped", {}):
		var item_id: String = data["equipped"][slot_str]
		var gear := ResourceRegistry.find_item(item_id) as GearData
		if gear:
			equipped[int(slot_str)] = gear
	recalculate_max_hp()

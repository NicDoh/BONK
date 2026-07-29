extends Node

const XP_PER_LEVEL_BASE: float = 100.0
const XP_SCALING: float = 1.15
const BARE_HANDS_DAMAGE: int = 2
const BARE_HANDS_INTERVAL: float = 2.0

var stats: Dictionary = {
	"strength":    {"level": 0, "xp": 0.0},
	"defense":     {"level": 0, "xp": 0.0},
	"constitution":{"level": 0, "xp": 0.0},
	"accuracy":    {"level": 0, "xp": 0.0},
}

var current_hp: int = 0
var max_hp: int = 0

var equipped: Dictionary = {}  # GearData.Slot (int) → GearData
var active_training: String = "strength"

func _ready() -> void:
	recalculate_max_hp()
	current_hp = max_hp

func set_training(stat_name: String) -> void:
	if not stats.has(stat_name):
		return
	active_training = stat_name
	EventBus.training_focus_changed.emit(stat_name)

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

func get_total_strength() -> int:
	var total := get_level("strength")
	for gear in equipped.values():
		total += gear.strength_bonus
	return maxi(0, total)

func get_weapon_damage() -> int:
	var weapon := get_equipped(GearData.Slot.WEAPON)
	var base := weapon.damage if weapon else BARE_HANDS_DAMAGE
	return roundi(float(base) * (1.0 + float(get_total_strength()) / 100.0))

func get_total_defense() -> int:
	var total := get_level("defense")
	for gear in equipped.values():
		total += gear.defense
	return maxi(0, total)

func get_attack_interval() -> float:
	var weapon := get_equipped(GearData.Slot.WEAPON)
	var base := weapon.attack_interval if weapon else BARE_HANDS_INTERVAL
	var modifier := 0.0
	for gear in equipped.values():
		modifier += gear.speed_modifier
	return maxf(0.3, base + modifier)

func get_total_accuracy() -> int:
	var base := get_level("accuracy")
	for gear in equipped.values():
		base += gear.accuracy_bonus
	return maxi(0, base)

func get_resistance(damage_type: GearData.DamageType) -> float:
	var key := (GearData.DamageType.keys()[damage_type] as String).to_lower()
	var total := 0.0
	for gear in equipped.values():
		total += gear.resistances.get(key, 0.0)
	return clampf(total, -1.0, 0.9)

func get_total_drop_bonus() -> float:
	var bonus := 0.0
	for gear in equipped.values():
		bonus += gear.bonus_drop_chance
	return bonus

func recalculate_max_hp() -> void:
	var bonus_hp := 0
	for gear in equipped.values():
		bonus_hp += gear.bonus_hp
	max_hp = 100 + get_level("constitution") * 10 + bonus_hp
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

func serialize() -> Dictionary:
	var equipped_data := {}
	for slot in equipped:
		equipped_data[str(slot)] = equipped[slot].id
	return {
		"stats": stats.duplicate(true),
		"current_hp": current_hp,
		"equipped": equipped_data,
		"active_training": active_training,
	}

func deserialize(data: Dictionary) -> void:
	var loaded: Dictionary = data.get("stats", {})
	# Migrate old stat keys from before the constitution/speed rename
	if loaded.has("hp") and not loaded.has("constitution"):
		loaded["constitution"] = loaded["hp"]
	loaded.erase("hp")
	loaded.erase("speed")
	for key in stats:
		if loaded.has(key):
			stats[key] = loaded[key]
	current_hp = data.get("current_hp", max_hp)
	active_training = data.get("active_training", "strength")
	equipped = {}
	for slot_str in data.get("equipped", {}):
		var item_id: String = data["equipped"][slot_str]
		var gear := ResourceRegistry.find_item(item_id) as GearData
		if gear:
			equipped[int(slot_str)] = gear
	recalculate_max_hp()

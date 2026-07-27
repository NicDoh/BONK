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

var equipped_main_hand: GearData = null
var equipped_off_hand: GearData = null

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

func get_effective_stat(stat_name: String) -> int:
	var base := get_level(stat_name)
	var bonus := 0
	if equipped_main_hand:
		match stat_name:
			"strength": bonus += equipped_main_hand.bonus_strength
			"speed":    bonus += equipped_main_hand.bonus_speed
			"accuracy": bonus += equipped_main_hand.bonus_accuracy
			"hp":       bonus += equipped_main_hand.bonus_hp
			"defense":  bonus += equipped_main_hand.bonus_defense
	if equipped_off_hand:
		match stat_name:
			"defense":  bonus += equipped_off_hand.bonus_defense
			"hp":       bonus += equipped_off_hand.bonus_hp
			"strength": bonus += equipped_off_hand.bonus_strength
			"speed":    bonus += equipped_off_hand.bonus_speed
			"accuracy": bonus += equipped_off_hand.bonus_accuracy
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
	match gear.slot:
		GearData.Slot.MAIN_HAND: equipped_main_hand = gear
		GearData.Slot.OFF_HAND:  equipped_off_hand = gear
	recalculate_max_hp()

func serialize() -> Dictionary:
	return {
		"stats": stats.duplicate(true),
		"current_hp": current_hp,
		"equipped_main_hand": equipped_main_hand.id if equipped_main_hand else "",
		"equipped_off_hand": equipped_off_hand.id if equipped_off_hand else "",
	}

func deserialize(data: Dictionary) -> void:
	stats = data["stats"]
	current_hp = data["current_hp"]
	recalculate_max_hp()

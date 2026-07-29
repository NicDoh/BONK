extends Node

enum Mode { ROAM }

var active: bool = false
var current_zone: ZoneData = null
var current_zone_id: String = ""
var current_mode: Mode = Mode.ROAM
var current_monster: MonsterData = null

var _player_tick_timer: float = 0.0
var _monster_tick_timer: float = 0.0
var _monster_hp: int = 0

func _process(delta: float) -> void:
	if not active:
		return

	_player_tick_timer += delta
	if _player_tick_timer >= _get_player_tick_interval():
		_player_tick_timer = 0.0
		_player_attack()
		if _monster_hp <= 0:
			_on_monster_died()
			return

	_monster_tick_timer += delta
	if _monster_tick_timer >= _get_monster_tick_interval():
		_monster_tick_timer = 0.0
		_monster_attack()
		if not CharacterManager.is_alive():
			_on_player_died()

func start(zone: ZoneData, mode: Mode = Mode.ROAM) -> void:
	if active:
		return
	if not GameManager.is_player_free():
		return
	current_zone = zone
	current_zone_id = zone.id
	current_mode = mode
	_pick_next_monster()
	active = true
	CharacterManager.heal_to_full()
	EventBus.expedition_started.emit(zone.id, Mode.keys()[mode])

func recall() -> void:
	if not active:
		return
	active = false
	current_monster = null
	current_zone = null
	EventBus.expedition_ended.emit({"reason": "recalled"})

func _pick_next_monster() -> void:
	match current_mode:
		Mode.ROAM:
			current_monster = _weighted_random(current_zone.roam_monsters)
	_monster_hp = current_monster.hp
	_player_tick_timer = 0.0
	_monster_tick_timer = 0.0
	EventBus.monster_spawned.emit(current_monster)

func _weighted_random(entries: Array[ZoneMonsterEntry]) -> MonsterData:
	var total := 0.0
	for e in entries:
		total += e.weight
	var roll := randf() * total
	var cumulative := 0.0
	for e in entries:
		cumulative += e.weight
		if roll <= cumulative:
			return e.monster
	return entries[-1].monster

# --- Combat formula constants ---
const MISS_MAX    := 0.20
const MISS_K      := 1.0
const MISS_P      := 1.3
const CRIT_BASE   := 0.02
const CRIT_BONUS  := 0.21
const CRIT_K      := 3.0
const CRIT_P      := 1.5
const CRIT_MULT   := 1.2
const RED_MAX     := 0.90
const RED_K       := 3.5
const RED_P       := 1.5
func _hit_chance(attacker_acc: float, defender_def: float) -> float:
	if defender_def <= 0.0:
		return 1.0
	var r := attacker_acc / defender_def
	return 1.0 - MISS_MAX * (MISS_K / (MISS_K + pow(r, MISS_P)))

func _crit_chance(accuracy: float, defense: float) -> float:
	if defense <= 0.0:
		return CRIT_BASE + CRIT_BONUS
	var r := accuracy / defense
	var rp := pow(r, CRIT_P)
	return CRIT_BASE + CRIT_BONUS * (rp / (CRIT_K + rp))

func _damage_reduction(defender_def: float, attacker_acc: float) -> float:
	if attacker_acc <= 0.0:
		return RED_MAX
	var r := defender_def / attacker_acc
	var rp := pow(r, RED_P)
	return RED_MAX * (rp / (RED_K + rp))

const ROLL_BASE := 0.85
const ROLL_K    := 25.0

func _damage_roll(base: float, accuracy: float) -> int:
	var exponent := ROLL_BASE / (1.0 + accuracy / ROLL_K)
	return maxi(1, ceili(base * pow(randf(), exponent)))

func _player_attack() -> void:
	var accuracy := float(CharacterManager.get_total_accuracy())
	var defense  := float(current_monster.defense)

	if randf() > _hit_chance(accuracy, defense):
		EventBus.player_missed.emit()
		return

	var base_damage := float(CharacterManager.get_attack_damage())
	var weapon := CharacterManager.get_equipped(GearData.Slot.WEAPON)
	var damage_type := weapon.damage_type if weapon else GearData.DamageType.BLUNT

	var rolled: int
	var crit_mult: float
	if randf() < _crit_chance(accuracy, defense):
		rolled = maxi(1, ceili(base_damage * CRIT_MULT))
		crit_mult = CRIT_MULT
	else:
		rolled = _damage_roll(base_damage, accuracy)
		crit_mult = 1.0

	var reduction  := _damage_reduction(defense, accuracy)
	var type_mult  := _get_damage_multiplier()
	var final_damage := maxi(1, ceili(float(rolled) * (1.0 - reduction) * type_mult))

	EventBus.player_hit_monster.emit(final_damage, damage_type, crit_mult)
	_monster_hp -= final_damage

func _monster_attack() -> void:
	var mon_acc    := float(current_monster.accuracy)
	var player_def := float(CharacterManager.get_total_defense())

	if randf() > _hit_chance(mon_acc, player_def):
		EventBus.monster_missed.emit()
		return

	var base := float(current_monster.strength)
	var rolled: int
	if randf() < _crit_chance(mon_acc, player_def):
		rolled = maxi(1, ceili(base * CRIT_MULT))
	else:
		rolled = _damage_roll(base, mon_acc)

	var reduction  := _damage_reduction(player_def, mon_acc)
	var resistance := CharacterManager.get_resistance(current_monster.attack_damage_type)
	var final_damage := maxi(1, int(float(rolled) * (1.0 - reduction) * (1.0 - resistance)))

	CharacterManager.take_damage(final_damage)
	EventBus.monster_hit_player.emit(final_damage)

func _on_monster_died() -> void:
	EventBus.monster_died.emit(current_monster)
	CharacterManager.gain_xp(CharacterManager.active_training, float(current_monster.xp_reward))
	_roll_drops()
	_pick_next_monster()

func _on_player_died() -> void:
	active = false
	current_zone = null
	EventBus.player_died.emit()
	EventBus.expedition_ended.emit({"reason": "died"})

func _roll_drops() -> void:
	var drop_bonus := CharacterManager.get_total_drop_bonus()

	for e in current_monster.drops_guaranteed:
		var qty := randi_range(e.quantity_min, e.quantity_max)
		InventoryManager.add_item(e.item, qty)

	_roll_common_table(current_monster.drops_common, drop_bonus)

	if current_monster.rare_table_chance > 0.0:
		_roll_single_table(current_monster.drops_rare, current_monster.rare_table_chance, drop_bonus)

	if current_monster.ultra_rare_table_chance > 0.0:
		_roll_single_table(current_monster.drops_ultra_rare, current_monster.ultra_rare_table_chance, 0.0)

func _roll_common_table(entries: Array[DropEntry], drop_bonus: float) -> void:
	if entries.is_empty():
		return
	var total := 0.0
	for e in entries:
		total += e.weight * (1.0 + drop_bonus)
	var roll := randf() * total
	var cumulative := 0.0
	for e in entries:
		cumulative += e.weight * (1.0 + drop_bonus)
		if roll <= cumulative:
			var qty := randi_range(e.quantity_min, e.quantity_max)
			InventoryManager.add_item(e.item, qty)
			return

func _roll_single_table(entries: Array[DropEntry], table_chance: float, drop_bonus: float) -> void:
	if entries.is_empty():
		return
	if randf() > table_chance * (1.0 + drop_bonus):
		return
	for e in entries:
		if randf() < e.weight:
			var qty := randi_range(e.quantity_min, e.quantity_max)
			InventoryManager.add_item(e.item, qty)


func _get_damage_multiplier() -> float:
	var weapon := CharacterManager.get_equipped(GearData.Slot.WEAPON)
	if not weapon:
		return 1.0
	var type_name := (GearData.DamageType.keys()[weapon.damage_type] as String).to_lower()
	var result = current_monster.get("multiplier_" + type_name)
	return result if result != null else 1.0

func _get_player_tick_interval() -> float:
	return CharacterManager.get_attack_interval()

func _get_monster_tick_interval() -> float:
	if not current_monster:
		return 3.0
	return clampf(3.0 - (current_monster.speed * 0.05), 0.5, 3.0)

func apply_offline_progress(elapsed: float) -> Dictionary:
	if not current_monster:
		return {}

	var accuracy    := float(CharacterManager.get_total_accuracy())
	var defense     := float(current_monster.defense)
	var base_damage := float(CharacterManager.get_attack_damage()) * _get_damage_multiplier()
	var hit_ch      := _hit_chance(accuracy, defense)
	var roll_exp    := ROLL_BASE / (1.0 + accuracy / ROLL_K)
	var avg_roll    := 1.0 / (1.0 + roll_exp)
	var avg_damage  := maxi(1, int(base_damage * hit_ch * avg_roll))
	var ticks_per_kill := ceili(float(current_monster.hp) / float(avg_damage))
	var time_per_kill := ticks_per_kill * _get_player_tick_interval()
	var kills := int(elapsed / time_per_kill)
	if kills <= 0:
		return {}

	var drop_bonus := CharacterManager.get_total_drop_bonus()

	var drops_summary: Dictionary = {}
	for i in kills:
		var results := _simulate_kill_drops(drop_bonus)
		for item_name in results:
			drops_summary[item_name] = drops_summary.get(item_name, 0) + results[item_name]

	CharacterManager.gain_xp(CharacterManager.active_training, float(current_monster.xp_reward * kills))

	return {"kills": kills, "elapsed": elapsed, "drops": drops_summary}

func _simulate_kill_drops(drop_bonus: float) -> Dictionary:
	var summary: Dictionary = {}
	for e in current_monster.drops_guaranteed:
		var qty := randi_range(e.quantity_min, e.quantity_max)
		InventoryManager.add_item(e.item, qty)
		summary[e.item.name] = summary.get(e.item.name, 0) + qty
	if not current_monster.drops_common.is_empty():
		var entry := _weighted_pick_drop(current_monster.drops_common, drop_bonus)
		var qty := randi_range(entry.quantity_min, entry.quantity_max)
		InventoryManager.add_item(entry.item, qty)
		summary[entry.item.name] = summary.get(entry.item.name, 0) + qty
	if current_monster.rare_table_chance > 0.0 and not current_monster.drops_rare.is_empty():
		if randf() < current_monster.rare_table_chance * (1.0 + drop_bonus):
			for e in current_monster.drops_rare:
				if randf() < e.weight:
					var qty := randi_range(e.quantity_min, e.quantity_max)
					InventoryManager.add_item(e.item, qty)
					summary[e.item.name] = summary.get(e.item.name, 0) + qty
	if current_monster.ultra_rare_table_chance > 0.0 and not current_monster.drops_ultra_rare.is_empty():
		if randf() < current_monster.ultra_rare_table_chance:
			for e in current_monster.drops_ultra_rare:
				if randf() < e.weight:
					var qty := randi_range(e.quantity_min, e.quantity_max)
					InventoryManager.add_item(e.item, qty)
					summary[e.item.name] = summary.get(e.item.name, 0) + qty
	return summary

func _weighted_pick_drop(entries: Array[DropEntry], drop_bonus: float) -> DropEntry:
	var total := 0.0
	for e in entries:
		total += e.weight * (1.0 + drop_bonus)
	var roll := randf() * total
	var cumulative := 0.0
	for e in entries:
		cumulative += e.weight * (1.0 + drop_bonus)
		if roll <= cumulative:
			return e
	return entries[-1]

func serialize() -> Dictionary:
	return {
		"active": active,
		"zone_id": current_zone_id,
		"zone_path": current_zone.resource_path if current_zone else "",
		"monster_path": current_monster.resource_path if current_monster else "",
	}

func deserialize(data: Dictionary) -> void:
	current_zone_id = data.get("zone_id", "")
	var zone_path: String = data.get("zone_path", "")
	if zone_path != "":
		current_zone = load(zone_path) as ZoneData
	var monster_path: String = data.get("monster_path", "")
	if monster_path != "":
		current_monster = load(monster_path) as MonsterData
		_monster_hp = current_monster.hp
	active = data.get("active", false) and current_zone != null and current_monster != null

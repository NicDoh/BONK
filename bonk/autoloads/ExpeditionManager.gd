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

func _player_attack() -> void:
	var accuracy := CharacterManager.get_total_accuracy()
	var hit_chance := clampf(accuracy / float(accuracy + current_monster.defense), 0.05, 0.95)

	if randf() > hit_chance:
		EventBus.player_missed.emit()
		return

	var damage := maxi(1, CharacterManager.get_weapon_damage() - current_monster.defense / 2)
	var multiplier := _get_damage_multiplier()
	var final_damage := int(damage * multiplier)

	var weapon := CharacterManager.get_equipped(GearData.Slot.WEAPON)
	var damage_type := weapon.damage_type if weapon else GearData.DamageType.BLUNT

	_monster_hp -= final_damage
	EventBus.player_hit_monster.emit(final_damage, damage_type, multiplier)
	_grant_weapon_xp(final_damage)

func _monster_attack() -> void:
	var monster_acc := current_monster.accuracy
	var player_def := CharacterManager.get_total_defense()
	var hit_chance := clampf(monster_acc / float(monster_acc + player_def), 0.05, 0.95)

	if randf() > hit_chance:
		EventBus.monster_missed.emit()
		CharacterManager.gain_xp("defense", 1.0)
		return

	var damage := maxi(1, current_monster.strength - player_def / 2)

	var shield := CharacterManager.get_equipped(GearData.Slot.SHIELD)
	if shield:
		var block_chance := clampf(player_def / float(player_def + current_monster.strength), 0.0, 0.6)
		if randf() < block_chance:
			EventBus.player_blocked.emit(damage)
			CharacterManager.gain_xp("defense", 2.0)
			return

	var resistance := CharacterManager.get_resistance(current_monster.attack_damage_type)
	var final_damage := maxi(1, int(damage * (1.0 - resistance)))
	CharacterManager.take_damage(final_damage)
	EventBus.monster_hit_player.emit(final_damage)
	CharacterManager.gain_xp("constitution", float(final_damage) * 0.5)

func _on_monster_died() -> void:
	EventBus.monster_died.emit(current_monster)
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

func _grant_weapon_xp(damage: int) -> void:
	var xp := float(damage) * 10.0
	CharacterManager.gain_xp("strength", xp * 0.6)
	CharacterManager.gain_xp("accuracy", xp * 0.4)

func _get_damage_multiplier() -> float:
	var weapon := CharacterManager.get_equipped(GearData.Slot.WEAPON)
	if not weapon:
		return 1.0
	match weapon.damage_type:
		GearData.DamageType.BLUNT:   return current_monster.multiplier_blunt
		GearData.DamageType.SLASH:   return current_monster.multiplier_slash
		GearData.DamageType.PIERCE:  return current_monster.multiplier_pierce
		GearData.DamageType.FIRE:    return current_monster.multiplier_fire
		GearData.DamageType.POISON:  return current_monster.multiplier_poison
		GearData.DamageType.SPIRIT:  return current_monster.multiplier_spirit
	return 1.0

func _get_player_tick_interval() -> float:
	return CharacterManager.get_attack_interval()

func _get_monster_tick_interval() -> float:
	if not current_monster:
		return 3.0
	return clampf(3.0 - (current_monster.speed * 0.05), 0.5, 3.0)

func apply_offline_progress(elapsed: float) -> Dictionary:
	if not current_monster:
		return {}

	var avg_damage := maxi(1, CharacterManager.get_weapon_damage() - current_monster.defense / 2)
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

	var xp_per_kill := float(avg_damage * ticks_per_kill)
	CharacterManager.gain_xp("strength", xp_per_kill * kills * 0.6)
	CharacterManager.gain_xp("accuracy", xp_per_kill * kills * 0.4)

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
